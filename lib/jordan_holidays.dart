class Holiday {
  final DateTime date;
  final String nameEn;
  final String nameAr;
  const Holiday(this.date, this.nameEn, this.nameAr);
}

/// Supported countries for the holiday calendar, in the order shown in
/// the country picker. Add a new entry here (and a matching list below)
/// to support another country.
const Map<String, String> holidayCountryNamesAr = {
  'QA': 'قطر',
  'JO': 'الأردن',
  'US': 'الولايات المتحدة',
};
const Map<String, String> holidayCountryNamesEn = {
  'QA': 'Qatar',
  'JO': 'Jordan',
  'US': 'United States',
};

/// Official Qatar public holidays. Islamic-calendar holidays (Eid
/// al-Fitr, Eid al-Adha) shift every year based on moon sightings, so
/// they're a hand-maintained per-year table — add next year's dates here
/// once officially announced.
final List<Holiday> _qatarHolidays = [
  // ---- 2026 ----
  Holiday(DateTime(2026, 1, 1), "New Year's Day", 'رأس السنة الميلادية'),
  Holiday(DateTime(2026, 2, 10), 'National Sports Day', 'اليوم الرياضي'),
  Holiday(DateTime(2026, 3, 20), 'Eid al-Fitr', 'عيد الفطر'),
  Holiday(DateTime(2026, 3, 21), 'Eid al-Fitr Holiday', 'عطلة عيد الفطر'),
  Holiday(DateTime(2026, 3, 22), 'Eid al-Fitr Holiday', 'عطلة عيد الفطر'),
  Holiday(DateTime(2026, 5, 26), 'Arafat Day', 'يوم عرفة'),
  Holiday(DateTime(2026, 5, 27), 'Eid al-Adha', 'عيد الأضحى'),
  Holiday(DateTime(2026, 5, 28), 'Eid al-Adha Holiday', 'عطلة عيد الأضحى'),
  Holiday(DateTime(2026, 5, 29), 'Eid al-Adha Holiday', 'عطلة عيد الأضحى'),
  Holiday(DateTime(2026, 12, 18), 'Qatar National Day', 'اليوم الوطني لقطر'),

  // ---- 2027 (Islamic dates tentative, pending moon-sighting confirmation) ----
  Holiday(DateTime(2027, 1, 1), "New Year's Day", 'رأس السنة الميلادية'),
  Holiday(DateTime(2027, 2, 9), 'National Sports Day', 'اليوم الرياضي'),
  Holiday(DateTime(2027, 3, 9), 'Eid al-Fitr', 'عيد الفطر'),
  Holiday(DateTime(2027, 3, 10), 'Eid al-Fitr Holiday', 'عطلة عيد الفطر'),
  Holiday(DateTime(2027, 3, 11), 'Eid al-Fitr Holiday', 'عطلة عيد الفطر'),
  Holiday(DateTime(2027, 5, 15), 'Arafat Day', 'يوم عرفة'),
  Holiday(DateTime(2027, 5, 16), 'Eid al-Adha', 'عيد الأضحى'),
  Holiday(DateTime(2027, 5, 17), 'Eid al-Adha Holiday', 'عطلة عيد الأضحى'),
  Holiday(DateTime(2027, 5, 18), 'Eid al-Adha Holiday', 'عطلة عيد الأضحى'),
  Holiday(DateTime(2027, 12, 18), 'Qatar National Day', 'اليوم الوطني لقطر'),
];

/// Official Jordan public holidays (same source table as before).
final List<Holiday> _jordanHolidays = [
  // ---- 2026 ----
  Holiday(DateTime(2026, 1, 1), "New Year's Day", 'رأس السنة الميلادية'),
  Holiday(DateTime(2026, 3, 20), 'Eid al-Fitr', 'عيد الفطر'),
  Holiday(DateTime(2026, 3, 21), 'Eid al-Fitr Holiday', 'عطلة عيد الفطر'),
  Holiday(DateTime(2026, 3, 22), 'Eid al-Fitr Holiday', 'عطلة عيد الفطر'),
  Holiday(DateTime(2026, 3, 23), 'Eid al-Fitr Holiday', 'عطلة عيد الفطر'),
  Holiday(DateTime(2026, 5, 1), 'Labour Day', 'عيد العمال'),
  Holiday(DateTime(2026, 5, 25), 'Independence Day', 'عيد الاستقلال'),
  Holiday(DateTime(2026, 5, 26), 'Arafat Day', 'يوم عرفة'),
  Holiday(DateTime(2026, 5, 27), 'Eid al-Adha', 'عيد الأضحى'),
  Holiday(DateTime(2026, 5, 28), 'Eid al-Adha Holiday', 'عطلة عيد الأضحى'),
  Holiday(DateTime(2026, 5, 29), 'Eid al-Adha Holiday', 'عطلة عيد الأضحى'),
  Holiday(DateTime(2026, 5, 30), 'Eid al-Adha Holiday', 'عطلة عيد الأضحى'),
  Holiday(DateTime(2026, 6, 16), 'Islamic New Year', 'رأس السنة الهجرية'),
  Holiday(DateTime(2026, 8, 25), "Prophet Muhammad's Birthday", 'المولد النبوي الشريف'),
  Holiday(DateTime(2026, 12, 25), 'Christmas Day', 'عيد الميلاد المجيد'),

  // ---- 2027 (Islamic dates tentative, pending moon-sighting confirmation) ----
  Holiday(DateTime(2027, 1, 1), "New Year's Day", 'رأس السنة الميلادية'),
  Holiday(DateTime(2027, 3, 9), 'Eid al-Fitr', 'عيد الفطر'),
  Holiday(DateTime(2027, 3, 10), 'Eid al-Fitr Holiday', 'عطلة عيد الفطر'),
  Holiday(DateTime(2027, 3, 11), 'Eid al-Fitr Holiday', 'عطلة عيد الفطر'),
  Holiday(DateTime(2027, 3, 12), 'Eid al-Fitr Holiday', 'عطلة عيد الفطر'),
  Holiday(DateTime(2027, 5, 1), 'Labour Day', 'عيد العمال'),
  Holiday(DateTime(2027, 5, 15), 'Arafat Day', 'يوم عرفة'),
  Holiday(DateTime(2027, 5, 16), 'Eid al-Adha', 'عيد الأضحى'),
  Holiday(DateTime(2027, 5, 17), 'Eid al-Adha Holiday', 'عطلة عيد الأضحى'),
  Holiday(DateTime(2027, 5, 18), 'Eid al-Adha Holiday', 'عطلة عيد الأضحى'),
  Holiday(DateTime(2027, 5, 19), 'Eid al-Adha Holiday', 'عطلة عيد الأضحى'),
  Holiday(DateTime(2027, 5, 25), 'Independence Day', 'عيد الاستقلال'),
  Holiday(DateTime(2027, 6, 6), 'Islamic New Year', 'رأس السنة الهجرية'),
  Holiday(DateTime(2027, 8, 14), "Prophet Muhammad's Birthday", 'المولد النبوي الشريف'),
  Holiday(DateTime(2027, 12, 25), 'Christmas Day', 'عيد الميلاد المجيد'),
];

/// US federal holidays. These are fixed by law to specific weekdays
/// (e.g. "3rd Monday of January"), so — unlike the Islamic-calendar
/// dates above — they don't need yearly manual confirmation, but are
/// still listed per-year for simplicity.
final List<Holiday> _usHolidays = [
  // ---- 2026 ----
  Holiday(DateTime(2026, 1, 1), "New Year's Day", 'رأس السنة الميلادية'),
  Holiday(DateTime(2026, 1, 19), 'Martin Luther King Jr. Day', 'يوم مارتن لوثر كينغ'),
  Holiday(DateTime(2026, 2, 16), "Presidents' Day", 'يوم الرؤساء'),
  Holiday(DateTime(2026, 5, 25), 'Memorial Day', 'يوم الذكرى'),
  Holiday(DateTime(2026, 6, 19), 'Juneteenth', 'يوم جوونتينث'),
  Holiday(DateTime(2026, 7, 3), 'Independence Day (observed)', 'عيد الاستقلال (يُراعى)'),
  Holiday(DateTime(2026, 7, 4), 'Independence Day', 'عيد الاستقلال'),
  Holiday(DateTime(2026, 9, 7), 'Labor Day', 'عيد العمال'),
  Holiday(DateTime(2026, 10, 12), 'Columbus Day', 'يوم كولومبوس'),
  Holiday(DateTime(2026, 11, 11), 'Veterans Day', 'يوم المحاربين القدامى'),
  Holiday(DateTime(2026, 11, 26), 'Thanksgiving Day', 'عيد الشكر'),
  Holiday(DateTime(2026, 12, 25), 'Christmas Day', 'عيد الميلاد المجيد'),

  // ---- 2027 ----
  Holiday(DateTime(2027, 1, 1), "New Year's Day", 'رأس السنة الميلادية'),
  Holiday(DateTime(2027, 1, 18), 'Martin Luther King Jr. Day', 'يوم مارتن لوثر كينغ'),
  Holiday(DateTime(2027, 2, 15), "Presidents' Day", 'يوم الرؤساء'),
  Holiday(DateTime(2027, 5, 31), 'Memorial Day', 'يوم الذكرى'),
  Holiday(DateTime(2027, 6, 18), 'Juneteenth (observed)', 'يوم جوونتينث (يُراعى)'),
  Holiday(DateTime(2027, 7, 4), 'Independence Day', 'عيد الاستقلال'),
  Holiday(DateTime(2027, 7, 5), 'Independence Day (observed)', 'عيد الاستقلال (يُراعى)'),
  Holiday(DateTime(2027, 9, 6), 'Labor Day', 'عيد العمال'),
  Holiday(DateTime(2027, 10, 11), 'Columbus Day', 'يوم كولومبوس'),
  Holiday(DateTime(2027, 11, 11), 'Veterans Day', 'يوم المحاربين القدامى'),
  Holiday(DateTime(2027, 11, 25), 'Thanksgiving Day', 'عيد الشكر'),
  Holiday(DateTime(2027, 12, 25), 'Christmas Day', 'عيد الميلاد المجيد'),
];

final Map<String, List<Holiday>> countryHolidays = {
  'QA': _qatarHolidays,
  'JO': _jordanHolidays,
  'US': _usHolidays,
};

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

Holiday? holidayOn(DateTime day, String countryCode) {
  final list = countryHolidays[countryCode] ?? _qatarHolidays;
  for (final h in list) {
    if (_sameDate(h.date, day)) return h;
  }
  return null;
}

Holiday? nextHolidayAfter(DateTime now, String countryCode) {
  final list = countryHolidays[countryCode] ?? _qatarHolidays;
  final today = DateTime(now.year, now.month, now.day);
  for (final h in list) {
    if (h.date.isAfter(today)) return h;
  }
  return null;
}
