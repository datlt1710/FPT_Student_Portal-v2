# FPT Student Portal — Spring Boot + Microsoft Access (.accdb)

Backend dùng **Java 21, Spring Boot 3.5.7, JDBC UCanAccess 5.0.1**. Dùng nguyên database **13 bảng** đã tạo bởi `FPT_Student_Portal_Access_Setup_FIXED.zip`; không dùng SQL Server và không tự thay đổi bảng.

## Chạy trong IntelliJ trên Windows

1. **Đóng Microsoft Access** nếu đang mở file `.accdb` để tránh khóa file.
2. Giải nén dự án, mở thư mục này trong IntelliJ dưới dạng Maven project; JDK 21.
3. Đảm bảo Maven đã tải dependency qua Internet (UCanAccess lần chạy đầu).
4. Mở PowerShell terminal trong IntelliJ:

```powershell
$env:ACCESS_DB_PATH="C:\Users\Admin\Downloads\FPT_Student_Portal-v2\FPT_Student_Portal.accdb"
$env:DEMO_ENABLED="true"
$env:DEMO_EMAIL="demo.student@example.com"
$env:DEMO_PASSWORD="Demo@12345"
& "C:\Program Files\JetBrains\IntelliJ IDEA 2026.1.3\plugins\maven\lib\maven3\bin\mvn.cmd" spring-boot:run
```

Hoặc chạy class `AccessPortalApplication` sau khi cấu hình environment variables trong IntelliJ. **Đường dẫn phải trỏ đến file .accdb có thật, không phải file ZIP.**

Khi chạy từ thư mục `backend`, mặc định backend dùng `../FPT_Student_Portal.accdb` (file trong thư mục `FPT_Student_Portal-v2`). Biến `ACCESS_DB_PATH` nếu được đặt sẽ ghi đè mặc định này; hãy cập nhật cả biến trong cấu hình Run/Debug của IntelliJ nếu đang trỏ tới thư mục cũ. Khởi động lại backend sau khi đổi cấu hình.

> DEMO_ENABLED chỉ dành cho demo local; **không công khai backend lên Internet** khi còn đăng nhập demo. Mật khẩu demo lưu trong biến môi trường; bảng Students không có password. Nếu bạn muốn đăng nhập thực tế, cần bổ sung bảng account có password hash hoặc xác minh Google ID token.

## Kiểm tra

- GET http://localhost:8086/api/health
- POST http://localhost:8086/api/auth/login JSON `{ "email":"demo.student@example.com", "password":"Demo@12345" }`
- GET http://localhost:8086/api/students/1/portal/marks (`Authorization: Bearer <accessToken>`)
- GET http://localhost:8086/api/students/1/timetable?start=2026-11-01&end=2026-11-30 (Bearer)

Android emulator kết nối máy host bằng `http://10.0.2.2:8086`; Flutter web dùng `http://localhost:8086`. Để chạy Flutter Web từ cổng khác, có thể cần cấu hình CORS theo origin cụ thể.

## API

| Method | Endpoint | Data source |
|---|---|---|
| GET | `/api/health` | Kiểm tra file Access |
| POST | `/api/auth/login` | Students + demo credentials (environment) |
| GET | `/api/auth/me` | Students |
| POST | `/api/auth/logout` | Xóa token trong bộ nhớ |
| GET | `/api/students/{id}/timetable?start=YYYY-MM-DD&end=YYYY-MM-DD` | TimetableSessions, Enrollments, Courses |
| GET | `/api/students/{id}/portal/marks` | Marks, Enrollments, Courses |
| GET | `/api/students/{id}/portal/attendance` | AttendanceRecords, TimetableSessions, Enrollments, Courses |
| GET | `/api/students/{id}/portal/exams` | ExamSchedules, Enrollments, Courses |
| GET | `/api/students/{id}/portal/fees` | TuitionFees |
| GET | `/api/students/{id}/portal/applications` | StudentRequests |
| GET | `/api/students/{id}/portal/notifications` | Notifications |
| GET | `/api/students/{id}/portal/messages` | Messages |
| GET | `/api/students/{id}/portal/contacts` | Contacts |
| GET | `/api/students/{id}/portal/reviews` | ServiceReviews |
| POST | `/api/students/{id}/portal/applications` | Tạo StudentRequests |
| POST | `/api/students/{id}/portal/reviews` | Tạo ServiceReviews |

**Quan trọng:** Chưa chạy tích hợp trên máy có Microsoft Access của bạn. Truy vấn UCanAccess/JDBC có thể cần điều chỉnh tùy phiên bản runtime và schema thực tế. Google Login dùng POST /api/auth/google, backend xác minh chữ ký + audience bằng Google API Client và tra Email trong Students. Bắt buộc cấu hình GOOGLE_WEB_CLIENT_ID. Token chỉ lưu trong RAM, server restart là phải đăng nhập lại. Không sử dụng backend demo với thông tin sinh viên thật.


Kiểm tra GOOGLE_WEB_CLIENT_ID: GET http://localhost:8086/api/auth/google/status → googleConfigured=true.

## C?u tr?c m? ngu?n

C?c package n?m d??i `com.fpt.accessportal`:

- `controller`: c?c endpoint x?c th?c, ki?m tra d?ch v? v? c?ng sinh vi?n.
- `service`: nghi?p v? c?ng sinh vi?n, t?ng h?p ?i?m v? ?i?m danh.
- `repository`: k?t n?i v? truy v?n Microsoft Access b?ng JDBC.
- `security`: x?c minh Google ID token, qu?n l? phi?n v? ki?m tra quy?n sinh vi?n.
- `config`: c?u h?nh CORS.
- `exception`: chuy?n l?i th?nh ph?n h?i API v? ghi log l?i database.

`AccessPortalApplication` n?m ? package g?c ?? Spring qu?t c?c package con.
???ng d?n API v? c?u tr?c JSON ???c gi? nguy?n sau khi t? ch?c l?i m?.
