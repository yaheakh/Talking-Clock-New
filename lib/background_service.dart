import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'local_voice.dart';

// MUST match AppState._prefsKey exactly — this is how the background
// isolate reads the same settings the foreground app just saved.
const _prefsKey = 'talking_clock_settings_v1';
const _channelId = 'talking_clock_background';

/// Configures (and, the first time, starts) the persistent Android
/// foreground service that keeps the clock speaking — periodic time
/// announcements and reminders — even while the app itself isn't the
/// visible/foreground screen. Safe to call on every app launch:
/// configure() + autoStart just make sure the service exists and is
/// running, they don't create duplicates.
///
/// Known limits, stated plainly: this relies on Android's foreground
/// service mechanism, which is the standard, correct way to do this —
/// but some OEM Android TV boxes ship aggressive custom battery/task
/// managers that kill background services regardless of best practice.
/// If that happens on a given device, there's no code-level fix; the
/// device's battery-optimization / "auto-start" manager settings need to
/// allow this app to run in the background.
Future<void> setupBackgroundService() async {
  final service = FlutterBackgroundService();

  const channel = AndroidNotificationChannel(
    _channelId,
    'الساعة الناطقة (تعمل في الخلفية)',
    description: 'يبقي هذا الإشعار الساعة تنطق بالوقت والتذكيرات حتى وأنت خارج التطبيق',
    importance: Importance.low,
  );
  final notifications = FlutterLocalNotificationsPlugin();
  await notifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: _onServiceStart,
      autoStart: true,
      isForegroundMode: true,
      autoStartOnBoot: false,
      notificationChannelId: _channelId,
      initialNotificationTitle: 'الساعة الناطقة',
      initialNotificationContent: 'تعمل في الخلفية',
      foregroundServiceNotificationId: 9990,
      // MUST match the android:foregroundServiceType on the <service> tag
      // in AndroidManifest.xml exactly — a mismatch (or omission on
      // either side) is what crashes the app on Android 14+ the instant
      // the service tries to start.
      foregroundServiceTypes: [AndroidForegroundType.mediaPlayback],
    ),
    iosConfiguration: IosConfiguration(),
  );
}

/// Runs in its own background isolate, completely independent of the
/// app's UI. This is now the ONLY place that fires voice announcements —
/// the foreground AppState no longer does, to avoid the clock speaking
/// twice (once from each isolate) whenever the app happens to be open at
/// the moment a reminder fires. It notifies the UI isolate (if attached)
/// via service.invoke('fired', ...) purely so the on-screen banner/pulse
/// can still show when the app is visible.
@pragma('vm:entry-point')
void _onServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  final tts = FlutterTts();
  final localVoice = LocalVoice();

  // Cleared whenever the wall-clock minute changes, exactly like the
  // foreground clock used to do — prevents firing the same reminder or
  // periodic announcement more than once inside the same minute.
  String lastMinuteMark = '';
  final firedThisMinute = <String>{};

  Future<void> speakFallback(String text, String language) async {
    try {
      await tts.setLanguage(language == 'ar' ? 'ar-SA' : 'en-US');
      await tts.stop();
      await tts.speak(text);
    } catch (_) {
      // No system TTS engine either — nothing more we can do for this
      // one announcement, but the loop itself must keep running.
    }
  }

  Timer.periodic(const Duration(seconds: 1), (timer) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Cross-isolate: the UI isolate may have just saved new settings,
      // so force a fresh read from disk instead of trusting this
      // isolate's cached copy.
      await prefs.reload();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;

      AppSettings settings;
      try {
        settings = AppSettings.fromJson(jsonDecode(raw));
      } catch (_) {
        return; // Malformed settings — just skip this tick, try again next second.
      }
      if (settings.others.mute) return;

      final now = DateTime.now();
      final minuteKey = '${now.year}-${now.month}-${now.day} ${now.hour}:${now.minute}';
      if (minuteKey != lastMinuteMark) {
        lastMinuteMark = minuteKey;
        firedThisMinute.clear();
      }

      final hhmm = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final dow = now.weekday % 7; // Dart: Mon=1..Sun=7 -> Sun=0..Sat=6

      // --- scheduled reminders (exact time) ---
      for (final r in settings.reminders) {
        if (!r.enabled) continue;
        final daysMatch = r.days.isEmpty || r.days.length == 7 || r.days.contains(dow);
        if (r.time != hhmm || !daysMatch) continue;
        final key = 'custom:${r.id}';
        if (firedThisMinute.contains(key)) continue;
        firedThisMinute.add(key);

        if (r.presetId != null) {
          final ok = await localVoice.speakPreset(r.presetId!, settings.language);
          if (!ok) await speakFallback(r.title, settings.language);
        } else {
          await speakFallback(r.title, settings.language);
        }
        service.invoke('fired', {'id': r.id, 'title': r.title, 'isAdvanceNotice': false});
      }

      // --- advance notices ("in N minutes") ---
      for (final r in settings.reminders) {
        if (!r.enabled) continue;
        if (!_isAdvanceNoticeDue(r, now)) continue;
        final key = 'advance:${r.id}';
        if (firedThisMinute.contains(key)) continue;
        firedThisMinute.add(key);

        final minutes = r.advanceNotice.minutesBefore;
        final text = '${r.title} in $minutes minute${minutes == 1 ? '' : 's'}';
        if (r.presetId != null) {
          final ok = await localVoice.speakPresetAdvanceNotice(r.presetId!, minutes, settings.language);
          if (!ok) await speakFallback(text, settings.language);
        } else {
          await speakFallback(text, settings.language);
        }
        service.invoke('fired', {'id': r.id, 'title': text, 'isAdvanceNotice': true});
      }

      // --- periodic time announcement ---
      if (now.second == 0 && settings.timeReminder.enabled && settings.timeReminder.voiceAnnouncement) {
        final interval = settings.timeReminder.intervalMinutes.clamp(1, 1440);
        final totalMinutes = now.hour * 60 + now.minute;
        if (totalMinutes % interval == 0) {
          final key = 'periodic:$hhmm';
          if (!firedThisMinute.contains(key)) {
            firedThisMinute.add(key);
            final ok = await localVoice.speakTime(now, settings.language);
            if (!ok) await speakFallback('The time is now $hhmm', settings.language);
          }
        }
      }
    } catch (_) {
      // A single bad tick must never kill the whole background loop —
      // just try again next second.
    }
  });
}

// Ported unchanged from the app's original foreground timer logic
// (AppState._isAdvanceNoticeDue), so a reminder's "N minutes before" alert
// still fires correctly even when it wraps past midnight or across the
// week boundary (e.g. a Monday-00:05 reminder with a 10-minute advance
// notice needs to fire Sunday 23:55).
const _weekMinutes = 7 * 1440;
bool _isAdvanceNoticeDue(Reminder r, DateTime now) {
  final adv = r.advanceNotice;
  if (!adv.enabled) return false;
  final minutesBefore = adv.minutesBefore.clamp(1, 180);

  final parts = r.time.split(':');
  final reminderMinutesOfDay = int.parse(parts[0]) * 60 + int.parse(parts[1]);
  final days = (r.days.isEmpty) ? const [0, 1, 2, 3, 4, 5, 6] : r.days;

  final dow = now.weekday % 7;
  final currentWeekMinute = dow * 1440 + now.hour * 60 + now.minute;

  for (final d in days) {
    final weekMinute = d * 1440 + reminderMinutesOfDay;
    final advanceWeekMinute = (weekMinute - minutesBefore + _weekMinutes) % _weekMinutes;
    if (advanceWeekMinute == currentWeekMinute) return true;
  }
  return false;
}
