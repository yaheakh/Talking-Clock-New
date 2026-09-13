import 'package:flutter/material.dart';
import 'app_state.dart';
import 'models.dart';
import 'themes.dart';
import 'reminder_presets.dart';

Future<void> showReminderDialog(BuildContext context, AppState app, {Reminder? existing}) {
  final palette = appPalettes[app.settings.clock.theme]!;
  final titleCtrl = TextEditingController(text: existing?.title ?? '');
  // Preset mode = guaranteed-voice mode: the title comes from the fixed,
  // pre-recorded list instead of free text. Defaults to preset mode for
  // new reminders (safer default on unknown devices); existing free-text
  // reminders keep opening in free-text mode.
  bool usePreset = existing == null ? true : existing.presetId != null;
  String selectedPresetId = existing?.presetId ?? reminderPresets.first.id;
  TimeOfDay time = existing != null
      ? TimeOfDay(
          hour: int.parse(existing.time.split(':')[0]),
          minute: int.parse(existing.time.split(':')[1]))
      : const TimeOfDay(hour: 9, minute: 0);
  Set<int> days = (existing?.days.isNotEmpty ?? false)
      ? existing!.days.toSet()
      : {0, 1, 2, 3, 4, 5, 6};
  bool enabled = existing?.enabled ?? true;
  bool advanceEnabled = existing?.advanceNotice.enabled ?? false;
  int advanceMinutes = existing?.advanceNotice.minutesBefore ?? 5;
  String? titleError;

  final dayKeys = ['day_sun', 'day_mon', 'day_tue', 'day_wed', 'day_thu', 'day_fri', 'day_sat'];

  return showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          backgroundColor: const Color(0xFF12121E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            existing == null ? app.t('modal_add_title') : app.t('modal_edit_title'),
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.t('title_label'), style: const TextStyle(color: Color(0xFF93A4C9), fontSize: 13)),
                const SizedBox(height: 4),
                // Guaranteed-voice vs free-text switch. Preset titles have
                // pre-recorded audio bundled with the app, so they always
                // speak — even on a device with no system TTS engine at
                // all. Free text is more flexible but needs that engine
                // to actually be heard.
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: usePreset ? palette.accent : Colors.transparent,
                            foregroundColor: usePreset ? Colors.black : Colors.white70,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => setState(() => usePreset = true),
                          child: const Text('قائمة جاهزة (صوت مضمون)', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: !usePreset ? palette.accent : Colors.transparent,
                            foregroundColor: !usePreset ? Colors.black : Colors.white70,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => setState(() => usePreset = false),
                          child: const Text('نص حر (يحتاج محرك النظام)', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (usePreset)
                  DropdownButtonFormField<String>(
                    value: selectedPresetId,
                    dropdownColor: const Color(0xFF12121E),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0x33FFFFFF))),
                    ),
                    items: reminderPresets
                        .map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.label(app.settings.language)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => selectedPresetId = v ?? selectedPresetId),
                  )
                else
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: app.t('title_placeholder'),
                      hintStyle: const TextStyle(color: Color(0xFF6B6B7A)),
                      errorText: titleError,
                      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0x33FFFFFF))),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: palette.accent)),
                    ),
                  ),
                const SizedBox(height: 14),
                Text(app.t('time_label'), style: const TextStyle(color: Color(0xFF93A4C9), fontSize: 13)),
                const SizedBox(height: 4),
                // A plain +/- stepper instead of Flutter's built-in
                // showTimePicker. The default Material time picker's dial
                // is touch/drag-only — it doesn't have a defined D-pad
                // focus order, so a TV remote can get stuck inside it
                // with no way to confirm or back out. Every control here
                // is a single focusable button, which the remote can
                // always move between and "select" reliably.
                _TimeStepperRow(
                  time: time,
                  use12h: app.settings.clock.hourFormat == 12,
                  accent: palette.accent,
                  onChanged: (t) => setState(() => time = t),
                ),
                const SizedBox(height: 14),
                Text(app.t('repeat_on'), style: const TextStyle(color: Color(0xFF93A4C9), fontSize: 13)),
                Wrap(
                  spacing: 6,
                  children: List.generate(7, (i) {
                    final selected = days.contains(i);
                    return FilterChip(
                      label: Text(app.t(dayKeys[i]), style: TextStyle(fontSize: 12, color: selected ? Colors.black : Colors.white70)),
                      selected: selected,
                      selectedColor: palette.accent,
                      backgroundColor: const Color(0x1AFFFFFF),
                      onSelected: (v) => setState(() => v ? days.add(i) : days.remove(i)),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: palette.accent,
                  title: Text(app.t('enable'), style: const TextStyle(color: Colors.white, fontSize: 14)),
                  value: enabled,
                  onChanged: (v) => setState(() => enabled = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: palette.accent,
                  title: Text(app.t('notify_before'), style: const TextStyle(color: Colors.white, fontSize: 14)),
                  value: advanceEnabled,
                  onChanged: (v) => setState(() => advanceEnabled = v),
                ),
                if (advanceEnabled)
                  Row(
                    children: [
                      SizedBox(
                        width: 70,
                        child: TextFormField(
                          initialValue: advanceMinutes.toString(),
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0x33FFFFFF))),
                          ),
                          onChanged: (v) {
                            final n = int.tryParse(v);
                            if (n != null) advanceMinutes = n.clamp(1, 180);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(app.t('minutes_before'), style: const TextStyle(color: Color(0xFF93A4C9))),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(app.t('cancel'), style: const TextStyle(color: Color(0xFF93A4C9))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: palette.accent, foregroundColor: Colors.black),
              onPressed: () async {
                if (!usePreset && titleCtrl.text.trim().isEmpty) {
                  setState(() => titleError = app.t('title_error'));
                  return;
                }
                final hh = time.hour.toString().padLeft(2, '0');
                final mm = time.minute.toString().padLeft(2, '0');
                final effectiveTitle = usePreset
                    ? findReminderPreset(selectedPresetId)!.label(app.settings.language)
                    : titleCtrl.text.trim();
                final reminder = Reminder(
                  id: existing?.id ?? 'r${DateTime.now().millisecondsSinceEpoch}',
                  title: effectiveTitle,
                  time: '$hh:$mm',
                  days: days.toList(),
                  enabled: enabled,
                  advanceNotice: AdvanceNotice(enabled: advanceEnabled, minutesBefore: advanceMinutes),
                  presetId: usePreset ? selectedPresetId : null,
                );
                if (existing == null) {
                  await app.addReminder(reminder);
                } else {
                  await app.updateReminder(reminder);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(app.t('save')),
            ),
          ],
        );
      });
    },
  );
}

/// A remote-friendly replacement for showTimePicker: every control is a
/// single, always-reachable button (+/- for hour, +/- for minute, and an
/// AM/PM toggle in 12h mode) instead of a touch-only dial, so a TV
/// remote's D-pad can always move between them and confirm with the
/// center/select button — no getting stuck with no way out.
class _TimeStepperRow extends StatelessWidget {
  final TimeOfDay time;
  final bool use12h;
  final Color accent;
  final ValueChanged<TimeOfDay> onChanged;

  const _TimeStepperRow({
    required this.time,
    required this.use12h,
    required this.accent,
    required this.onChanged,
  });

  void _changeHour(int delta) {
    final newHour = (time.hour + delta) % 24;
    onChanged(TimeOfDay(hour: newHour < 0 ? newHour + 24 : newHour, minute: time.minute));
  }

  void _changeMinute(int delta) {
    final newMinute = (time.minute + delta) % 60;
    onChanged(TimeOfDay(hour: time.hour, minute: newMinute < 0 ? newMinute + 60 : newMinute));
  }

  void _togglePeriod() => _changeHour(12);

  @override
  Widget build(BuildContext context) {
    final displayHour = use12h ? (time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod) : time.hour;
    final isPm = time.period == DayPeriod.pm;

    Widget stepper({required int value, required VoidCallback onInc, required VoidCallback onDec}) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up),
            color: Colors.white70,
            onPressed: onInc,
          ),
          Container(
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value.toString().padLeft(2, '0'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            color: Colors.white70,
            onPressed: onDec,
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        stepper(value: displayHour, onInc: () => _changeHour(1), onDec: () => _changeHour(-1)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Text(':', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        stepper(value: time.minute, onInc: () => _changeMinute(1), onDec: () => _changeMinute(-1)),
        if (use12h) ...[
          const SizedBox(width: 14),
          OutlinedButton(
            onPressed: _togglePeriod,
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              side: BorderSide(color: accent),
            ),
            child: Text(isPm ? 'PM' : 'AM'),
          ),
        ],
      ],
    );
  }
}
