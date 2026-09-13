import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'app_state.dart';
import 'models.dart';
import 'themes.dart';
import 'jordan_holidays.dart';
import 'reminder_dialog.dart';
import 'settings_screen.dart';
import 'native_window.dart';
import 'world_clocks.dart';

class ClockScreen extends StatefulWidget {
  final AppState app;
  const ClockScreen({super.key, required this.app});

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> with SingleTickerProviderStateMixin {
  DateTime _now = DateTime.now();
  StreamSubscription? _tickSub;
  StreamSubscription? _fireSub;
  String? _bannerText;
  Timer? _bannerTimer;
  final Set<String> _firingIds = {};

  @override
  void initState() {
    super.initState();
    _tickSub = widget.app.tickStream.listen((_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _fireSub = widget.app.fireStream.listen(_onFire);
  }

  void _onFire(FireEvent e) {
    if (!mounted) return;
    setState(() => _firingIds.add(e.id));
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _firingIds.remove(e.id));
    });
    if (!e.isAdvanceNotice) {
      setState(() => _bannerText = e.title);
      _bannerTimer?.cancel();
      _bannerTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => _bannerText = null);
      });
    }
  }

  @override
  void dispose() {
    _tickSub?.cancel();
    _fireSub?.cancel();
    _bannerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final s = app.settings;
    final palette = appPalettes[s.clock.theme]!;
    final isAr = s.language == 'ar';

    return Directionality(
      textDirection: isAr ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: palette.background,
        body: Stack(
          children: [
            if (palette.aurora) _AuroraBackground(palette: palette),
            SafeArea(
              child: Row(
                children: [
                  if (s.clock.showReminders)
                    Expanded(
                      flex: 5,
                      child: _RemindersPanel(app: app, palette: palette, now: _now, firingIds: _firingIds),
                    ),
                  Expanded(
                    flex: 12,
                    child: _ClockColumn(app: app, palette: palette, now: _now),
                  ),
                  if (s.clock.showHolidays)
                    Expanded(
                      flex: 5,
                      child: _HolidayPanel(app: app, palette: palette, now: _now),
                    ),
                ],
              ),
            ),
            Positioned(
              top: 18,
              right: isAr ? null : 20,
              left: isAr ? 20 : null,
              child: Row(
                children: [
                  _CornerButton(
                    icon: Icons.remove_circle_outline,
                    onTap: () => NativeWindow.minimize(),
                  ),
                  const SizedBox(width: 10),
                  _CornerButton(
                    icon: Icons.settings,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => SettingsScreen(app: app)),
                    ),
                  ),
                ],
              ),
            ),
            if (_bannerText != null)
              _AttentionBanner(
                text: _bannerText!,
                palette: palette,
                onDismiss: () => setState(() => _bannerText = null),
              ),
          ],
        ),
      ),
    );
  }
}

class _CornerButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CornerButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.06),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
      ),
    );
  }
}

class _AuroraBackground extends StatelessWidget {
  final AppPalette palette;
  const _AuroraBackground({required this.palette});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: _blob(palette.accent.withOpacity(0.35), 280),
          ),
          Positioned(
            bottom: -100,
            right: -80,
            child: _blob(palette.accent2.withOpacity(0.30), 320),
          ),
        ],
      ),
    );
  }

  Widget _blob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    );
  }
}

class _ClockColumn extends StatelessWidget {
  final AppState app;
  final AppPalette palette;
  final DateTime now;
  const _ClockColumn({required this.app, required this.palette, required this.now});

  double get _fontSize {
    switch (app.settings.clock.textSize) {
      case 'normal':
        return 64;
      case 'xlarge':
        return 128;
      default:
        return 96;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = app.settings;
    int hour = now.hour;
    String suffix = '';
    if (s.clock.hourFormat == 12) {
      suffix = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
    }
    final hh = hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (s.clock.showWorldClocks) ...[
            _WorldClockBar(palette: palette, hourFormat: s.clock.hourFormat, isAr: s.language == 'ar'),
            const SizedBox(height: 22),
          ],
          Directionality(
            textDirection: ui.TextDirection.ltr, // clock digits always LTR
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w400),
                children: [
                  TextSpan(text: hh, style: TextStyle(fontSize: _fontSize, color: palette.textMain)),
                  TextSpan(text: ':', style: TextStyle(fontSize: _fontSize * 0.86, color: palette.textSub.withOpacity(0.55))),
                  TextSpan(text: mm, style: TextStyle(fontSize: _fontSize * 0.76, color: palette.accent2)),
                  if (s.clock.showSeconds) ...[
                    TextSpan(text: ':', style: TextStyle(fontSize: _fontSize * 0.64, color: palette.textSub.withOpacity(0.55))),
                    TextSpan(text: ss, style: TextStyle(fontSize: _fontSize * 0.56, color: palette.accent)),
                  ],
                  if (suffix.isNotEmpty)
                    TextSpan(
                      text: ' $suffix',
                      style: TextStyle(fontSize: _fontSize * 0.32, color: suffix == 'AM' ? palette.accent2 : palette.accent),
                    ),
                ],
              ),
            ),
          ),
          if (s.clock.showDate) ...[
            const SizedBox(height: 18),
            Container(width: 220, height: 2, color: palette.accent.withOpacity(0.5)),
            const SizedBox(height: 14),
            Text(
              DateFormat.yMMMMEEEEd(s.language == 'ar' ? 'ar' : 'en_US').format(now),
              style: TextStyle(color: palette.textSub, fontSize: 18),
            ),
          ],
        ],
      ),
    );
  }
}

class _WorldClockBar extends StatelessWidget {
  final AppPalette palette;
  final int hourFormat;
  final bool isAr;
  const _WorldClockBar({required this.palette, required this.hourFormat, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final entries = worldCities.map(worldCityNow).whereType<WorldCityTime>().toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final entry in entries) ...[
          _WorldCityCard(entry: entry, palette: palette, hourFormat: hourFormat, isAr: isAr),
          if (entry != entries.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _WorldCityCard extends StatelessWidget {
  final WorldCityTime entry;
  final AppPalette palette;
  final int hourFormat;
  final bool isAr;
  const _WorldCityCard({required this.entry, required this.palette, required this.hourFormat, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final t = entry.time;
    int hour = t.hour;
    String suffix = '';
    if (hourFormat == 12) {
      suffix = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
    }
    final hh = hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');

    // Some countries (e.g. Japan) never observe daylight saving at all —
    // showing "Standard" for those would wrongly imply the country
    // switches between two times. isDst tells us definitively either way
    // (straight from the real tz database), so the label only ever
    // claims what's actually true for that place.
    final badgeText = entry.isDst
        ? (isAr ? 'صيفي' : 'DST')
        : (isAr ? 'قياسي' : 'Standard');
    final badgeColor = entry.isDst ? palette.accent : palette.accent2;

    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: palette.panelBg,
        border: Border.all(color: palette.panelBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isAr ? entry.city.nameAr : entry.city.nameEn,
            style: TextStyle(color: palette.textSub, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Directionality(
            textDirection: ui.TextDirection.ltr,
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w500),
                children: [
                  TextSpan(text: '$hh:$mm', style: TextStyle(fontSize: 18, color: palette.textMain)),
                  if (suffix.isNotEmpty)
                    TextSpan(text: ' $suffix', style: TextStyle(fontSize: 10, color: palette.textSub)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(badgeText, style: TextStyle(color: badgeColor, fontSize: 10)),
          ),
        ],
      ),
    );
  }
}

class _RemindersPanel extends StatelessWidget {
  final AppState app;
  final AppPalette palette;
  final DateTime now;
  final Set<String> firingIds;
  const _RemindersPanel({required this.app, required this.palette, required this.now, required this.firingIds});

  @override
  Widget build(BuildContext context) {
    final s = app.settings;
    final dow = now.weekday % 7;
    final nowHHMM = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final todays = s.reminders.where((r) {
      return r.days.isEmpty || r.days.length == 7 || r.days.contains(dow);
    }).toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.panelBg,
        border: Border.all(color: palette.panelBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: Text(app.t('reminders_title'),
                    style: TextStyle(color: palette.textMain, fontWeight: FontWeight.w600)),
              ),
              InkWell(
                onTap: () => showReminderDialog(context, app),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(color: palette.accent, shape: BoxShape.circle),
                  child: const Icon(Icons.add, size: 16, color: Colors.black),
                ),
              ),
            ],
          ),
          const Divider(color: Color(0x22FFFFFF)),
          Expanded(
            child: todays.isEmpty
                ? Center(
                    child: Text(app.t('no_reminders_today'),
                        style: TextStyle(color: palette.textSub, fontStyle: FontStyle.italic)))
                : ListView.builder(
                    itemCount: todays.length,
                    itemBuilder: (ctx, i) {
                      final r = todays[i];
                      final isDone = r.time.compareTo(nowHHMM) < 0;
                      final isFiring = firingIds.contains(r.id);
                      return ListTile(
                        dense: true,
                        onTap: () => showReminderDialog(context, app, existing: r),
                        title: Row(
                          children: [
                            Text(r.time,
                                style: TextStyle(
                                    color: isFiring ? palette.accent : (isDone ? palette.textSub : palette.accent),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                r.title,
                                style: TextStyle(
                                  color: isDone ? palette.textSub : palette.textMain,
                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _HolidayPanel extends StatelessWidget {
  final AppState app;
  final AppPalette palette;
  final DateTime now;
  const _HolidayPanel({required this.app, required this.palette, required this.now});

  @override
  Widget build(BuildContext context) {
    final isAr = app.settings.language == 'ar';
    final country = app.settings.clock.holidayCountry;
    final todayHoliday = holidayOn(now, country);
    final next = nextHolidayAfter(now, country);

    String nextText = app.t('no_upcoming_holiday');
    if (next != null) {
      final days = next.date.difference(DateTime(now.year, now.month, now.day)).inDays;
      final name = isAr ? next.nameAr : next.nameEn;
      final when = days == 0
          ? app.t('today_word')
          : days == 1
              ? app.t('tomorrow_word')
              : app.t('in_days').replaceAll('{n}', '$days');
      final dateStr = DateFormat.yMMMd(isAr ? 'ar' : 'en_US').format(next.date);
      nextText = '$name — $dateStr ($when)';
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.panelBg,
        border: Border.all(color: palette.panelBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event, size: 16, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  DateFormat.yMMMM(isAr ? 'ar' : 'en_US').format(now),
                  style: TextStyle(color: palette.textMain, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const Divider(color: Color(0x22FFFFFF)),
          _WeekStrip(now: now, palette: palette, isAr: isAr, country: country),
          const SizedBox(height: 16),
          Text(app.t('today_label'), style: TextStyle(color: palette.textSub, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            todayHoliday != null
                ? (isAr ? todayHoliday.nameAr : todayHoliday.nameEn)
                : app.t('regular_day'),
            style: TextStyle(
              color: todayHoliday != null ? palette.accent : palette.textMain,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(app.t('next_holiday'), style: TextStyle(color: palette.textSub, fontSize: 11)),
          const SizedBox(height: 4),
          Text(nextText, style: TextStyle(color: palette.textMain, fontSize: 13), softWrap: true),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  final DateTime now;
  final AppPalette palette;
  final bool isAr;
  final String country;
  const _WeekStrip({required this.now, required this.palette, required this.isAr, required this.country});

  @override
  Widget build(BuildContext context) {
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final d = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + i);
        final isToday = d.year == now.year && d.month == now.month && d.day == now.day;
        final hasHoliday = holidayOn(d, country) != null;
        // Wrapped in Expanded + FittedBox so this row can never overflow
        // horizontally, no matter how narrow the panel gets on
        // lower-resolution TV screens — instead of the classic
        // black/yellow "overflow" hazard stripes, the whole day cell
        // (letter, circle, dot) just scales down together to fit.
        return Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(DateFormat.E(isAr ? 'ar' : 'en_US').format(d).substring(0, 1), style: TextStyle(color: palette.textSub, fontSize: 10)),
                const SizedBox(height: 4),
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isToday ? palette.accent : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Text('${d.day}',
                      style: TextStyle(
                        color: isToday ? Colors.black : palette.textMain,
                        fontSize: 12,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      )),
                ),
                if (hasHoliday)
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.8), shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _AttentionBanner extends StatelessWidget {
  final String text;
  final AppPalette palette;
  final VoidCallback onDismiss;
  const _AttentionBanner({required this.text, required this.palette, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onDismiss,
        child: Container(
          color: Colors.black.withOpacity(0.55),
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: const Color(0xFF14101E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: palette.accent, width: 2),
              boxShadow: [BoxShadow(color: palette.accent.withOpacity(0.5), blurRadius: 40)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🔔', style: TextStyle(fontSize: 48, shadows: [Shadow(color: palette.accent, blurRadius: 20)])),
                const SizedBox(height: 16),
                Text(text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
