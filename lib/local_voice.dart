import 'package:audioplayers/audioplayers.dart';

/// Speaks the clock's time announcement by stitching together short,
/// pre-recorded audio clips bundled as app assets, instead of asking the
/// operating system's text-to-speech engine to synthesize it.
///
/// Why this exists: some locked-down / OEM Android TV boxes (e.g. carrier
/// set-top boxes) ship with no TTS engine installed at all, so
/// AppState.speak() has nothing to talk to and stays silent no matter what.
/// A clock only ever needs to say numbers + "AM"/"PM" (or their Arabic
/// equivalents), so that small, fixed vocabulary can be recorded once and
/// played back — this works on every device, with or without a system TTS
/// engine.
///
/// This does NOT replace system TTS for custom reminder titles (arbitrary
/// user-typed text can't be pre-recorded) — those still go through
/// AppState.speak() and its existing fallback/diagnostics.
class LocalVoice {
  final AudioPlayer _player = AudioPlayer();
  bool _busy = false;

  static const _enOnes = [
    'zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten',
    'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen',
  ];
  static const _enTens = {20: 'twenty', 30: 'thirty', 40: 'forty', 50: 'fifty'};

  static const _arDigits = ['d0', 'd1', 'd2', 'd3', 'd4', 'd5', 'd6', 'd7', 'd8', 'd9'];

  List<String> _englishNumberClips(int n) {
    n = n.clamp(0, 59);
    if (n < 20) return [_enOnes[n]];
    final tens = (n ~/ 10) * 10;
    final ones = n % 10;
    final clips = [_enTens[tens]!];
    if (ones != 0) clips.add(_enOnes[ones]);
    return clips;
  }

  List<String> _arabicDigitClips(int n) {
    n = n.clamp(0, 59);
    return n.toString().split('').map((c) => _arDigits[int.parse(c)]).toList();
  }

  /// Digit-by-digit reading of any non-negative number, used for the
  /// "in N minutes" advance notice — unlike the time announcement this
  /// isn't limited to 0-59, and reading digit-by-digit sidesteps needing
  /// a much larger recorded vocabulary (twenty-one, thirty-seven, ...).
  List<String> _digitByDigitClips(String language, int n) {
    final digits = n.abs().toString().split('');
    if (language == 'ar') {
      return digits.map((c) => _arDigits[int.parse(c)]).toList();
    }
    return digits.map((c) => _enOnes[int.parse(c)]).toList();
  }

  Future<void> _playClip(String lang, String id) async {
    await _player.play(AssetSource('audio/$lang/$id.mp3'));
    // Wait for this clip to actually finish before starting the next one,
    // so the sequence sounds like one continuous sentence rather than
    // overlapping/garbled audio.
    await _player.onPlayerComplete.first.timeout(const Duration(seconds: 4));
  }

  /// Speaks [now] using pre-recorded clips in [language] ('ar' or 'en').
  /// Returns true if it played successfully. Returns false — without
  /// throwing — if a clip is missing or playback failed for any reason,
  /// so the caller can fall back to system TTS instead of staying silent.
  Future<bool> speakTime(DateTime now, String language) async {
    if (_busy) return true; // an announcement is already in progress
    _busy = true;
    try {
      int h12 = now.hour % 12;
      if (h12 == 0) h12 = 12;
      final isPm = now.hour >= 12;

      final clips = <String>[];
      if (language == 'ar') {
        clips.add('alsaa');
        clips.addAll(_arabicDigitClips(h12));
        if (now.minute != 0) {
          clips.add('wa');
          clips.addAll(_arabicDigitClips(now.minute));
        }
        clips.add(isPm ? 'masaan' : 'sabahan');
        for (final c in clips) {
          await _playClip('ar', c);
        }
      } else {
        clips.add('the_time_is');
        clips.addAll(_englishNumberClips(h12));
        if (now.minute == 0) {
          clips.add('oclock');
        } else {
          if (now.minute < 10) clips.add('oh');
          clips.addAll(_englishNumberClips(now.minute));
        }
        clips.add(isPm ? 'pm' : 'am');
        for (final c in clips) {
          await _playClip('en', c);
        }
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      _busy = false;
    }
  }

  void dispose() {
    _player.dispose();
  }

  /// Speaks a fixed preset reminder title (see reminder_presets.dart)
  /// using its pre-recorded clip. Returns false (without throwing) if the
  /// clip is missing, so the caller can fall back to system TTS.
  Future<bool> speakPreset(String presetId, String language) async {
    if (_busy) return true;
    _busy = true;
    try {
      await _playClip(language, 'preset_$presetId');
      return true;
    } catch (_) {
      return false;
    } finally {
      _busy = false;
    }
  }

  /// Speaks "<preset title> in <N> minutes" (or its Arabic equivalent) for
  /// a preset-based reminder's advance notice, entirely from pre-recorded
  /// clips. Returns false if anything is missing/fails, so the caller can
  /// fall back to system TTS instead.
  Future<bool> speakPresetAdvanceNotice(String presetId, int minutesBefore, String language) async {
    if (_busy) return true;
    _busy = true;
    try {
      final clips = <String>['preset_$presetId'];
      if (language == 'ar') {
        clips.add('qabl');
        clips.addAll(_digitByDigitClips('ar', minutesBefore));
        clips.add('daqiqa');
      } else {
        clips.add('in');
        clips.addAll(_digitByDigitClips('en', minutesBefore));
        clips.add(minutesBefore == 1 ? 'minute' : 'minutes');
      }
      for (final c in clips) {
        await _playClip(language, c);
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      _busy = false;
    }
  }
}
