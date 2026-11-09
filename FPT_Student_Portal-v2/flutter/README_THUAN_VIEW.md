# FPT Student Portal – giữ nguyên giao diện gốc, dữ liệu demo

Bản này được tạo từ `NovaStudent_Full_SemesterSchedule.zip`, không phải giao diện thiết kế lại.

- Giữ lại `main.dart`, `login_screen.dart`, `home_page.dart`, `semester_schedule_screen.dart`, `timetable_screen.dart`, `mark_report_view.dart`, `attendance_report_view.dart` và các widget / assets gốc.
- Thay HTTP tới server 8086 bằng `lib/services/mock_http.dart`, trả JSON mẫu trong bộ nhớ.
- Nút Google theo giao diện cũ kích hoạt đăng nhập demo, **không xác thực Google thật**.
- Form đăng ký/quên mật khẩu cũng là mô phỏng, **không gửi email**.
- Dữ liệu gửi ở màn dịch vụ chỉ tồn tại trong phiên chạy, tải lại ứng dụng sẽ mất.
- Không cần SQL Server, Microsoft Access, Spring Boot hoặc kết nối mạng.

## Chạy
```powershell
flutter pub get
flutter run -d chrome
```

Lưu ý: Chưa thực hiện flutter analyze/test trong môi trường này vì Flutter SDK không được cài đặt.
