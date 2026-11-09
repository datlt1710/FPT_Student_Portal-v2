# API cho màn điểm, điểm danh và lịch thi

Base URL local: `http://localhost:8086`.
Mọi request bên dưới cần `Authorization: Bearer <accessToken>` từ Google login.
`studentId` phải là sinh viên của token; sai sinh viên trả 403, thiếu/hết phiên trả 401.

| Màn hình | GET |
|---|---|
| Danh sách điểm | `/api/students/{studentId}/portal/marks` |
| Chi tiết điểm | `/api/students/{studentId}/portal/marks/{enrollmentId}` |
| Danh sách điểm danh | `/api/students/{studentId}/portal/attendance` |
| Chi tiết điểm danh | `/api/students/{studentId}/portal/attendance/{enrollmentId}` |
| Lịch thi | `/api/students/{studentId}/portal/exams` |

Các danh sách trả JSON array. Chi tiết trả JSON object; dùng `EnrollmentID` từ danh sách để mở chi tiết, không dùng CourseID hay StudentID.
Đăng ký môn không thuộc sinh viên hiện tại hoặc không tồn tại trả 404.

Thêm `?semester=FALL2026` để lọc danh sách. So sánh không phân biệt hoa thường và khoảng trắng, nên khớp `Fall 2026`. Bỏ tham số để lấy tất cả học kỳ. Học kỳ không có dữ liệu trả `[]`.

## Điểm

Mỗi môn có `EnrollmentID`, `SubjectCode`, `SubjectName`, `ClassName`, `Semester`, `AverageMark`, `GradeStatus`, `Assessments`.
`Assessments` là array gồm `AssessmentName`, `Score`, `Weight` lấy từ Marks.
Weight giữ nguyên dữ liệu Access (ví dụ 0.1 tương ứng 10% nếu database lưu theo tỷ lệ).
Điểm trung bình tính theo tổng điểm nhân trọng số chia tổng trọng số của các điểm đã có; chưa có điểm trả null.
Status hiện dùng quy tắc trung bình >= 5 là `PASSED`, dưới 5 là `NOT PASSED`, chưa có điểm là `IN PROGRESS`; đây không phải kết luận chính thức theo quy chế môn học.
Database chưa có cột nhóm bài đánh giá nên API chỉ trả tên bài, không tự tạo nhóm Final/Midterm.

## Điểm danh

Mỗi môn có `EnrollmentID`, `SubjectCode`, `SubjectName`, `ClassCode`, `Semester`, `StartDate`, `EndDate`, `Attended`, `Absent`, `Future`, `Unrecorded`, `TotalSessions`, `Sessions`.
`Sessions` gồm `SessionID`, `SessionDate`, `StartTime`, `EndTime`, `Room`, `AttendanceStatus`.
`Attended` đếm Present, `Absent` đếm Absent. Buổi chưa có điểm danh và ngày sau hôm nay là Future; các buổi còn lại chưa có điểm danh là Unrecorded. Không tự coi chưa điểm danh là vắng.
`TotalSessions` tính toàn bộ buổi, kể cả buổi tương lai; Flutter có thể hiển thị tỷ lệ `Attended / TotalSessions` và xử lý mẫu số 0.
Không có dữ liệu giảng viên hoặc số slot trong schema hiện tại; dùng giờ bắt đầu/kết thúc thực tế.

## Lịch thi

Mỗi kỳ thi có `ExamID`, `EnrollmentID`, `Semester`, `ClassCode`, `SubjectCode`, `SubjectName`, `ExamDate`, `ExamTime`, `Room`, `ExamType`, `ExamStatus`.
`ExamTime` có dạng HH:mm. `ExamStatus` là PAST, TODAY, UPCOMING hoặc UNKNOWN khi thiếu ngày; tính theo ngày máy chạy backend. PAST chỉ nghĩa là ngày thi đã qua.
Danh sách sắp theo ngày, giờ và ExamID; số kỳ thi là độ dài array sau lọc.
Schema chưa có giờ kết thúc thi nên API không tự tạo khoảng giờ.

Chưa có dữ liệu thì trả danh sách rỗng; không tạo dữ liệu mẫu hay sửa bảng Students.

## Kiểm thử

`mvn test` chạy kiểm thử logic và phân quyền. Đặt biến `ACCESS_SMOKE_DB` trỏ tới file Access để bật thêm kiểm thử tích hợp chỉ truy vấn SELECT trên database thật. UCanAccess cần quyền tạo file tạm cạnh database.
