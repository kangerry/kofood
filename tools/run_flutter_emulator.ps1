param(
  [string]$DeviceId = "emulator-5554",
  [string]$AvdName,
  [switch]$Wipe
)
$ErrorActionPreference = "Stop"
$flutter = "C:\src\flutter\bin\flutter.bat"
$adb = "C:\Users\acer\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$emulator = "C:\Users\acer\AppData\Local\Android\Sdk\emulator\emulator.exe"
$project = "e:\komera\mobile\komera_mobile"
$gradleHome = "e:\komera\gradle_user_home"
$apk = Join-Path $project "build\app\outputs\apk\debug\app-debug.apk"
$package = "com.example.komera_mobile"
$activity = "com.example.komera_mobile.MainActivity"
# Force emulator user dirs to user profile to avoid E:\Android permission issues
$env:ANDROID_SDK_HOME = "C:\Users\acer"
$env:ANDROID_PREFS_ROOT = "C:\Users\acer\.android"
$env:ANDROID_AVD_HOME = "C:\Users\acer\.android\avd"
$env:ANDROID_EMULATOR_HOME = "C:\Users\acer\.android\emulator"
if (-not (Test-Path $env:ANDROID_PREFS_ROOT)) { New-Item -ItemType Directory -Force -Path $env:ANDROID_PREFS_ROOT | Out-Null }
if (-not (Test-Path $env:ANDROID_AVD_HOME)) { New-Item -ItemType Directory -Force -Path $env:ANDROID_AVD_HOME | Out-Null }
if (-not (Test-Path $env:ANDROID_EMULATOR_HOME)) { New-Item -ItemType Directory -Force -Path $env:ANDROID_EMULATOR_HOME | Out-Null }
# Clean up stale lock file in E:\Android if present
$staleLock = "E:\Android\avd\emu-last-feature-flags.protobuf.lock"
if (Test-Path $staleLock) {
  try { Remove-Item -Force $staleLock -ErrorAction SilentlyContinue } catch {}
}
if (-not (Test-Path $gradleHome)) {
  New-Item -ItemType Directory -Force -Path $gradleHome | Out-Null
}
$env:GRADLE_USER_HOME = $gradleHome
# Resolve AVD name: use provided, otherwise pick the first available
if (-not $AvdName -or $AvdName.Trim() -eq "") {
  $available = & $emulator -list-avds 2>$null
  if ($available) {
    if ($available -is [array]) {
      $AvdName = $available[0].ToString().Trim()
    } else {
      $AvdName = $available.ToString().Split("`n")[0].Trim()
    }
  } else {
    throw "No Android Virtual Device (AVD) found. Create one via avdmanager first."
  }
}
# Launch emulator directly to avoid CLI issues
$emuArgs = @("-avd",$AvdName,"-no-snapshot","-no-snapshot-save","-no-snapshot-load","-gpu","swiftshader_indirect","-netdelay","none","-netspeed","full")
if ($Wipe) { $emuArgs += "-wipe-data" }
Start-Process -FilePath $emulator -ArgumentList $emuArgs -WindowStyle Normal | Out-Null
# Wait until any emulator is detected by ADB, then capture its serial
$detected = $false
$serial = $null
for ($i=0; $i -lt 120; $i++) {
  $list = & $adb devices
  $match = ($list | Select-String -Pattern "^emulator-\d+\s+device")
  if ($match) {
    $serial = ($match.Matches[0].Value -split "\s+")[0]
    $detected = $true
    break
  }
  Start-Sleep -Seconds 2
}
if (-not $detected -or -not $serial) {
  throw "ADB did not detect emulator device"
}
$DeviceId = $serial
# Wait until sys.boot_completed == 1
for ($i=0; $i -lt 90; $i++) {
  try {
    $booted = (& $adb -s $DeviceId shell getprop sys.boot_completed) -as [string]
  } catch {
    $booted = ""
  }
  if ($booted -and $booted.Trim() -eq "1") { break }
  Start-Sleep -Seconds 2
}
Push-Location $project
& $flutter clean
if (-not (Test-Path (Join-Path $project "windows\\flutter\\ephemeral\\.plugin_symlinks"))) {
  New-Item -ItemType Directory -Force -Path (Join-Path $project "windows\\flutter\\ephemeral\\.plugin_symlinks") | Out-Null
}
& $flutter pub get
& $flutter build apk --debug
# Find the generated APK in common Flutter/Gradle locations
if (-not (Test-Path $apk)) {
  $apkAlt = Join-Path $project "build\app\outputs\flutter-apk\app-debug.apk"
  if (Test-Path $apkAlt) {
    $apk = $apkAlt
  } else {
    $found = Get-ChildItem -Path (Join-Path $project "build\app\outputs") -Recurse -Filter "app-debug.apk" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
      $apk = $found.FullName
    } else {
      throw "APK not found under $(Join-Path $project 'build\app\outputs')"
    }
  }
}
& $adb -s $DeviceId install -r $apk
& $adb -s $DeviceId shell am start -n "$package/$activity"
Pop-Location
