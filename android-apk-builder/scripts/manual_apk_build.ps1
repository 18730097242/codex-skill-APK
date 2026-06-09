param(
    [string]$ProjectRoot = (Get-Location).Path,
    [string]$SdkRoot = (Join-Path (Split-Path -Parent (Get-Location).Path) "android-sdk"),
    [string]$BuildToolsVersion = "28.0.3",
    [string]$PlatformVersion = "android-28",
    [string]$OutputName = "app.apk",
    [string]$KeyAlias = "apk-builder"
)

$ErrorActionPreference = "Stop"

function New-Dir($Path) {
    [System.IO.Directory]::CreateDirectory($Path) | Out-Null
}

function Require-File($Path, $Label) {
    if (!(Test-Path $Path)) {
        throw "Missing $Label`: $Path"
    }
}

$BuildTools = Join-Path $SdkRoot "build-tools\$BuildToolsVersion"
$AndroidJar = Join-Path $SdkRoot "platforms\$PlatformVersion\android.jar"
$Manifest = Join-Path $ProjectRoot "AndroidManifest.xml"
$ResDir = Join-Path $ProjectRoot "res"
$SrcDir = Join-Path $ProjectRoot "src"
$OutDir = Join-Path $ProjectRoot "build"
$GenDir = Join-Path $OutDir "gen"
$ClassesDir = Join-Path $OutDir "classes"
$DexDir = Join-Path $OutDir "dex"
$DexFile = Join-Path $DexDir "classes.dex"
$ClassesJar = Join-Path $OutDir "classes.jar"
$UnsignedApk = Join-Path $OutDir "app-unsigned.apk"
$UnalignedApk = Join-Path $OutDir "app-unaligned.apk"
$AlignedApk = Join-Path $OutDir "app-aligned-unsigned.apk"
$FinalApk = Join-Path $OutDir $OutputName
$Keystore = Join-Path $OutDir "debug-apk-builder.keystore"

Require-File $Manifest "Android manifest"
Require-File $AndroidJar "Android platform jar"
Require-File (Join-Path $BuildTools "aapt.exe") "aapt"
Require-File (Join-Path $BuildTools "zipalign.exe") "zipalign"
Require-File (Join-Path $BuildTools "lib\d8.jar") "d8.jar"
Require-File (Join-Path $BuildTools "lib\apksigner.jar") "apksigner.jar"

$manifestText = Get-Content $Manifest -Raw
$packageMatch = [regex]::Match($manifestText, 'package\s*=\s*"([^"]+)"')
if (!$packageMatch.Success) {
    throw "Could not find package attribute in AndroidManifest.xml"
}
$PackageName = $packageMatch.Groups[1].Value
$PackagePath = $PackageName.Replace(".", "\")

New-Dir $OutDir
New-Dir $GenDir
New-Dir $ClassesDir
New-Dir $DexDir
New-Dir (Join-Path $GenDir $PackagePath)
New-Dir (Join-Path $ClassesDir $PackagePath)

Remove-Item -Force $UnsignedApk, $UnalignedApk, $AlignedApk, $FinalApk, $DexFile, $ClassesJar -ErrorAction SilentlyContinue

& (Join-Path $BuildTools "aapt.exe") package -f -m `
    -J $GenDir `
    -M $Manifest `
    -S $ResDir `
    -I $AndroidJar `
    -F $UnsignedApk
if ($LASTEXITCODE -ne 0) { throw "aapt package failed with exit code $LASTEXITCODE" }

$Sources = Get-ChildItem -Path $SrcDir, $GenDir -Recurse -Filter *.java | ForEach-Object { $_.FullName }
if (!$Sources -or $Sources.Count -eq 0) {
    throw "No Java sources found under $SrcDir or $GenDir"
}

& javac -encoding UTF-8 -source 1.8 -target 1.8 `
    -bootclasspath $AndroidJar `
    -d $ClassesDir `
    $Sources
if ($LASTEXITCODE -ne 0) { throw "javac failed with exit code $LASTEXITCODE" }

Push-Location $ClassesDir
try {
    & jar cf $ClassesJar "."
    if ($LASTEXITCODE -ne 0) { throw "jar failed with exit code $LASTEXITCODE" }
} finally {
    Pop-Location
}

& java -jar (Join-Path $BuildTools "lib\d8.jar") `
    --min-api 23 `
    --lib $AndroidJar `
    --output $DexDir `
    $ClassesJar
if ($LASTEXITCODE -ne 0) { throw "d8 failed with exit code $LASTEXITCODE" }
Require-File $DexFile "classes.dex"

Copy-Item $UnsignedApk $UnalignedApk -Force
Push-Location $DexDir
try {
    & (Join-Path $BuildTools "aapt.exe") add $UnalignedApk "classes.dex"
    if ($LASTEXITCODE -ne 0) { throw "aapt add classes.dex failed with exit code $LASTEXITCODE" }
} finally {
    Pop-Location
}

if (!(Test-Path $Keystore)) {
    & keytool -genkeypair `
        -keystore $Keystore `
        -storepass android `
        -keypass android `
        -alias $KeyAlias `
        -keyalg RSA `
        -keysize 2048 `
        -validity 10000 `
        -dname "CN=Android APK Builder,O=Codex,C=CN"
    if ($LASTEXITCODE -ne 0) { throw "keytool failed with exit code $LASTEXITCODE" }
}

& (Join-Path $BuildTools "zipalign.exe") -f 4 $UnalignedApk $AlignedApk
if ($LASTEXITCODE -ne 0) { throw "zipalign failed with exit code $LASTEXITCODE" }

& java -jar (Join-Path $BuildTools "lib\apksigner.jar") sign `
    --ks $Keystore `
    --ks-key-alias $KeyAlias `
    --ks-pass pass:android `
    --key-pass pass:android `
    --out $FinalApk `
    $AlignedApk
if ($LASTEXITCODE -ne 0) { throw "apksigner failed with exit code $LASTEXITCODE" }

Write-Host "APK generated: $FinalApk"
