import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app_state.dart';
import 'clock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Loads locale data (month/day names, etc.) for both English and
  // Arabic so DateFormat(..., 'ar') doesn't throw at runtime — by
  // default intl only ships 'en_US' data until this is called.
  await initializeDateFormatting();
  await initializeDateFormatting('ar');

  // Replace Flutter's red "error" screen with a plain black one in
  // release builds. A widget-build error should never look like a
  // frozen/black screen with no way out — this at least keeps the rest
  // of the app interactive instead of one broken widget wedging
  // everything.
  ErrorWidget.builder = (details) {
    if (kDebugMode) return ErrorWidget(details.exception);
    return const ColoredBox(color: Color(0xFF0A0612));
  };

  runApp(const TalkingClockApp());
}

class TalkingClockApp extends StatefulWidget {
  const TalkingClockApp({super.key});

  @override
  State<TalkingClockApp> createState() => _TalkingClockAppState();
}

class _TalkingClockAppState extends State<TalkingClockApp> {
  final AppState _app = AppState();
  Object? _fatalError;

  @override
  void initState() {
    super.initState();
    _startInit();
  }

  void _startInit() {
    _fatalError = null;
    // If init() itself throws (rather than just recording a warning —
    // every step inside it already catches its own errors, but this is
    // the last line of defense), show a recovery screen with a reset
    // option instead of leaving the app stuck behind the loading spinner
    // forever, which is what an *uncaught* init failure looked like
    // before this was added.
    _app.init().then((_) {
      if (mounted) setState(() {});
    }).catchError((e) {
      if (mounted) setState(() => _fatalError = e);
    });
  }

  @override
  void dispose() {
    _app.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Talking Clock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: _fatalError != null
          ? _RecoveryScreen(
              error: _fatalError!,
              onReset: () async {
                await _app.resetToDefaults();
                setState(() => _fatalError = null);
                _startInit();
              },
            )
          : (_app.loaded
              ? ClockScreen(app: _app)
              : const Scaffold(
                  backgroundColor: Color(0xFF0A0612),
                  body: Center(child: CircularProgressIndicator()),
                )),
    );
  }
}

/// Shown only if startup fails in a way none of the per-step error
/// handling inside AppState.init() could recover from on its own. Gives
/// the user a way out (reset to default settings) instead of a
/// permanently stuck black screen after an app update or a corrupted
/// settings edit.
class _RecoveryScreen extends StatelessWidget {
  final Object error;
  final VoidCallback onReset;
  const _RecoveryScreen({required this.error, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0612),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.orangeAccent, size: 48),
              const SizedBox(height: 16),
              const Text(
                'حدث خطأ أثناء تشغيل التطبيق',
                style: TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onReset,
                child: const Text('إعادة ضبط الإعدادات وإعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
