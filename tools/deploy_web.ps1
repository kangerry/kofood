param(
    [Parameter(Mandatory = $true)][string]$Server,
    [string]$User = "root",
    [string]$Path = "/var/www/kofood",
    [string]$KeyFile = ""
)

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $repoRoot

$hasFlutter = Get-Command flutter -ErrorAction SilentlyContinue
if ($hasFlutter) {
    flutter pub get
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    flutter build web --release --pwa-strategy=offline-first
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} elseif (-not (Test-Path "build/web/index.html")) {
    Write-Error "Flutter not found and build/web not present. Install Flutter or run build once."
    exit 1
} else {
    Write-Host "Flutter not found. Using existing build/web for deployment."
}

$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$tarPath = Join-Path $env:TEMP ("kofood-web-$timestamp.tar")

tar -C "build/web" -cf $tarPath .
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$scpArgs = @()
if ($KeyFile -ne "") { $scpArgs += "-i"; $scpArgs += $KeyFile }
$scpArgs += $tarPath
$scpArgs += "$User@$Server`:~/kofood-web.tar"

& scp @scpArgs
if ($LASTEXITCODE -ne 0) { Remove-Item -Force $tarPath -ErrorAction SilentlyContinue; exit $LASTEXITCODE }

$sshArgs = @()
if ($KeyFile -ne "") { $sshArgs += "-i"; $sshArgs += $KeyFile }
$sshArgs += "$User@$Server"
$sshArgs += "mkdir -p `"$Path`" && tar -xf ~/kofood-web.tar -C `"$Path`" && rm ~/kofood-web.tar"

& ssh @sshArgs
$code = $LASTEXITCODE
Remove-Item -Force $tarPath -ErrorAction SilentlyContinue
exit $code
