import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:flutter_timezone/flutter_timezone.dart';

import 'models.dart';
import 'i18n.dart';
import 'local_voice.dart';
import 'background_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

const _prefsKey = 'talking_clock_settings_v1';

// Notification-id ranges. Every call to _scheduleAllNotifications() cancels
// *everything* first and rebuilds from scratch, so these ranges only need
// to avoid colliding with each other within a single rebuild, not across
// app runs.
const int _remindersBase = 1000; // reminder i, day d -> 1000 + i*10 + d
const int _advanceBase = 5000; // same scheme, offset
const int _periodicBase = 20000; // one id per scheduled future occurrence

/// Fires once whenever a reminder/announcement goes off *while the app is
/// open*, so the clock screen can show a brief on-screen pulse/banner and
/// speak it out loud. Kept separate from AppState's own settings-change
/// notifications so a firing reminder doesn't trigger a full
/// settings-dependent rebuild everywhere.
///
/// IMPORTANT — how background operation actually works here:
/// Every reminder (and every periodic time announcement) is *also*
/// scheduled as a real Android system notification via
/// flutter_local_notifications' zonedSchedule, backed by AlarmManager.
/// That notification (title, body, sound, icon) will show up on time even
/// if this app has been fully closed/killed — Android itself wakes up and
/// displays it, no Dart code needs to be running.
/// What that scheduled notification can NOT do on its own is *speak* the
/// reminder out loud — text-to-speech needs Dart code actually executing,
/// which Android will only let happen if the app process is still alive
/// (foreground, or recently backgrounded and not yet killed). So: the
/// notification (with sound) is reliable always; the spoken voice is
/// reliable whenever the app hasn't been fully killed by the OS.
class FireEvent {
  final String id;
  final String title;
  final bool isAdvanceNotice;
  FireEvent({required this.id, required this.title, this.isAdvanceNotice = false});
}

/// Result of probing the device for working text-to-speech support.
/// Surfaced in the settings screen so a stuck/silent TV box can be
/// diagnosed from inside the app instead of guessing blindly.
class TtsDiagnostics {
  final bool engineFound;
  final List<String> engines;
  final String? defaultEngine;
  final String? lastError;
  TtsDiagnostics({
    required this.engineFound,
    required this.engines,
    required this.defaultEngine,
    required this.lastError,
  });
}

class AppState extends ChangeNotifier {
  AppSettings settings = AppSettings();
  bool loaded = false;
  // Set if something in init() failed in a way the user should know about
  // (shown as a small non-blocking banner rather than an endless spinner).
  String? initWarning;

  final FlutterTts _tts = FlutterTts();
  final LocalVoice _localVoice = LocalVoice();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // Tracks whether speech has ever actually produced sound on this device,
  // and the last error the TTS engine reported (if any), so the UI can
  // tell "silent because muted" apart from "silent because no engine".
  bool ttsEngineAvailable = true;
  String? lastTtsError;

  final StreamController<FireEvent> _fireController = StreamController<FireEvent>.broadcast();
  Stream<FireEvent> get fireStream => _fireController.stream;

  final StreamController<void> _tickController = StreamController<void>.broadcast();
  Stream<void> get tickStream => _tickController.stream;

  Timer? _timer;
  StreamSubscription? _bgSubscription;

  String t(String key) => I18n.t(settings.language, key);

  Future<void> init() async {
    // Every step below is wrapped individually and never rethrows, so a
    // single broken plugin call (very common on locked-down / custom TV
    // firmware) can't leave the whole app stuck behind the launch screen
    // forever. Anything that fails is recorded in initWarning instead.
    final warnings = <String>[];

    await _loadSettings();

    try {
      await _initTimeZone();
    } catch (e) {
      warnings.add('timezone: $e');
    }

    try {
      await _initNotifications();
    } catch (e) {
      warnings.add('notifications: $e');
    }

    try {
      await _setupTtsHandlers();
      await _applyTtsSettings();
    } catch (e) {
      warnings.add('tts: $e');
      ttsEngineAvailable = false;
      lastTtsError = e.toString();
    }

    if (settings.others.keepAwake) {
      try {
        WakelockPlus.enable();
      } catch (_) {
        // Not fatal — the clock just won't keep the screen awake.
      }
    }

    try {
      await _scheduleAllNotifications();
    } catch (e) {
      warnings.add('scheduling: $e');
    }

    // Background voice is opt-in (settings.others.backgroundVoice, off by
    // default) — see the field's doc comment in models.dart for why. Only
    // attempted at all if the person has explicitly turned it on.
    if (settings.others.backgroundVoice) {
      try {
        await _startBackgroundService();
      } catch (e) {
        warnings.add('background service: $e');
      }
    }

    if (warnings.isNotEmpty) {
      initWarning = warnings.join(' | ');
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    loaded = true;
    notifyListeners();
  }

  Future<void> _setupTtsHandlers() async {
    _tts.setErrorHandler((msg) {
      ttsEngineAvailable = false;
      lastTtsError = msg.toString();
      notifyListeners();
    });
    _tts.setStartHandler(() {
      // A speak() call actually started producing audio — the engine
      // clearly works, so clear any earlier stale error.
      ttsEngineAvailable = true;
      lastTtsError = null;
    });
  }

  /// Actively probes the device for a usable TTS engine, independent of
  /// whatever the last speak() attempt reported. Safe to call any time
  /// (e.g. from a "Diagnose sound" button in Settings) since it never
  /// throws — every failure mode is captured in the returned object.
  Future<TtsDiagnostics> diagnoseTts() async {
    List<String> engines = [];
    String? defaultEngine;
    String? error;
    try {
      final rawEngines = await _tts.getEngines;
      engines = (rawEngines as List).map((e) => e.toString()).toList();
    } catch (e) {
      error = e.toString();
    }
    try {
      final rawDefault = await _tts.getDefaultEngine;
      defaultEngine = rawDefault?.toString();
    } catch (e) {
      error ??= e.toString();
    }
    final found = engines.isNotEmpty || defaultEngine != null;
    ttsEngineAvailable = found;
    return TtsDiagnostics(
      engineFound: found,
      engines: engines,
      defaultEngine: defaultEngine,
      lastError: error,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bgSubscription?.cancel();
    _fireController.close();
    _tickController.close();
    _localVoice.dispose();
    super.dispose();
  }

  Future<void> _initTimeZone() async {
  tzdata.initializeTimeZones();
  try {
    final timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezone.identifier));
  } catch (_) {
    // Fall back to whatever the device's UTC-offset says "now" is, if the
    // timezone-name lookup fails for any reason.
  }
}

  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    settings = AppSettings();
    initWarning = null;
    await persist();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        settings = AppSettings.fromJson(jsonDecode(raw));
      } catch (_) {
        settings = AppSettings();
      }
    }
  }

  Future<void> _startBackgroundService() async {
    await setupBackgroundService();
    _bgSubscription ??= FlutterBackgroundService().on('fired').listen((data) {
      if (data == null) return;
      _fireController.add(FireEvent(
        id: data['id'] as String? ?? '',
        title: data['title'] as String? ?? '',
        isAdvanceNotice: data['isAdvanceNotice'] as bool? ?? false,
      ));
    });
  }

  /// Called from the Settings toggle. Turning it on tries to start the
  /// service right away (so the person gets immediate feedback if it
  /// fails on their device, via [lastTtsError]-style reporting through
  /// initWarning, instead of finding out only on next app launch).
  /// Turning it off asks the running service to stop itself and drops
  /// the event subscription — it will simply not be started again on the
  /// next launch, since the setting itself is what init() checks.
  Future<void> setBackgroundVoiceEnabled(bool enabled) async {
    settings.others.backgroundVoice = enabled;
    if (enabled) {
      try {
        await _startBackgroundService();
        initWarning = null;
      } catch (e) {
        initWarning = 'background service: $e';
        settings.others.backgroundVoice = false; // don't retry a known-broken setup on next launch
      }
    } else {
      try {
        FlutterBackgroundService().invoke('stopService');
      } catch (_) {}
      await _bgSubscription?.cancel();
      _bgSubscription = null;
    }
    await persist();
  }

  Future<void> persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(settings.toJson()));
    try {
      await _scheduleAllNotifications();
    } catch (e) {
      // Never let a scheduling hiccup (e.g. a plugin/permission error)
      // prevent the settings themselves from being saved, or leave an
      // unhandled error behind that could destabilize the next launch.
      initWarning = 'scheduling: $e';
    }
    notifyListeners();
  }

  Future<void> _initNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _notifications.initialize(
      initSettings,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTap,
    );
    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();
  }

  Future<void> _applyTtsSettings() async {
    await _tts.setLanguage(settings.language == 'ar' ? 'ar' : 'en-US');
    await _tts.setSpeechRate(settings.tts.rate);
    await _tts.setPitch(settings.tts.pitch);
    await _tts.setVolume(settings.tts.volume);
  }

  Future<void> speak(String text) async {
    if (settings.others.mute) return;
    try {
      await _applyTtsSettings();
      await _tts.stop();
      final result = await _tts.speak(text);
      // On Android, flutter_tts returns 0 (not an exception) when the
      // underlying call to the system TTS service fails — e.g. no engine
      // installed at all. That's exactly the silent-failure case we want
      // to surface instead of swallowing.
      if (result == 0) {
        ttsEngineAvailable = false;
        lastTtsError = 'speak() returned failure (no TTS engine on device?)';
        notifyListeners();
      }
    } catch (e) {
      ttsEngineAvailable = false;
      lastTtsError = e.toString();
      notifyListeners();
    }
  }

  Future<void> notify(String title, String body, {int id = 0}) async {
    if (settings.others.mute) return;
    const androidDetails = AndroidNotificationDetails(
      'talking_clock_channel',
      'Talking Clock',
      channelDescription: 'Reminders and time announcements',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _notifications.show(
      id != 0 ? id : DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  Future<void> setKeepAwake(bool value) async {
    settings.others.keepAwake = value;
    if (value) {
      await WakelockPlus.enable();
    } else {
      await WakelockPlus.disable();
    }
    await persist();
  }

  // ==========================================================
  // BACKGROUND SCHEDULING — this is what makes reminders and time
  // announcements keep firing (as real Android notifications, with
  // sound) even after the app itself has been closed/killed.
  // Called once at startup and again every time persist() runs (i.e.
  // any settings change), so the background schedule always reflects
  // exactly what's configured right now.
  // ==========================================================

  Future<void> _scheduleAllNotifications() async {
    if (settings.others.mute) {
      await _notifications.cancelAll();
      return;
    }
    await _notifications.cancelAll();

    for (int i = 0; i < settings.reminders.length; i++) {
      final r = settings.reminders[i];
      if (!r.enabled) continue;
      final days = (r.days.isEmpty || r.days.length == 7) ? const [0, 1, 2, 3, 4, 5, 6] : r.days;

      int hour, minute;
      try {
        final parts = r.time.split(':');
        hour = int.parse(parts[0]);
        minute = int.parse(parts[1]);
      } catch (_) {
        // Malformed time on this one reminder — skip only this reminder
        // instead of aborting scheduling for every other reminder too.
        continue;
      }

      for (final d in days) {
        await _scheduleWeekly(
          id: _remindersBase + i * 10 + d,
          weekday: d,
          hour: hour,
          minute: minute,
          title: r.title,
          body: _recurrenceLabel(r),
        );

        if (r.advanceNotice.enabled) {
          final before = r.advanceNotice.minutesBefore.clamp(1, 180);
          final total = hour * 60 + minute - before;
          final advDay = (d + (total < 0 ? 6 : 0)) % 7; // roll to previous day if it goes negative
          final normalized = ((total % 1440) + 1440) % 1440;
          await _scheduleWeekly(
            id: _advanceBase + i * 10 + d,
            weekday: advDay,
            hour: normalized ~/ 60,
            minute: normalized % 60,
            title: t('notify_before'),
            body: '${r.title} — $before ${t('minutes_before')}',
          );
        }
      }
    }

    if (settings.timeReminder.enabled && settings.timeReminder.systemNotification) {
      await _scheduleUpcomingPeriodicAnnouncements();
    }
  }

  /// Weekday here is Sun=0..Sat=6 (matches the rest of this app); Dart's
  /// own DateTime.weekday is Mon=1..Sun=7, converted where needed.
  Future<void> _scheduleWeekly({
    required int id,
    required int weekday,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final scheduled = _nextInstanceOfWeekdayTime(weekday, hour, minute);
    const androidDetails = AndroidNotificationDetails(
      'talking_clock_channel',
      'Talking Clock',
      channelDescription: 'Reminders and time announcements',
      importance: Importance.high,
      priority: Priority.high,
    );
    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // If the exact-alarm permission was denied, fall back to an inexact
      // schedule rather than silently having no background alert at all.
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  tz.TZDateTime _nextInstanceOfWeekdayTime(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    // Dart weekday: Mon=1..Sun=7. Our weekday: Sun=0..Sat=6.
    final targetDartWeekday = weekday == 0 ? 7 : weekday;
    while (scheduled.weekday != targetDartWeekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Periodic announcements don't repeat on a fixed weekly pattern, so
  /// instead this just queues up every remaining occurrence for the next
  /// 48 hours as one-off scheduled notifications. Re-run automatically
  /// every time settings change and once at every app launch, so as long
  /// as the app is opened at least once every couple of days the queue
  /// never runs dry. (This is the one place where a fully-killed app for
  /// several days straight could fall behind — opening the app for a
  /// moment refills the queue.)
  Future<void> _scheduleUpcomingPeriodicAnnouncements() async {
    final interval = settings.timeReminder.intervalMinutes.clamp(1, 1440);
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, now.hour)
        .add(Duration(minutes: (now.minute ~/ interval + 1) * interval));

    const androidDetails = AndroidNotificationDetails(
      'talking_clock_channel',
      'Talking Clock',
      channelDescription: 'Reminders and time announcements',
      importance: Importance.high,
      priority: Priority.high,
    );

    int idOffset = 0;
    final limit = now.add(const Duration(hours: 48));
    while (next.isBefore(limit)) {
      final hh = next.hour.toString().padLeft(2, '0');
      final mm = next.minute.toString().padLeft(2, '0');
      await _notifications.zonedSchedule(
        _periodicBase + idOffset,
        t('app_title'),
        '$hh:$mm',
        next,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      idOffset++;
      next = next.add(Duration(minutes: interval));
    }
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTap(NotificationResponse response) {
    // Runs in a limited background isolate when the user taps a
    // notification while the app isn't already running. There is
    // deliberately very little here — see the class doc comment above for
    // why speech can't reliably happen from a fully-killed app state.
  }

  // ---------------- in-app scheduler (visual pulse + speech while the
  // app itself is alive; the actual notification is handled above by the
  // OS regardless of whether the app is open) ----------------

  // NOTE: This no longer fires reminders/announcements itself — that's
  // now the background service's job exclusively (background_service.dart),
  // so the clock never speaks twice (once from each isolate) when the
  // app happens to be open at the moment something fires. This just
  // keeps the on-screen digits ticking every second; the visual
  // banner/pulse for a firing reminder arrives via the 'fired' event
  // from the background service (see init()) instead.
  void _tick() {
    _tickController.add(null);
  }

  /// Speech + on-screen pulse only — the actual notification for this
  /// exact firing was already scheduled natively (see above), so this
  /// does not call notify() again (that would show a duplicate banner
  /// while the app happens to be open).
  void _fireReminderEffects(Reminder r) {
    if (r.presetId != null) {
      _localVoice.speakPreset(r.presetId!, settings.language).then((ok) {
        if (!ok) speak(r.title);
      });
    } else {
      speak(r.title);
    }
    _fireController.add(FireEvent(id: r.id, title: r.title));
  }

  void _fireAdvanceNoticeEffects(Reminder r) {
    final minutes = r.advanceNotice.minutesBefore;
    final text = '${r.title} in $minutes minute${minutes == 1 ? '' : 's'}';
    if (r.presetId != null) {
      _localVoice.speakPresetAdvanceNotice(r.presetId!, minutes, settings.language).then((ok) {
        if (!ok) speak(text);
      });
    } else {
      speak(text);
    }
    _fireController.add(FireEvent(id: r.id, title: text, isAdvanceNotice: true));
  }

  void _firePeriodicAnnouncementEffects(DateTime now) {
    if (settings.timeReminder.voiceAnnouncement) {
      if (settings.tts.useLocalVoice) {
        // Try the bundled recorded-voice clips first — this is what keeps
        // the clock speaking even on devices with no system TTS engine.
        // If a clip is missing or playback fails, fall back to the system
        // TTS engine so the announcement still has a chance to be heard.
        _localVoice.speakTime(now, settings.language).then((ok) {
          if (!ok) speak('The time is ${_spokenTime(now)}');
        });
      } else {
        speak('The time is ${_spokenTime(now)}');
      }
    }
  }

  /// Manually fires a reminder right now — used by the "Test" button in
  /// the reminders list. Unlike the real scheduled firing, this DOES also
  /// call notify() directly, since it's a one-off manual preview rather
  /// than something already covered by a background-scheduled alarm.
  void testFire(Reminder r) {
    notify(r.title, _recurrenceLabel(r));
    if (r.presetId != null) {
      _localVoice.speakPreset(r.presetId!, settings.language).then((ok) {
        if (!ok) speak(r.title);
      });
    } else {
      speak(r.title);
    }
    _fireController.add(FireEvent(id: r.id, title: r.title));
  }

  void testAdvance(Reminder r) {
    final minutes = r.advanceNotice.minutesBefore;
    final text = '${r.title} in $minutes minute${minutes == 1 ? '' : 's'}';
    notify(t('notify_before'), text);
    if (r.presetId != null) {
      _localVoice.speakPresetAdvanceNotice(r.presetId!, minutes, settings.language).then((ok) {
        if (!ok) speak(text);
      });
    } else {
      speak(text);
    }
    _fireController.add(FireEvent(id: r.id, title: text, isAdvanceNotice: true));
  }

  String _recurrenceLabel(Reminder r) {
    const names = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    if (r.days.isEmpty || r.days.length == 7) {
      return '${t('every_day')} ${t('at')} ${r.time}';
    }
    final sorted = [...r.days]..sort();
    return '${t('every_week_on')} ${sorted.map((d) => names[d]).join(', ')} ${t('at')} ${r.time}';
  }

  static const _ones = [
    'zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten',
    'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen'
  ];
  static const _tens = ['', '', 'twenty', 'thirty', 'forty', 'fifty'];

  static String _numberToWords(int n) {
    n = n.clamp(0, 59);
    if (n < 20) return _ones[n];
    final tensPart = n ~/ 10;
    final onesPart = n % 10;
    return _tens[tensPart] + (onesPart != 0 ? '-${_ones[onesPart]}' : '');
  }

  static String _spokenTime(DateTime now) {
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    int h12 = now.hour % 12;
    if (h12 == 0) h12 = 12;
    final hourWord = _numberToWords(h12);
    String minutePhrase;
    if (now.minute == 0) {
      minutePhrase = "o'clock";
    } else if (now.minute < 10) {
      minutePhrase = 'oh ${_numberToWords(now.minute)}';
    } else {
      minutePhrase = _numberToWords(now.minute);
    }
    return '$hourWord $minutePhrase $ampm';
  }

  // ---------------- reminder CRUD ----------------

  Future<void> addReminder(Reminder r) async {
    settings.reminders.add(r);
    await persist();
  }

  Future<void> updateReminder(Reminder r) async {
    final idx = settings.reminders.indexWhere((x) => x.id == r.id);
    if (idx != -1) settings.reminders[idx] = r;
    await persist();
  }

  Future<void> deleteReminder(String id) async {
    settings.reminders.removeWhere((r) => r.id == id);
    await persist();
  }

  Future<void> toggleReminder(String id, bool enabled) async {
    final r = settings.reminders.firstWhere((x) => x.id == id);
    r.enabled = enabled;
    await persist();
  }
}
