# Google Sign-In thật — FPT Student Portal

## Đã sửa trong code

- Giữ nguyên các màn hình Flutter và nút Google.
- Flutter dùng `google_sign_in` để lấy **ID token**, gửi `POST /api/auth/google`.
- Spring Boot kiểm tra **chữ ký Google, audience (Web Client ID), issuer, hạn token, email_verified** bằng GoogleIdTokenVerifier.
- Email được xác minh phải tồn tại **duy nhất** trong bảng `Students` của Microsoft Access. Không tự tạo sinh viên và không cấp quyền truy cập StudentID=1 cho tài khoản khác.
- Backend phát hành accessToken cho các API điểm, lịch học, điểm danh...

## Bắt buộc cấu hình Google Cloud (không thể tự tạo credential thay bạn)

1. Vào https://console.cloud.google.com/apis/credentials và tạo/chọn Google Cloud project.
2. Cấu hình **OAuth consent screen**, với chế độ Testing hãy thêm email tài khoản vào **Test users**.
3. Tạo **OAuth client ID → Web application**. Sao chép client ID dạng `xxxx.apps.googleusercontent.com`.
4. Tạo **OAuth client ID → Android** với package `com.example.flutter_application_3` (xem `flutter/android/app/build.gradle.kts`) và SHA-1 debug/release của app. Lấy SHA-1 từ `cd flutter/android; .\gradlew.bat signingReport` trên Windows (có JDK).
5. Nếu chạy Flutter Web, thêm `http://localhost:<PORT>` vào **Authorized JavaScript origins** của OAuth Web client. Chạy Flutter cố định `--web-port=...`; thay `content` của meta `google-signin-client_id` trong `flutter/web/index.html` bằng **Web client ID** của bạn.
6. Đối chiếu email đăng nhập Google thật với trường `Email` trong bảng `Students` của Access. Nếu chưa có, thêm/cập nhật hồ sơ sinh viên hợp lệ bằng Access. Demo `demo.student@example.com` không phải email Google thực.

## Chạy backend trên Windows

Trong thư mục `backend`:

```powershell
$env:JAVA_HOME="C:\Users\Admin\.jdks\ms-21.0.12.1"
$env:ACCESS_DB_PATH="C:\duong-dan\FPT_Student_Portal.accdb"
$env:GOOGLE_WEB_CLIENT_ID="575300277989-2hu6jrrb3qh2cl61suk86lqvcaqhgb1s.apps.googleusercontent.com"
$maven="C:\Program Files\JetBrains\IntelliJ IDEA 2026.1.3\plugins\maven\lib\maven3\bin\mvn.cmd"
& $maven spring-boot:run
```

`DEMO_ENABLED` không cần bật để dùng Google Sign-In.

## Chạy Flutter Android Emulator

```powershell
cd flutter
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8086 --dart-define=GOOGLE_WEB_CLIENT_ID=575300277989-2hu6jrrb3qh2cl61suk86lqvcaqhgb1s.apps.googleusercontent.com
```

## Test bằng Flutter Web

```powershell
flutter run -d chrome --web-port=51366 --dart-define=API_BASE_URL=http://localhost:8086 --dart-define=GOOGLE_WEB_CLIENT_ID=575300277989-2hu6jrrb3qh2cl61suk86lqvcaqhgb1s.apps.googleusercontent.com
```

Đồng thời sửa meta Google trong `flutter/web/index.html` cùng client ID này. Thêm `http://localhost:51366` vào Authorized JavaScript origins.

## Kiểm tra lỗi

- `401`: ID token sai, hết hạn, không đúng audience hoặc email chưa xác minh.
- `403`: Google xác minh được nhưng email chưa được đăng ký trong bảng Students.
- `503`: backend thiếu GOOGLE_WEB_CLIENT_ID.
- Google Android hủy đăng nhập bất ngờ: kiểm tra package name, SHA-1, Web client ID và OAuth consent test users.
- `http://localhost:8086/api/health` kiểm tra sức khỏe API, nhưng để xác nhận Google cần đăng nhập thật từ Flutter.

**Bảo mật:** không gửi Google ID token hoặc backend accessToken qua chat. Không đưa Google OAuth client secret vào ứng dụng Flutter. Google Client ID (public) không phải client secret. Cơ chế session backend đang lưu trong RAM, khởi động lại sẽ yêu cầu đăng nhập lại; khi triển khai production nên thêm session storage, HTTPS và quản lý tài khoản dựa trên Google `sub` ổn định.


## Chạy nhanh trên máy Windows đã cấu hình

Trong thư mục gốc đã giải nén, chạy `powershell -ExecutionPolicy Bypass -File .\CHAY_BACKEND.ps1` để tự đặt Client ID và đường dẫn Access; file script kiểm tra `ACCESS_DB_PATH` và Maven trước khi chạy. Dừng phiên backend cũ chiếm cổng 8086 trước. Kiểm tra `http://localhost:8086/api/auth/google/status` trả `googleConfigured=true`.
