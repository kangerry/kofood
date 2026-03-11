param(
  [string]$DeviceId = "emulator-5554",
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
if (-not (Test-Path $gradleHome)) {
  New-Item -ItemType Directory -Force -Path $gradleHome | Out-Null
}
$env:GRADLE_USER_HOME = $gradleHome
# Launch emulator directly to avoid CLI issues
$emuArgs = @("-avd","KOJEK_36","-no-snapshot","-no-snapshot-save","-no-snapshot-load","-gpu","swiftshader_indirect","-netdelay","none","-netspeed","full")
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
