/// A fixed, known-in-advance vocabulary of common reminder titles. Because
/// these never change, their audio can be pre-recorded and bundled with
/// the app (see local_voice.dart + generate_voice_clips.py), so a reminder
/// built from one of these speaks reliably on any device — even one with
/// no system TTS engine at all.
///
/// Picking one of these is the "guaranteed voice" option in the reminder
/// dialog, as an alternative to typing a free-text title (which still
/// works, but depends on the device's system TTS engine being present).
class ReminderPreset {
  final String id;
  final String labelAr;
  final String labelEn;
  const ReminderPreset(this.id, this.labelAr, this.labelEn);

  String label(String language) => language == 'ar' ? labelAr : labelEn;
}

const List<ReminderPreset> reminderPresets = [
  ReminderPreset('medicine', 'حان موعد الدواء', 'Time for your medicine'),
  ReminderPreset('prayer', 'حان وقت الصلاة', 'Time for prayer'),
  ReminderPreset('meeting', 'حان موعد الاجتماع', 'Time for your meeting'),
  ReminderPreset('wakeup', 'حان وقت الاستيقاظ', 'Time to wake up'),
  ReminderPreset('doctor', 'حان موعد الطبيب', 'Time for your doctor appointment'),
  ReminderPreset('breakfast', 'حان وقت الفطور', 'Time for breakfast'),
  ReminderPreset('lunch', 'حان وقت الغداء', 'Time for lunch'),
  ReminderPreset('dinner', 'حان وقت العشاء', 'Time for dinner'),
  ReminderPreset('exercise', 'حان وقت التمرين', 'Time to exercise'),
  ReminderPreset('coffee', 'حان وقت استراحة القهوة', 'Time for a coffee break'),
  ReminderPreset('rest', 'حان وقت الراحة', 'Time to rest'),
  ReminderPreset('sleep', 'حان وقت النوم', 'Time to sleep'),
  ReminderPreset('call', 'لا تنسَ الاتصال المهم', "Don't forget your important call"),
  ReminderPreset('water', 'لا تنسَ شرب الماء', "Don't forget to drink water"),
];

ReminderPreset? findReminderPreset(String? id) {
  if (id == null) return null;
  for (final p in reminderPresets) {
    if (p.id == id) return p;
  }
  return null;
}
