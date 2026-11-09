# Nova Student – 9 màn hình bổ sung

Dựa theo 9 ảnh tham khảo do người dùng cung cấp. Bản này bổ sung UI, **không tự tạo API hoặc dữ liệu sinh viên thật**.

## Màn hình đã thêm
- Messages: Tin nhắn/thông báo đăng nhập; tìm kiếm, xem chi tiết DEMO
- Exam schedule: Lịch thi, tab học kỳ, thẻ môn thi DEMO
- Application status: Trạng thái đơn (empty state như ảnh)
- Notification: Danh sách thông báo; tìm kiếm, xem chi tiết DEMO
- Attendance report: Báo cáo điểm danh với vòng tiến độ DEMO
- Mark Report: Kết quả học tập theo môn DEMO
- Student Fee: Số dư và hóa đơn minh họa; nút FPT ĐÓNG hiện thông báo chưa kết nối thanh toán
- Contact: Thông tin liên hệ minh họa
- Service review: Trạng thái chưa có đánh giá (empty state)
- Semester Schedule: placeholder tránh báo `not available yet`.

## Đã nối điều hướng
- `lib/main.dart` import `screens/nova_extra_screens.dart`.
- `_openMenu()` mở `NovaExtraScreen(page: data.title)` cho các ô chưa có trang riêng; `Weekly timetable` vẫn đi vào trang lịch có API hiện có.
- Tab chat mở `NovaExtraScreen(page: 'Messages')`.

## Dữ liệu / Backend
Source backend trong Project.zip hiện có Auth, Student, Timetable. Chưa xác minh API thực cho 9 danh mục bổ sung nên dữ liệu **là DEMO** và được ghi nhãn rõ ràng trong UI. Không dùng số liệu ví dụ làm dữ liệu sinh viên thực tế. Muốn lưu/tải dữ liệu thật cần bổ sung endpoint, bảng và code service tương ứng.

## Chạy trên Windows
```powershell
cd E:\Flutterr\flutter_application_3
flutter pub get
flutter run -d chrome --web-port=57153
```
Backend hiện có cấu hình Flutter gọi `http://localhost:8086` trên web, hãy chạy Spring Boot tương ứng trước khi dùng tính năng lịch.

## Cách dùng bản ZIP
1. Sao lưu thư mục Flutter cũ.
2. Giải nén bản ZIP mới và dùng nguyên project Flutter hoặc chép 2 file `lib/main.dart`, `lib/screens/nova_extra_screens.dart` vào project hiện có.
3. `flutter pub get`, `flutter analyze`, `flutter run`.

Mã nguồn chưa được chạy Flutter analyze trong môi trường tạo file vì không có Flutter SDK.
