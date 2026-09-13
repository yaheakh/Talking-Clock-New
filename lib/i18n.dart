/// Small hand-written translation table (no ARB/codegen — easier to keep
/// in sync with the app by hand for a project this size). Add a key here
/// and reference it with `t(context, 'key')` anywhere in the UI.
class I18n {
  static const Map<String, Map<String, String>> _strings = {
    'app_title': {'en': 'Talking Clock', 'ar': 'الساعة الناطقة'},
    'settings': {'en': 'Settings', 'ar': 'الإعدادات'},
    'back_to_clock': {'en': 'Back to clock', 'ar': 'العودة للساعة'},
    'reminders_title': {'en': "Today's Reminders", 'ar': 'تذكيرات اليوم'},
    'add_reminder': {'en': 'Add a reminder', 'ar': 'إضافة تذكير'},
    'no_reminders_today': {'en': 'No reminders today', 'ar': 'لا توجد تذكيرات اليوم'},
    'edit': {'en': 'Edit', 'ar': 'تعديل'},
    'delete': {'en': 'Delete', 'ar': 'حذف'},
    'test': {'en': 'Test', 'ar': 'تجربة'},

    // Tabs
    'tab_reminders': {'en': 'Reminders', 'ar': 'التذكيرات'},
    'tab_time_reminder': {'en': 'Time Reminder', 'ar': 'تذكير الوقت'},
    'tab_voice': {'en': 'Voice', 'ar': 'الصوت'},
    'tab_display': {'en': 'Clock & Display', 'ar': 'الساعة والعرض'},
    'tab_others': {'en': 'Others', 'ar': 'أخرى'},

    // Reminders tab
    'add_reminder_btn': {'en': '+ Add Reminder', 'ar': '+ إضافة تذكير'},
    'modal_add_title': {'en': 'Add Reminder', 'ar': 'إضافة تذكير'},
    'modal_edit_title': {'en': 'Edit Reminder', 'ar': 'تعديل تذكير'},
    'title_label': {'en': 'Title', 'ar': 'العنوان'},
    'title_placeholder': {'en': 'e.g. Team meeting', 'ar': 'مثال: اجتماع الفريق'},
    'title_error': {'en': 'Please enter a title.', 'ar': 'الرجاء إدخال عنوان.'},
    'time_label': {'en': 'Time', 'ar': 'الوقت'},
    'repeat_on': {'en': 'Repeat on', 'ar': 'يتكرر في'},
    'enable': {'en': 'Enable', 'ar': 'تفعيل'},
    'notify_before': {'en': 'Notify me a few minutes before', 'ar': 'نبّهني قبل بضع دقائق'},
    'minutes_before': {'en': 'minutes before', 'ar': 'دقيقة قبل الموعد'},
    'cancel': {'en': 'Cancel', 'ar': 'إلغاء'},
    'save': {'en': 'Save', 'ar': 'حفظ'},
    'day_sun': {'en': 'Sun', 'ar': 'أحد'},
    'day_mon': {'en': 'Mon', 'ar': 'إثنين'},
    'day_tue': {'en': 'Tue', 'ar': 'ثلاثاء'},
    'day_wed': {'en': 'Wed', 'ar': 'أربعاء'},
    'day_thu': {'en': 'Thu', 'ar': 'خميس'},
    'day_fri': {'en': 'Fri', 'ar': 'جمعة'},
    'day_sat': {'en': 'Sat', 'ar': 'سبت'},
    'every_day': {'en': 'Every day', 'ar': 'كل يوم'},
    'every_week_on': {'en': 'Every week on', 'ar': 'كل أسبوع في'},
    'at': {'en': 'at', 'ar': 'الساعة'},

    // Time Reminder tab
    'announce_interval': {'en': 'Announce Interval', 'ar': 'فاصل الإعلان الصوتي'},
    'minutes': {'en': 'minutes', 'ar': 'دقيقة'},
    'interval_hint': {'en': 'Any number of minutes (e.g. 10, 45, 90).', 'ar': 'أي عدد من الدقائق (مثلاً 10 أو 45 أو 90).'},
    'voice_announcement': {'en': 'Voice Announcement', 'ar': 'إعلان صوتي'},
    'system_notification': {'en': 'System Notification', 'ar': 'إشعار النظام'},

    // Voice tab
    'rate': {'en': 'Speech Rate', 'ar': 'سرعة الكلام'},
    'pitch': {'en': 'Pitch', 'ar': 'حدة الصوت'},
    'volume': {'en': 'Volume', 'ar': 'مستوى الصوت'},
    'test_voice_placeholder': {'en': 'Type text to test the voice...', 'ar': 'اكتب نصاً لتجربة الصوت...'},
    'test_voice': {'en': 'Test Voice', 'ar': 'تجربة الصوت'},

    // Clock & Display tab
    'language': {'en': 'Language', 'ar': 'اللغة'},
    'lang_en': {'en': 'English', 'ar': 'الإنجليزية (English)'},
    'lang_ar': {'en': 'العربية (Arabic)', 'ar': 'العربية'},
    'color_theme': {'en': 'Color Theme', 'ar': 'لون الثيم'},
    'theme_aurora': {'en': 'Aurora', 'ar': 'أورورا'},
    'theme_cyan': {'en': 'Neon Cyan', 'ar': 'سماوي نيون'},
    'theme_amber': {'en': 'Amber Night', 'ar': 'كهرماني ليلي'},
    'theme_minimal': {'en': 'Minimal Contrast', 'ar': 'تباين بسيط'},
    'display': {'en': 'Display', 'ar': 'العرض'},
    'display_seconds': {'en': 'Display Seconds', 'ar': 'إظهار الثواني'},
    'display_date': {'en': 'Display Date & Calendar', 'ar': 'إظهار التاريخ والتقويم'},
    'display_reminders': {'en': "Display Today's Reminders", 'ar': 'إظهار تذكيرات اليوم'},
    'display_holidays': {'en': 'Display Holiday Calendar (Jordan)', 'ar': 'إظهار تقويم العطل الرسمية (الأردن)'},
    'text_size': {'en': 'Text Size', 'ar': 'حجم الخط'},
    'size_normal': {'en': 'Normal', 'ar': 'عادي'},
    'size_large': {'en': 'Large (default)', 'ar': 'كبير (افتراضي)'},
    'size_xlarge': {'en': 'Extra Large', 'ar': 'كبير جداً'},
    'hour_format': {'en': 'Hour Format', 'ar': 'صيغة الوقت'},
    'hour_12': {'en': '12-hour', 'ar': '12 ساعة'},
    'hour_24': {'en': '24-hour', 'ar': '24 ساعة'},

    // Others tab
    'mute_all': {'en': 'Mute all notifications and voices', 'ar': 'كتم كل الإشعارات والأصوات'},
    'keep_awake': {'en': 'Keep the screen awake while this is open', 'ar': 'إبقاء الشاشة مضاءة طالما التطبيق مفتوح'},

    // Holiday panel
    'today_label': {'en': 'Today', 'ar': 'اليوم'},
    'regular_day': {'en': 'Regular day', 'ar': 'يوم عادي'},
    'holiday_today': {'en': 'Official holiday today', 'ar': 'عطلة رسمية اليوم'},
    'next_holiday': {'en': 'Next official holiday', 'ar': 'العطلة الرسمية القادمة'},
    'no_upcoming_holiday': {'en': 'No upcoming holiday in the current data', 'ar': 'لا توجد عطلة رسمية قادمة ضمن البيانات المتوفرة'},
    'today_word': {'en': 'today', 'ar': 'اليوم'},
    'tomorrow_word': {'en': 'tomorrow', 'ar': 'غداً'},
    'in_days': {'en': 'in {n} days', 'ar': 'خلال {n} يوم'},
  };

  static String t(String lang, String key) {
    return _strings[key]?[lang] ?? _strings[key]?['en'] ?? key;
  }
}
