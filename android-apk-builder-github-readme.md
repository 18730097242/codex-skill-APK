# Android APK Builder Skill

`android-apk-builder` is a Codex skill for creating, packaging, signing, and verifying lightweight Android APKs, especially when a full Android Studio or Gradle setup is not available.

It is designed for small Android utility apps, prototypes, and local-install APKs such as calculators, daily expense trackers, note tools, check-in apps, and other simple single-activity applications.

## What This Skill Can Do

- Create a minimal native Android app from scratch.
- Generate a simple Java `Activity`-based project.
- Add basic Android resources such as app name, theme colors, and vector launcher icon.
- Package APKs without Gradle by using Android SDK command-line tools.
- Use `aapt`, `javac`, `d8`, `zipalign`, and `apksigner` to build a signed APK.
- Verify the final APK before delivery.
- Help install the APK to a connected Android device with `adb`.
- Recover from common command-line Android build issues.

## Best Use Cases

- "Make me an Android calculator APK."
- "Create a daily income and expense tracker APK."
- "Build a simple Android notes app installation package."
- "Package this small Java Android project into an APK."
- "I do not have Android Studio/Gradle, but I need an APK."
- "Verify that this APK is signed and installable."

## Available Skill

### `$android-apk-builder`

Build lightweight Android APKs from scratch or from a simple native Android project.

Use it when you want Codex to:

- scaffold a small Android app,
- create app resources and launcher icon,
- build a signed APK,
- validate APK contents and signature,
- optionally install it with `adb`.

Example prompts:

```text
Use $android-apk-builder to create a simple Android calculator APK.
```

```text
Use $android-apk-builder to build a daily expense and income tracker APK with a simple launcher icon.
```

```text
Use $android-apk-builder to package this Android project into a signed APK and verify it.
```

## Skill Directory Structure

```text
android-apk-builder/
  SKILL.md
  agents/
    openai.yaml
  scripts/
    manual_apk_build.ps1
```

## Included Script

The skill includes:

```text
scripts/manual_apk_build.ps1
```

This PowerShell script performs a manual Android APK build for minimal Java Activity projects.

It expects a project layout like:

```text
project/
  AndroidManifest.xml
  res/
  src/
    com/example/app/MainActivity.java
  build-apk.ps1
```

By default, it expects the local Android SDK at:

```text
workspace/
  android-sdk/
    platforms/android-28/android.jar
    build-tools/28.0.3/
```

The SDK path can be overridden with `-SdkRoot`.

## Manual Build Flow

The manual build script runs this flow:

1. Compile Android resources with `aapt`.
2. Compile Java sources with `javac`.
3. Package compiled classes into `classes.jar`.
4. Convert Java bytecode to `classes.dex` with `d8`.
5. Add `classes.dex` to the unsigned APK.
6. Generate a debug keystore when needed.
7. Align the APK with `zipalign`.
8. Sign the APK with `apksigner`.

## Verification Flow

The skill verifies that:

- `classes.dex` exists in the APK.
- `AndroidManifest.xml` and `resources.arsc` exist in the APK.
- `zipalign` validation passes.
- `apksigner verify` passes.
- `aapt dump badging` shows the expected package, app label, SDK versions, and launchable activity.

## Installation

Copy the skill folder into your Codex skills directory:

```powershell
Copy-Item -Recurse .\android-apk-builder "$env:USERPROFILE\.codex\skills\android-apk-builder"
```

Then start a new Codex session or reload skills if your Codex environment supports it.

## Requirements

For manual APK building:

- Windows PowerShell
- Java/JDK with `javac`, `jar`, and `keytool`
- Android SDK Platform, such as Android 28
- Android Build-Tools, such as 28.0.3
- Optional: `adb` for device installation

If the SDK/build-tools are missing, the skill instructs Codex to search locally first and request approval before downloading official Android SDK packages.

## Limitations

This skill is intended for small Android apps and prototypes.

It is not a replacement for a full Android Studio/Gradle workflow when the app needs:

- complex navigation,
- Kotlin/Jetpack Compose,
- external dependencies,
- advanced permissions,
- app store release signing,
- multi-module architecture,
- production-grade CI/CD.

For existing Gradle projects, the skill tells Codex to prefer the repository's own Gradle build system.

## Example Output

Typical final output from a task using this skill:

```text
APK generated:
D:\workspace\android-calculator\build\calculator.apk

Verified:
- classes.dex present
- zipalign passed
- apksigner v1/v2 signature passed
- package and launchable activity detected by aapt
```
