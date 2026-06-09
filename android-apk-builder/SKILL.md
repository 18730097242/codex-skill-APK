---
name: android-apk-builder
description: Build lightweight Android APKs from scratch or from a simple native Android project, especially when Gradle or a full Android Studio setup is unavailable. Use for requests to create, package, sign, verify, or install a small Android app/APK, including simple Java Activity apps with vector launcher icons and local Android SDK/build-tools setup.
metadata:
  short-description: Build small Android APKs
---

# Android APK Builder

Use this skill when the user asks to create or package a small Android APK, especially a simple utility app, prototype, or local-install APK.

## Approach

1. Inspect the workspace first.
   - If an existing Android/Gradle project is present, prefer its established build (`gradlew assemble...`) and verify the APK.
   - If no Android project exists, scaffold a minimal native Android app: `AndroidManifest.xml`, `res/values`, a vector launcher icon, and a Java `Activity`.
2. Discover the toolchain:
   - Check `java`, `javac`, `keytool`, `jarsigner`, `gradle`, `adb`, `aapt`, `d8`, `apksigner`, `zipalign`.
   - Check `ANDROID_HOME` / `ANDROID_SDK_ROOT`.
   - Search likely local SDK paths before downloading anything.
3. If SDK/build-tools are missing, use official Google Android repository packages only, and request approval before network downloads.
   - For Java 8 environments, Android SDK Platform 28 + Build-Tools 28.0.3 are a reliable fallback.
   - Verify downloaded zip hashes against the official repository index when practical.
4. Build conservatively.
   - Keep the app single-Activity unless the user asks for more.
   - Store simple local data with `SharedPreferences` or SQLite, depending on complexity.
   - Prefer vector XML for a simple launcher icon when a generated bitmap is not necessary.
5. Verify before delivery.
   - APK contains `AndroidManifest.xml`, `resources.arsc`, and `classes.dex`.
   - `zipalign -c -p 4 app.apk` passes.
   - `apksigner verify --verbose` passes.
   - `aapt dump badging app.apk` shows expected package, label, launchable activity, minSdk, and targetSdk.

## Manual Build Script

For a minimal Java Activity project when Gradle is unavailable, copy or adapt `scripts/manual_apk_build.ps1` into the project root as `build-apk.ps1`.

Expected project layout:

```text
project/
  AndroidManifest.xml
  res/
  src/
    com/example/app/MainActivity.java
  build-apk.ps1
```

Default SDK layout used by the script:

```text
workspace/
  android-sdk/
    platforms/android-28/android.jar
    build-tools/28.0.3/
```

If the SDK is elsewhere, call the script with `-SdkRoot`.

## Verification Commands

After a manual build, run the relevant commands from the project or workspace:

```powershell
jar tf .\build\app.apk | Select-String -Pattern 'classes.dex|AndroidManifest.xml|resources.arsc'
<build-tools>\zipalign.exe -c -p 4 .\build\app.apk
java -jar <build-tools>\lib\apksigner.jar verify --verbose --min-sdk-version 23 .\build\app.apk
<build-tools>\aapt.exe dump badging .\build\app.apk
```

If the user wants installation and `adb` is available:

```powershell
adb install -r .\build\app.apk
```

## Common Fixes

- PowerShell script execution blocked: run with `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force; & .\build-apk.ps1`.
- `dx.bat`/`d8.bat` silently exits in partial SDK installs: call `java -jar <build-tools>\lib\d8.jar` directly.
- APK verifies only with old JAR signing or fails API compatibility: zipalign first, then sign with `apksigner`.
- Missing `classes.dex`: fail the build; do not deliver the APK.
- Sandbox prevents external compilers from writing generated files: rerun the exact build command with approval/escalation rather than substituting a fake artifact.

## Delivery

Tell the user the final APK path, app name/package when useful, and exactly which verification steps passed. If generation could not complete, say which toolchain/network component blocked it.
