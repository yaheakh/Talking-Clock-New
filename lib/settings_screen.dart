import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'app_state.dart';
import 'models.dart';
import 'themes.dart';
import 'reminder_dialog.dart';
import 'jordan_holidays.dart';

class SettingsScreen extends StatefulWidget {
  final AppState app;
  const SettingsScreen({super.key, required this.app});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final palette = appPalettes[app.settings.clock.theme]!;
    final isAr = app.settings.language == 'ar';

    return Directionality(
      textDirection: isAr ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: AnimatedBuilder(
        animation: app,
        builder: (context, _) {
          return Scaffold(
            backgroundColor: const Color(0xFF0E0E18),
            appBar: AppBar(
              backgroundColor: const Color(0xFF0E0E18),
              elevation: 0,
              title: Text(app.t('settings')),
              bottom: TabBar(
                controller: _tabs,
                isScrollable: true,
                indicatorColor: palette.accent,
                labelColor: palette.accent,
                unselectedLabelColor: Colors.white54,
                tabs: [
                  Tab(text: app.t('tab_reminders')),
                  Tab(text: app.t('tab_time_reminder')),
                  Tab(text: app.t('tab_voice')),
                  Tab(text: app.t('tab_display')),
                  Tab(text: app.t('tab_others')),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabs,
              children: [
                _RemindersTab(app: app, palette: palette),
                _TimeReminderTab(app: app),
                _VoiceTab(app: app),
                _DisplayTab(app: app, palette: palette),
                _OthersTab(app: app),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(text.toUpperCase(),
            style: const TextStyle(color: Color(0xFF93A4C9), fontSize: 12, letterSpacing: 1.1)),
      );
}

class _RemindersTab extends StatelessWidget {
  final AppState app;
  final AppPalette palette;
  const _RemindersTab({required this.app, required this.palette});

  @override
  Widget build(BuildContext context) {
    final reminders = app.settings.reminders;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: reminders.isEmpty
                ? Center(child: Text(app.t('no_reminders_today'), style: const TextStyle(color: Colors.white54)))
                : ListView.separated(
                    itemCount: reminders.length,
                    separatorBuilder: (_, __) => const Divider(color: Color(0x1AFFFFFF)),
                    itemBuilder: (ctx, i) {
                      final r = reminders[i];
                      return ListTile(
                        title: Text(r.title, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(r.time, style: const TextStyle(color: Color(0xFF93A4C9))),
                        leading: Switch(
                          value: r.enabled,
                          activeColor: palette.accent,
                          onChanged: (v) => app.toggleReminder(r.id, v),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_active, color: Colors.white54, size: 20),
                              tooltip: app.t('test'),
                              onPressed: () => app.testFire(r),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white54, size: 20),
                              onPressed: () => showReminderDialog(context, app, existing: r),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                              onPressed: () => app.deleteReminder(r.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: palette.accent, foregroundColor: Colors.black),
              onPressed: () => showReminderDialog(context, app),
              child: Text(app.t('add_reminder_btn')),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeReminderTab extends StatelessWidget {
  final AppState app;
  const _TimeReminderTab({required this.app});

  @override
  Widget build(BuildContext context) {
    final tr = app.settings.timeReminder;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SwitchListTile(
          title: Text(app.t('enable'), style: const TextStyle(color: Colors.white)),
          value: tr.enabled,
          onChanged: (v) { tr.enabled = v; app.persist(); },
        ),
        const _SectionTitle('announce_interval'),
        Row(
          children: [
            SizedBox(
              width: 90,
              child: TextFormField(
                initialValue: tr.intervalMinutes.toString(),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onChanged: (v) {
                  final n = int.tryParse(v);
                  if (n != null) { tr.intervalMinutes = n.clamp(1, 1440); app.persist(); }
                },
              ),
            ),
            const SizedBox(width: 10),
            Text(app.t('minutes'), style: const TextStyle(color: Colors.white70)),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(app.t('interval_hint'), style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ),
        const _SectionTitle('actions'),
        SwitchListTile(
          title: Text(app.t('voice_announcement'), style: const TextStyle(color: Colors.white)),
          value: tr.voiceAnnouncement,
          onChanged: (v) { tr.voiceAnnouncement = v; app.persist(); },
        ),
        SwitchListTile(
          title: Text(app.t('system_notification'), style: const TextStyle(color: Colors.white)),
          value: tr.systemNotification,
          onChanged: (v) { tr.systemNotification = v; app.persist(); },
        ),
      ],
    );
  }
}

class _VoiceTab extends StatelessWidget {
  final AppState app;
  const _VoiceTab({required this.app});

  @override
  Widget build(BuildContext context) {
    final tts = app.settings.tts;
    final testCtrl = TextEditingController();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SwitchListTile(
          title: const Text('استخدم الصوت المسجّل محليًا لإعلان الوقت',
              style: TextStyle(color: Colors.white)),
          subtitle: const Text(
            'أضمن وأسرع، ويعمل حتى بدون محرك نطق في النظام — التذكيرات النصية '
            'المخصّصة تبقى تحتاج محرك نظام التشغيل.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          value: tts.useLocalVoice,
          onChanged: (v) { tts.useLocalVoice = v; app.persist(); },
        ),
        const SizedBox(height: 12),
        Text(app.t('rate'), style: const TextStyle(color: Color(0xFF93A4C9))),
        Slider(
          value: tts.rate, min: 0.1, max: 1.0,
          onChanged: (v) { tts.rate = v; app.persist(); },
        ),
        Text(app.t('pitch'), style: const TextStyle(color: Color(0xFF93A4C9))),
        Slider(
          value: tts.pitch, min: 0.5, max: 2.0,
          onChanged: (v) { tts.pitch = v; app.persist(); },
        ),
        Text(app.t('volume'), style: const TextStyle(color: Color(0xFF93A4C9))),
        Slider(
          value: tts.volume, min: 0.0, max: 1.0,
          onChanged: (v) { tts.volume = v; app.persist(); },
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: testCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(hintText: app.t('test_voice_placeholder'), hintStyle: const TextStyle(color: Colors.white38)),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => app.speak(testCtrl.text.isEmpty ? 'This is a test' : testCtrl.text),
              child: Text(app.t('test_voice')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.health_and_safety_outlined, color: Colors.white70),
          label: const Text('تشخيص الصوت / Diagnose sound', style: TextStyle(color: Colors.white70)),
          onPressed: () async {
            final result = await app.diagnoseTts();
            if (!context.mounted) return;
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF17122A),
                title: Text(
                  result.engineFound ? 'تم العثور على محرك نطق' : 'لا يوجد محرك نطق على الجهاز',
                  style: const TextStyle(color: Colors.white),
                ),
                content: SingleChildScrollView(
                  child: Text(
                    [
                      if (result.defaultEngine != null) 'المحرك الافتراضي: ${result.defaultEngine}',
                      if (result.engines.isNotEmpty) 'كل المحركات المتاحة: ${result.engines.join(', ')}',
                      if (!result.engineFound)
                        'لم يتم العثور على أي محرك تحويل نص إلى كلام على هذا الجهاز.\n'
                        'هذا يفسّر انعدام الصوت — المشكلة في نظام التلفاز نفسه، وليست في هذا التطبيق.\n'
                        'جرّب تثبيت "Google Text-to-Speech" من متجر التطبيقات إن كان متاحًا، '
                        'أو تحقّق من إعدادات "تحويل النص إلى كلام" في التلفاز مباشرة.',
                      if (result.lastError != null) '\nتفاصيل تقنية: ${result.lastError}',
                    ].join('\n\n'),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسنًا')),
                ],
              ),
            );
          },
        ),
        if (!app.ttsEngineAvailable) ...[
          const SizedBox(height: 8),
          Text(
            app.lastTtsError == null
                ? '⚠ لم يصدر الجهاز أي صوت بعد — اضغط "تشخيص الصوت" أعلاه.'
                : '⚠ فشل النطق: ${app.lastTtsError}',
            style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _DisplayTab extends StatelessWidget {
  final AppState app;
  final AppPalette palette;
  const _DisplayTab({required this.app, required this.palette});

  @override
  Widget build(BuildContext context) {
    final clock = app.settings.clock;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _SectionTitle('language'),
        RadioListTile<String>(
          value: 'en',
          groupValue: app.settings.language,
          activeColor: palette.accent,
          title: Text(app.t('lang_en'), style: const TextStyle(color: Colors.white)),
          onChanged: (v) { app.settings.language = v!; app.persist(); },
        ),
        RadioListTile<String>(
          value: 'ar',
          groupValue: app.settings.language,
          activeColor: palette.accent,
          title: Text(app.t('lang_ar'), style: const TextStyle(color: Colors.white)),
          onChanged: (v) { app.settings.language = v!; app.persist(); },
        ),
        const _SectionTitle('color_theme'),
        Wrap(
          spacing: 14,
          children: appPalettes.values.map((p) {
            final selected = clock.theme == p.id;
            final labelKey = 'theme_${p.id}';
            return Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                focusColor: p.accent.withOpacity(0.35),
                onTap: () { clock.theme = p.id; app.persist(); },
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [p.accent, p.accent2]),
                          border: selected ? Border.all(color: Colors.white, width: 2) : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(app.t(labelKey), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const _SectionTitle('display'),
        SwitchListTile(
          title: Text(app.t('display_seconds'), style: const TextStyle(color: Colors.white)),
          value: clock.showSeconds,
          activeColor: palette.accent,
          onChanged: (v) { clock.showSeconds = v; app.persist(); },
        ),
        SwitchListTile(
          title: Text(app.t('display_date'), style: const TextStyle(color: Colors.white)),
          value: clock.showDate,
          activeColor: palette.accent,
          onChanged: (v) { clock.showDate = v; app.persist(); },
        ),
        SwitchListTile(
          title: Text(app.t('display_reminders'), style: const TextStyle(color: Colors.white)),
          value: clock.showReminders,
          activeColor: palette.accent,
          onChanged: (v) { clock.showReminders = v; app.persist(); },
        ),
        SwitchListTile(
          title: Text(
            app.settings.language == 'ar' ? 'عرض ساعات العالم' : 'Show world clocks',
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            app.settings.language == 'ar'
                ? 'نيويورك، لندن، طوكيو — مع توقيتها الصيفي/الشتوي تلقائيًا'
                : 'New York, London, Tokyo — with automatic DST',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          value: clock.showWorldClocks,
          activeColor: palette.accent,
          onChanged: (v) { clock.showWorldClocks = v; app.persist(); },
        ),
        SwitchListTile(
          title: Text(app.t('display_holidays'), style: const TextStyle(color: Colors.white)),
          value: clock.showHolidays,
          activeColor: palette.accent,
          onChanged: (v) { clock.showHolidays = v; app.persist(); },
        ),
        if (clock.showHolidays) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 16, bottom: 8),
            child: DropdownButtonFormField<String>(
              value: clock.holidayCountry,
              dropdownColor: const Color(0xFF12121E),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: app.settings.language == 'ar' ? 'دولة العطل' : 'Holiday country',
                labelStyle: const TextStyle(color: Color(0xFF93A4C9)),
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0x33FFFFFF))),
              ),
              items: holidayCountryNamesAr.keys
                  .map((code) => DropdownMenuItem(
                        value: code,
                        child: Text(app.settings.language == 'ar'
                            ? holidayCountryNamesAr[code]!
                            : holidayCountryNamesEn[code]!),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                clock.holidayCountry = v;
                app.persist();
              },
            ),
          ),
        ],
        const _SectionTitle('text_size'),
        ...['normal', 'large', 'xlarge'].map((size) => RadioListTile<String>(
              value: size,
              groupValue: clock.textSize,
              activeColor: palette.accent,
              title: Text(app.t('size_$size'), style: const TextStyle(color: Colors.white)),
              onChanged: (v) { clock.textSize = v!; app.persist(); },
            )),
        const _SectionTitle('hour_format'),
        RadioListTile<int>(
          value: 12,
          groupValue: clock.hourFormat,
          activeColor: palette.accent,
          title: Text(app.t('hour_12'), style: const TextStyle(color: Colors.white)),
          onChanged: (v) { clock.hourFormat = v!; app.persist(); },
        ),
        RadioListTile<int>(
          value: 24,
          groupValue: clock.hourFormat,
          activeColor: palette.accent,
          title: Text(app.t('hour_24'), style: const TextStyle(color: Colors.white)),
          onChanged: (v) { clock.hourFormat = v!; app.persist(); },
        ),
      ],
    );
  }
}

class _OthersTab extends StatelessWidget {
  final AppState app;
  const _OthersTab({required this.app});

  @override
  Widget build(BuildContext context) {
    final others = app.settings.others;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SwitchListTile(
          title: Text(app.t('mute_all'), style: const TextStyle(color: Colors.white)),
          value: others.mute,
          onChanged: (v) { others.mute = v; app.persist(); },
        ),
        SwitchListTile(
          title: Text(app.t('keep_awake'), style: const TextStyle(color: Colors.white)),
          value: others.keepAwake,
          onChanged: (v) => app.setKeepAwake(v),
        ),
        SwitchListTile(
          title: const Text('الصوت في الخلفية (تجريبي)', style: TextStyle(color: Colors.white)),
          subtitle: const Text(
            'يبقي الساعة تنطق حتى وأنت خارج التطبيق تمامًا، عبر خدمة خلفية '
            'حقيقية بإشعار دائم صغير. ميزة تجريبية — قد لا تعمل بثبات على '
            'كل الأجهزة. إن تعطّل شيء، أوقفها من هنا وأعد فتح التطبيق.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          value: others.backgroundVoice,
          onChanged: (v) => app.setBackgroundVoiceEnabled(v),
        ),
        if (app.initWarning != null && app.initWarning!.contains('background service'))
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 16, left: 16),
            child: Text(
              'تعذّر تشغيل الخدمة على هذا الجهاز: ${app.initWarning}',
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
            ),
          ),
        const Divider(height: 32, color: Color(0x33FFFFFF)),
        OutlinedButton.icon(
          icon: const Icon(Icons.restart_alt, color: Colors.orangeAccent),
          label: const Text(
            'إعادة ضبط كل الإعدادات (حل أخير عند وجود عطل)',
            style: TextStyle(color: Colors.orangeAccent),
          ),
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF17122A),
                title: const Text('إعادة ضبط الإعدادات؟', style: TextStyle(color: Colors.white)),
                content: const Text(
                  'سيتم حذف كل التذكيرات والإعدادات المخصّصة والعودة للوضع الافتراضي. '
                  'استخدم هذا فقط إن كان التطبيق يتصرف بشكل غير طبيعي بعد تعديل الإعدادات.',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إعادة الضبط')),
                ],
              ),
            );
            if (confirmed == true) {
              await app.resetToDefaults();
            }
          },
        ),
      ],
    );
  }
}
