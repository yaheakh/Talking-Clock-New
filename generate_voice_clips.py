#!/usr/bin/env python3
"""
Generates every short audio clip the Talking Clock app needs for its
"local recorded voice" mode — no manual recording required.

WHAT THIS DOES
  - Uses edge-tts (Microsoft's free, no-API-key text-to-speech service)
    to synthesize each word/phrase in the vocabulary below.
  - Re-encodes every clip with ffmpeg to mono Opus-in-OGG at a very low
    bitrate, trimmed of silence — perfect for short spoken words, and
    tiny in size (the whole set for both languages is normally well
    under 300 KB total).
  - Writes everything directly into assets/audio/en/ and assets/audio/ar/
    with the exact filenames the Flutter code (lib/local_voice.dart)
    expects, so you can drop the resulting `assets` folder straight into
    the project root and rebuild.

REQUIREMENTS (run this on your own computer — needs internet access)
    pip install edge-tts
    # ffmpeg must be installed and on your PATH:
    #   Windows:  https://ffmpeg.org/download.html  (or `choco install ffmpeg`)
    #   macOS:    brew install ffmpeg
    #   Linux:    sudo apt install ffmpeg

USAGE
    python3 generate_voice_clips.py

    Then copy the generated "assets" folder into your Talking-Clock
    project root (next to lib/, pubspec.yaml, etc.), overwriting nothing
    else, and run `flutter pub get` before building.

You can swap VOICE_EN / VOICE_AR below for any other edge-tts voice name
(run `edge-tts --list-voices` to see all available voices/languages).
"""

import asyncio
import os
import shutil
import subprocess
import sys

try:
    import edge_tts
except ImportError:
    sys.exit("Missing dependency. Run:  pip install edge-tts")

if shutil.which("ffmpeg") is None:
    sys.exit("ffmpeg not found on PATH. Install it first (see script header).")

OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "assets", "audio")

VOICE_EN = "en-US-GuyNeural"       # clear, natural US English voice
VOICE_AR = "ar-SA-HamedNeural"     # clear, natural Arabic (Saudi) voice

# id -> spoken text. These ids MUST match the ones referenced in
# lib/local_voice.dart exactly.
EN_WORDS = {
    "zero": "zero", "one": "one", "two": "two", "three": "three", "four": "four",
    "five": "five", "six": "six", "seven": "seven", "eight": "eight", "nine": "nine",
    "ten": "ten", "eleven": "eleven", "twelve": "twelve", "thirteen": "thirteen",
    "fourteen": "fourteen", "fifteen": "fifteen", "sixteen": "sixteen",
    "seventeen": "seventeen", "eighteen": "eighteen", "nineteen": "nineteen",
    "twenty": "twenty", "thirty": "thirty", "forty": "forty", "fifty": "fifty",
    "oh": "oh", "oclock": "o'clock", "am": "A M", "pm": "P M",
    "the_time_is": "The time is",
    # Connector words for the "<preset> in <N> minute(s)" advance notice.
    "in": "in", "minute": "minute", "minutes": "minutes",
}

AR_WORDS = {
    "d0": "صفر", "d1": "واحد", "d2": "اثنان", "d3": "ثلاثة", "d4": "أربعة",
    "d5": "خمسة", "d6": "ستة", "d7": "سبعة", "d8": "ثمانية", "d9": "تسعة",
    "alsaa": "الساعة الآن", "wa": "و", "sabahan": "صباحاً", "masaan": "مساءً",
    # Connector words for the Arabic advance notice.
    "qabl": "بعد", "daqiqa": "دقيقة",
}

# Fixed reminder titles with guaranteed audio (see lib/reminder_presets.dart
# — these ids MUST match exactly). Unlike the numbers above, these are
# recorded as single complete phrases rather than built word-by-word.
PRESET_EN = {
    "preset_medicine": "Time for your medicine",
    "preset_prayer": "Time for prayer",
    "preset_meeting": "Time for your meeting",
    "preset_wakeup": "Time to wake up",
    "preset_doctor": "Time for your doctor appointment",
    "preset_breakfast": "Time for breakfast",
    "preset_lunch": "Time for lunch",
    "preset_dinner": "Time for dinner",
    "preset_exercise": "Time to exercise",
    "preset_coffee": "Time for a coffee break",
    "preset_rest": "Time to rest",
    "preset_sleep": "Time to sleep",
    "preset_call": "Don't forget your important call",
    "preset_water": "Don't forget to drink water",
}

PRESET_AR = {
    "preset_medicine": "حان موعد الدواء",
    "preset_prayer": "حان وقت الصلاة",
    "preset_meeting": "حان موعد الاجتماع",
    "preset_wakeup": "حان وقت الاستيقاظ",
    "preset_doctor": "حان موعد الطبيب",
    "preset_breakfast": "حان وقت الفطور",
    "preset_lunch": "حان وقت الغداء",
    "preset_dinner": "حان وقت العشاء",
    "preset_exercise": "حان وقت التمرين",
    "preset_coffee": "حان وقت استراحة القهوة",
    "preset_rest": "حان وقت الراحة",
    "preset_sleep": "حان وقت النوم",
    "preset_call": "لا تنسَ الاتصال المهم",
    "preset_water": "لا تنسَ شرب الماء",
}

# Merge presets into the same per-language word maps so they're generated
# (and compressed) by the same loop as everything else.
EN_WORDS.update(PRESET_EN)
AR_WORDS.update(PRESET_AR)


async def synth(text: str, voice: str, raw_path: str):
    communicate = edge_tts.Communicate(text, voice)
    await communicate.save(raw_path)


def compress(raw_path: str, final_path: str):
    # Mono, 24kHz, 48kbps MP3: tiny files that still sound clear for short
    # spoken words, and MP3 keeps this consistent with the web-based
    # generator (voice_generator.html), which can only produce MP3 in-browser.
    # `silenceremove` trims any leading/trailing silence edge-tts adds,
    # which keeps clip playback snappy.
    subprocess.run(
        [
            "ffmpeg", "-y", "-i", raw_path,
            "-af", "silenceremove=start_periods=1:start_threshold=-45dB:"
                   "stop_periods=1:stop_threshold=-45dB:stop_duration=0.3",
            "-ac", "1", "-ar", "24000", "-c:a", "libmp3lame", "-b:a", "48k",
            final_path,
        ],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


async def build_set(lang_dir: str, words: dict, voice: str):
    os.makedirs(lang_dir, exist_ok=True)
    for clip_id, text in words.items():
        raw_path = os.path.join(lang_dir, f"_raw_{clip_id}.mp3")
        final_path = os.path.join(lang_dir, f"{clip_id}.mp3")
        print(f"  {clip_id:15s} -> \"{text}\"")
        await synth(text, voice, raw_path)
        compress(raw_path, final_path)
        os.remove(raw_path)


async def main():
    print("Generating English clips...")
    await build_set(os.path.join(OUT_DIR, "en"), EN_WORDS, VOICE_EN)
    print("Generating Arabic clips...")
    await build_set(os.path.join(OUT_DIR, "ar"), AR_WORDS, VOICE_AR)

    total_size = sum(
        os.path.getsize(os.path.join(root, f))
        for root, _, files in os.walk(OUT_DIR)
        for f in files
    )
    print(f"\nDone. Total size: {total_size / 1024:.1f} KB")
    print(f"Output folder: {OUT_DIR}")
    print("Copy the 'assets' folder into your Flutter project root, then run:")
    print("  flutter pub get")


if __name__ == "__main__":
    asyncio.run(main())
