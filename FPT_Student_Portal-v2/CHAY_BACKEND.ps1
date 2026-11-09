$ErrorActionPreference = 'Stop'
$backend = Join-Path $PSScriptRoot 'backend'
$db = Join-Path $PSScriptRoot 'FPT_Student_Portal.accdb'
$maven = 'C:\Program Files\JetBrains\IntelliJ IDEA 2026.1.3\plugins\maven\lib\maven3\bin\mvn.cmd'
$jhome = 'C:\Users\Admin\.jdks\ms-21.0.12.1'
if (-not (Test-Path $db)) { throw "KHONG TIM THAY ACCESS DATABASE: $db" }
if (-not (Test-Path $maven)) { throw "KHONG TIM THAY MAVEN: $maven" }
if (Test-Path $jhome) { $env:JAVA_HOME = $jhome; $env:Path = "$jhome\bin;$env:Path" }
$env:ACCESS_DB_PATH = $db
$env:GOOGLE_WEB_CLIENT_ID = '575300277989-2hu6jrrb3qh2cl61suk86lqvcaqhgb1s.apps.googleusercontent.com'
$env:DEMO_ENABLED = 'false'
Write-Host 'Google OAuth backend: configured; Access: ' $db -ForegroundColor Green
Write-Host 'Check http://localhost:8086/api/auth/google/status after startup'
Set-Location $backend
& $maven spring-boot:run
