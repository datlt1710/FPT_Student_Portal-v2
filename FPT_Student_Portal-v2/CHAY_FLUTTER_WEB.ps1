$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot 'flutter')
flutter pub get
flutter run -d chrome --web-port=51366 --dart-define=API_BASE_URL=http://localhost:8086 --dart-define=GOOGLE_WEB_CLIENT_ID=575300277989-2hu6jrrb3qh2cl61suk86lqvcaqhgb1s.apps.googleusercontent.com
