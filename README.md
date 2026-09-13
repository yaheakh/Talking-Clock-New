# Talking Clock — Flutter (native rewrite)

A full native Flutter/Dart rewrite of the Talking Clock — same features
(custom reminders, periodic time announcements, Jordan holiday calendar,
Arabic/English with proper RTL, 4 color themes), completely separate
codebase from the Electron/web versions. Built to run on Android phones,
tablets, and Android TV from one APK.

## Structure

```
lib/
├── main.dart              entry point
├── app_state.dart         settings persistence + the reminder/announcement scheduler
├── models.dart             data models (Reminder, AppSettings, ...)
├── i18n.dart               English/Arabic translation table
├── jordan_holidays.dart    2026-2027 official Jordan holiday data
├── themes.dart             the 4 color palettes
├── clock_screen.dart       the full-screen clock UI
├── settings_screen.dart    the tabbed settings UI
└── reminder_dialog.dart    add/edit reminder dialog

android/                   standard Flutter Android embedding (v2)
.github/workflows/         builds the APK automatically on GitHub
```

## Building the APK — no local Flutter/Android Studio needed

1. Push this folder to a GitHub repository.
2. Go to the **Actions** tab → the **"Build Flutter APK"** workflow runs
   automatically on push (or trigger it manually with "Run workflow").
3. When it finishes, open the run → **Artifacts** →
   download **talking-clock-flutter-debug-apk**.
4. Copy `app-debug.apk` onto your Android device/TV and install it
   (allow "install from unknown sources" the first time).

The workflow installs Flutter itself via `subosito/flutter-action`, runs
`flutter pub get` then `flutter build apk --debug` — the exact same
commands you'd run locally, just executed on GitHub's servers instead of
your machine.

## If you do get Flutter installed locally later

```
flutter pub get
flutter run           # run on a connected device/emulator
flutter build apk     # build a release-shaped APK locally
```

## Honest notes on what I could and couldn't verify

I don't have a Flutter/Dart toolchain available in the environment I
wrote this in, so **I was not able to run `flutter analyze` or actually
compile this before handing it to you.** I checked every file carefully
by hand (brace/paren balance, matching imports, matching package APIs
against the versions pinned in `pubspec.yaml`), but a real build is the
first true test. If GitHub Actions reports an error, paste it back to me
and I'll fix it — first-build hiccups on a hand-written project this
size (version mismatches, a typo'd API) are common and normally quick
to resolve once I can see the actual error message.

## Feature notes

- **Reminders** — add/edit/delete, per-weekday recurrence, optional
  "notify N minutes before", a Test button that fires the exact same
  code path as a real trigger (notification + speech + on-screen pulse).
- **Time announcements** — speaks the time every N minutes (configurable),
  optional system notification too.
- **Jordan holidays** — mini week-strip with a dot on holiday dates,
  "today" status, and a "next holiday" countdown. Islamic-calendar dates
  (Eid al-Fitr, Eid al-Adha, etc.) are hand-entered per year in
  `lib/jordan_holidays.dart` — extend that list once official dates for
  a new year are announced.
- **Arabic** — real `Directionality`/RTL support (not CSS tricks like the
  web version needed) — the whole UI mirrors properly. The clock digits
  themselves are pinned to strict left-to-right in every language,
  matching what was asked for earlier.
- **Themes** — Aurora / Neon Cyan / Amber Night / Minimal Contrast,
  same palettes as the other versions.
- **Keep screen awake** — toggle in Others, using `wakelock_plus`.
- Both a normal Android app icon (phones/tablets) and an Android TV
  banner/Leanback launcher entry are included in the same APK.
