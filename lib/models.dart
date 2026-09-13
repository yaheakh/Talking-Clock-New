class AdvanceNotice {
  bool enabled;
  int minutesBefore;
  AdvanceNotice({this.enabled = false, this.minutesBefore = 5});

  Map<String, dynamic> toJson() => {'enabled': enabled, 'minutesBefore': minutesBefore};
  factory AdvanceNotice.fromJson(Map<String, dynamic>? j) => AdvanceNotice(
        enabled: j?['enabled'] ?? false,
        minutesBefore: j?['minutesBefore'] ?? 5,
      );
}

class Reminder {
  String id;
  String title;
  String time; // "HH:MM", 24h
  List<int> days; // 0=Sun .. 6=Sat, empty/full = every day
  bool enabled;
  AdvanceNotice advanceNotice;
  // If set, this reminder was created from the fixed preset list (see
  // reminder_presets.dart) instead of free-typed text. Presets have
  // pre-recorded audio bundled with the app, so they speak reliably even
  // without a system TTS engine — free-text titles (presetId == null)
  // still work, but need the system TTS engine to actually be heard.
  String? presetId;

  Reminder({
    required this.id,
    required this.title,
    required this.time,
    required this.days,
    this.enabled = true,
    AdvanceNotice? advanceNotice,
    this.presetId,
  }) : advanceNotice = advanceNotice ?? AdvanceNotice();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'time': time,
        'days': days,
        'enabled': enabled,
        'advanceNotice': advanceNotice.toJson(),
        'presetId': presetId,
      };

  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
        id: j['id'],
        title: j['title'],
        time: j['time'],
        days: List<int>.from(j['days'] ?? const [0, 1, 2, 3, 4, 5, 6]),
        enabled: j['enabled'] ?? true,
        advanceNotice: AdvanceNotice.fromJson(j['advanceNotice']),
        presetId: j['presetId'] as String?,
      );
}

class TimeReminderSettings {
  bool enabled;
  int intervalMinutes;
  bool voiceAnnouncement;
  bool systemNotification;
  TimeReminderSettings({
    this.enabled = true,
    this.intervalMinutes = 30,
    this.voiceAnnouncement = true,
    this.systemNotification = false,
  });

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'intervalMinutes': intervalMinutes,
        'voiceAnnouncement': voiceAnnouncement,
        'systemNotification': systemNotification,
      };
  factory TimeReminderSettings.fromJson(Map<String, dynamic>? j) => TimeReminderSettings(
        enabled: j?['enabled'] ?? true,
        intervalMinutes: j?['intervalMinutes'] ?? 30,
        voiceAnnouncement: j?['voiceAnnouncement'] ?? true,
        systemNotification: j?['systemNotification'] ?? false,
      );
}

class TtsSettings {
  double rate;
  double pitch;
  double volume;
  // When true, the periodic time announcement is spoken by stitching
  // together short pre-recorded audio clips instead of the device's
  // system TTS engine. This is what makes the clock speak reliably even
  // on locked-down TV boxes with no TTS engine installed at all.
  // Custom reminder titles (free text) still need the system TTS, since
  // they can't be pre-recorded.
  bool useLocalVoice;
  TtsSettings({this.rate = 0.5, this.pitch = 1.0, this.volume = 1.0, this.useLocalVoice = true});

  Map<String, dynamic> toJson() => {'rate': rate, 'pitch': pitch, 'volume': volume, 'useLocalVoice': useLocalVoice};
  factory TtsSettings.fromJson(Map<String, dynamic>? j) => TtsSettings(
        rate: (j?['rate'] ?? 0.5).toDouble(),
        pitch: (j?['pitch'] ?? 1.0).toDouble(),
        volume: (j?['volume'] ?? 1.0).toDouble(),
        useLocalVoice: (j?['useLocalVoice'] ?? true) as bool,
      );
}

class ClockSettings {
  bool showSeconds;
  bool showDate;
  bool showReminders;
  bool showHolidays;
  bool showWorldClocks;
  int hourFormat; // 12 or 24
  String textSize; // normal | large | xlarge
  String theme; // aurora | cyan | amber | minimal
  String holidayCountry; // 'QA' | 'JO' | 'US' — which calendar to show holidays for

  ClockSettings({
    this.showSeconds = true,
    this.showDate = true,
    this.showReminders = false,
    this.showHolidays = false,
    this.showWorldClocks = true,
    this.hourFormat = 12,
    this.textSize = 'xlarge',
    this.theme = 'aurora',
    this.holidayCountry = 'QA',
  });

  Map<String, dynamic> toJson() => {
        'showSeconds': showSeconds,
        'showDate': showDate,
        'showReminders': showReminders,
        'showHolidays': showHolidays,
        'showWorldClocks': showWorldClocks,
        'hourFormat': hourFormat,
        'textSize': textSize,
        'theme': theme,
        'holidayCountry': holidayCountry,
      };
  factory ClockSettings.fromJson(Map<String, dynamic>? j) => ClockSettings(
        showSeconds: j?['showSeconds'] ?? true,
        showDate: j?['showDate'] ?? true,
        showReminders: j?['showReminders'] ?? false,
        showHolidays: j?['showHolidays'] ?? false,
        showWorldClocks: j?['showWorldClocks'] ?? true,
        hourFormat: j?['hourFormat'] ?? 12,
        textSize: j?['textSize'] ?? 'xlarge',
        theme: j?['theme'] ?? 'aurora',
        holidayCountry: j?['holidayCountry'] ?? 'QA',
      );
}

class OtherSettings {
  bool mute;
  bool keepAwake;
  // Off by default — starting a real Android foreground service is one
  // of the riskiest things an app can do on a given device/ROM/Android
  // version combination, and failures can happen at the native layer in
  // ways no amount of Dart-side try/catch can fully protect against.
  // Keeping this opt-in guarantees the base app (clock, reminders,
  // in-app voice) always works; the person can turn this on deliberately
  // to test it on their specific device.
  bool backgroundVoice;
  OtherSettings({this.mute = false, this.keepAwake = true, this.backgroundVoice = false});

  Map<String, dynamic> toJson() => {'mute': mute, 'keepAwake': keepAwake, 'backgroundVoice': backgroundVoice};
  factory OtherSettings.fromJson(Map<String, dynamic>? j) => OtherSettings(
        mute: j?['mute'] ?? false,
        keepAwake: j?['keepAwake'] ?? true,
        backgroundVoice: j?['backgroundVoice'] ?? false,
      );
}

class AppSettings {
  String language; // 'en' | 'ar'
  List<Reminder> reminders;
  TimeReminderSettings timeReminder;
  TtsSettings tts;
  ClockSettings clock;
  OtherSettings others;

  AppSettings({
    this.language = 'en',
    List<Reminder>? reminders,
    TimeReminderSettings? timeReminder,
    TtsSettings? tts,
    ClockSettings? clock,
    OtherSettings? others,
  })  : reminders = reminders ?? defaultReminders(),
        timeReminder = timeReminder ?? TimeReminderSettings(),
        tts = tts ?? TtsSettings(),
        clock = clock ?? ClockSettings(),
        others = others ?? OtherSettings();

  static List<Reminder> defaultReminders() => [];

  Map<String, dynamic> toJson() => {
        'language': language,
        'reminders': reminders.map((r) => r.toJson()).toList(),
        'timeReminder': timeReminder.toJson(),
        'tts': tts.toJson(),
        'clock': clock.toJson(),
        'others': others.toJson(),
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        language: j['language'] ?? 'en',
        reminders: (j['reminders'] as List?)
                ?.map((e) => Reminder.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            defaultReminders(),
        timeReminder: TimeReminderSettings.fromJson(j['timeReminder']),
        tts: TtsSettings.fromJson(j['tts']),
        clock: ClockSettings.fromJson(j['clock']),
        others: OtherSettings.fromJson(j['others']),
      );
}
