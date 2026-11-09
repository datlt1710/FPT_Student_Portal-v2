# Nova Student Portal — Google Sign-In thật, không database

- Giữ toàn bộ giao diện Flutter cũ.
- `lib/screens/login_screen.dart` đăng nhập Google SDK thật, KHÔNG gửi token đến Spring Boot.
- `lib/widgets/google_login_button_web.dart` hiển thị nút Google chính thức trên Chrome.
- Tên và email lấy từ tài khoản Google. Điểm, lịch học, điểm danh vẫn là dữ liệu demo trong `lib/services/mock_http.dart`.
- `StudentID=1` chỉ dùng để ánh xạ data demo; đây KHÔNG phải xác thực sinh viên FPT.

## BẮT BUỘC: Google Cloud OAuth

1. Truy cập https://console.cloud.google.com/apis/credentials
2. Chọn OAuth 2.0 Client ID loại **Web application**. Bạn có thể dùng client ID đang điền trong `web/index.html`, nếu thuộc dự án Google Cloud mà bạn quản lý; nếu không, thay bằng Web Client ID của bạn tại **hai nơi**:
   - `web/index.html`: meta `google-signin-client_id`
   - `lib/screens/login_screen.dart`: `googleClientId`
3. Authorized JavaScript origins: nhập `http://localhost` và `http://localhost:7357`.
4. Nếu consent screen ở chế độ Testing, thêm email Google của bạn vào **Test users**.
5. Cần bật/cấu hình Google Auth platform/consent screen đúng để hiện cửa sổ đăng nhập.

## Chạy trên Chrome

```powershell
flutter pub get
flutter run -d chrome --web-hostname localhost --web-port 7357
```

Chọn campus, bấm nút Google chính thức, chọn tài khoản và vào Dashboard cũ.

## Lưu ý

Đây là đăng nhập Google thực sự ở phía client, nhưng KHÔNG phải xác thực để bảo vệ dữ liệu trên server. Không dùng quy trình này để cấp quyền truy cập dữ liệu nhạy cảm. Không cần Microsoft Access/SQL Server/Spring Boot.

Không thể kiểm thử runtime Google OAuth trong container vì thiếu Flutter SDK và quyền quản lý Google Cloud; bạn cần tự khai báo origin/client ID phía Google Cloud.
