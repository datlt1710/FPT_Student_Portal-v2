package com.fpt.accessportal.service;

import com.fpt.accessportal.repository.AccessDb;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class StudentPortalService {
  private final AccessDb db;

  public StudentPortalService(AccessDb db) {
    this.db = db;
  }

  public List<Map<String, Object>> list(long id, String section) throws SQLException {
    return switch (section) {
      case "marks" -> marks(id);
      case "attendance" -> attendance(id);
      case "exams" -> exams(id);
      case "fees" ->
          db.query(
              "SELECT FeeID, Description AS FeeName, Amount,DueDate,PaymentStatus AS"
                  + " Status,PaymentStatus FROM TuitionFees WHERE StudentID=? ORDER BY FeeID DESC",
              id);
      case "applications" ->
          db.query(
              "SELECT RequestID,RequestType AS Title,RequestContent AS Content,RequestStatus AS"
                  + " Status,SubmittedAt AS SubmittedDate FROM StudentRequests WHERE StudentID=?"
                  + " ORDER BY RequestID DESC",
              id);
      case "notifications" ->
          db.query(
              "SELECT NotificationID,Title,Body AS Content,CreatedAt,IsRead FROM Notifications"
                  + " WHERE StudentID=? ORDER BY NotificationID DESC",
              id);
      case "messages" ->
          db.query(
              "SELECT MessageID,SenderName AS Subject,MessageBody AS Content,SentAt AS"
                  + " CreatedAt,IsRead FROM Messages WHERE StudentID=? ORDER BY MessageID DESC",
              id);
      case "contacts" ->
          db.query(
              "SELECT ContactID,Department,ContactName,Email,Phone FROM Contacts ORDER BY"
                  + " ContactID");
      case "reviews" ->
          db.query(
              "SELECT ReviewID,ServiceName,Rating,Feedback,CreatedAt FROM ServiceReviews WHERE"
                  + " StudentID=? ORDER BY ReviewID DESC",
              id);
      default -> throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Unknown section");
    };
  }

  public Map<String, Object> detail(long id, String section, long enrollmentId) throws SQLException {
    if (!section.equals("marks") && !section.equals("attendance"))
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Unknown detail section");
    return list(id, section).stream()
        .filter(row -> row.get("EnrollmentID") instanceof Number number
            && number.longValue() == enrollmentId)
        .findFirst()
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Enrollment not found"));
  }

  private List<Map<String, Object>> exams(long id) throws SQLException {
    var rows = db.query(
        "SELECT x.ExamID,e.EnrollmentID,e.Semester,e.ClassCode,c.CourseCode AS SubjectCode,c.CourseName AS"
            + " SubjectName,x.ExamDate,x.ExamTime,x.Room,x.ExamType FROM (ExamSchedules AS x"
            + " INNER JOIN Enrollments AS e ON x.EnrollmentID=e.EnrollmentID) INNER JOIN"
            + " Courses AS c ON e.CourseID=c.CourseID WHERE e.StudentID=? ORDER BY"
            + " x.ExamDate,x.ExamTime,x.ExamID", id);
    List<Map<String, Object>> exams = new ArrayList<>();
    for (var raw : rows) {
      Map<String, Object> row = new LinkedHashMap<>();
      for (String field : List.of("ExamID", "EnrollmentID", "Semester", "ClassCode",
          "SubjectCode", "SubjectName", "ExamDate", "ExamTime", "Room", "ExamType"))
        row.put(field, raw.get(field));
      Object date = row.get("ExamDate");
      String status = "UNKNOWN";
      if (date != null) {
        LocalDate examDate = LocalDate.parse(date.toString().substring(0, 10));
        status = examDate.isBefore(LocalDate.now()) ? "PAST"
            : examDate.equals(LocalDate.now()) ? "TODAY" : "UPCOMING";
      }
      row.put("ExamStatus", status);
      row.put("ExamTime", time(row.get("ExamTime")));
      exams.add(row);
    }
    return exams;
  }

  public void submit(long id, String section, Map<String, Object> data) throws SQLException {
    switch (section) {
      case "applications" -> {
        String title =
            Objects.toString(data.getOrDefault("title", data.getOrDefault("Title", "")), "").trim();
        String content =
            Objects.toString(data.getOrDefault("content", data.getOrDefault("Content", "")), "");
        if (title.isBlank())
          throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "title là bắt buộc");
        db.update(
            "INSERT INTO StudentRequests"
                + " (StudentID,RequestType,RequestContent,RequestStatus,SubmittedAt) VALUES"
                + " (?,?,?,?,?)",
            id,
            title,
            content,
            "Pending",
            Timestamp.valueOf(LocalDateTime.now()));
      }
      case "reviews" -> {
        Object raw = data.getOrDefault("rating", data.get("Rating"));
        int rating;
        try {
          rating = Integer.parseInt(Objects.toString(raw, "0"));
        } catch (NumberFormatException ex) {
          rating = 0;
        }
        if (rating < 1 || rating > 5)
          throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "rating phải từ 1 đến 5");
        String service =
            Objects.toString(
                data.getOrDefault("service", data.getOrDefault("ServiceName", "Student services")),
                "Student services");
        String feedback =
            Objects.toString(data.getOrDefault("comment", data.getOrDefault("Feedback", "")), "");
        db.update(
            "INSERT INTO ServiceReviews (StudentID,ServiceName,Rating,Feedback,CreatedAt) VALUES"
                + " (?,?,?,?,?)",
            id,
            service,
            rating,
            feedback,
            Timestamp.valueOf(LocalDateTime.now()));
      }
      default ->
          throw new ResponseStatusException(
              HttpStatus.METHOD_NOT_ALLOWED, "Chỉ được tạo đơn hoặc đánh giá");
    }
  }

  public List<Map<String, Object>> timetable(long id, LocalDate start, LocalDate end)
      throws SQLException {
    if (start.isAfter(end) || start.plusDays(366).isBefore(end))
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Khoảng ngày không hợp lệ");
    var rows =
        db.query(
            "SELECT"
                + " t.SessionID,t.SessionDate,t.StartTime,t.EndTime,t.Room,t.SessionStatus,c.CourseCode,c.CourseName,e.ClassCode,t.StudyMode"
                + " FROM (TimetableSessions AS t INNER JOIN Enrollments AS e ON"
                + " t.EnrollmentID=e.EnrollmentID) INNER JOIN Courses AS c ON e.CourseID=c.CourseID"
                + " WHERE e.StudentID=? AND t.SessionDate>=? AND t.SessionDate<? ORDER BY"
                + " t.SessionDate,t.StartTime",
            id,
            java.sql.Date.valueOf(start),
            java.sql.Date.valueOf(end.plusDays(1)));
    List<Map<String, Object>> result = new ArrayList<>();
    int i = 0;
    for (var row : rows) {
      Map<String, Object> m = new LinkedHashMap<>();
      m.put("sessionId", row.get("SessionID"));
      m.put("subjectCode", row.get("CourseCode"));
      m.put("subjectName", row.get("CourseName"));
      m.put("classCode", row.get("ClassCode"));
      m.put(
          "sessionDate",
          Objects.toString(row.get("SessionDate"), "")
              .substring(0, Math.min(10, Objects.toString(row.get("SessionDate"), "").length())));
      m.put("startTime", time(row.get("StartTime")));
      m.put("endTime", time(row.get("EndTime")));
      m.put("slotNumber", 0);
      m.put("sessionNumber", ++i);
      m.put("roomCode", Objects.toString(row.get("Room"), ""));
      m.put("building", "");
      m.put("lecturerName", "");
      m.put("sessionStatus", Objects.toString(row.get("SessionStatus"), ""));
      m.put("meetingUrl", null);
      result.add(m);
    }
    return result;
  }

  // Convert Access assessment-level marks to one course card per enrollment.
  private List<Map<String, Object>> marks(long id) throws SQLException {
    var rows =
        db.query(
            "SELECT e.EnrollmentID,e.ClassCode,e.Semester,c.CourseCode AS SubjectCode,c.CourseName"
                + " AS SubjectName,m.MarkID,m.AssessmentName,m.Score,m.Weight FROM (Enrollments AS e INNER JOIN Courses AS c"
                + " ON e.CourseID=c.CourseID) LEFT JOIN Marks AS m ON e.EnrollmentID=m.EnrollmentID"
                + " WHERE e.StudentID=? ORDER BY e.EnrollmentID",
            id);
    Map<Object, Map<String, Object>> result = new LinkedHashMap<>();
    Map<Object, double[]> sums = new HashMap<>();
    for (var r : rows) {
      Object key = r.get("EnrollmentID");
      result.computeIfAbsent(
          key,
          k -> {
            Map<String, Object> x = new LinkedHashMap<>();
            x.put("EnrollmentID", r.get("EnrollmentID"));
            x.put("Assessments", new ArrayList<Map<String, Object>>());
            x.put("SubjectCode", r.get("SubjectCode"));
            x.put("SubjectName", r.get("SubjectName"));
            x.put("ClassName", r.get("ClassCode"));
            x.put("Semester", r.get("Semester"));
            x.put("AverageMark", null);
            x.put("GradeStatus", "IN PROGRESS");
            return x;
          });
      if (r.get("MarkID") != null) {
        Map<String, Object> assessment = new LinkedHashMap<>();
        assessment.put("AssessmentName", r.get("AssessmentName"));
        assessment.put("Score", r.get("Score"));
        assessment.put("Weight", r.get("Weight"));
        @SuppressWarnings("unchecked")
        var assessments = (List<Map<String, Object>>) result.get(key).get("Assessments");
        assessments.add(assessment);
      }
      if (r.get("Score") instanceof Number score) {
        double weight = r.get("Weight") instanceof Number w ? w.doubleValue() : 1.0;
        if (weight <= 0) weight = 1;
        double[] a = sums.computeIfAbsent(key, k -> new double[2]);
        a[0] += score.doubleValue() * weight;
        a[1] += weight;
      }
    }
    for (var e : result.entrySet()) {
      double[] a = sums.get(e.getKey());
      if (a != null && a[1] > 0) {
        double avg = Math.round(a[0] / a[1] * 100.0) / 100.0;
        e.getValue().put("AverageMark", avg);
        e.getValue().put("GradeStatus", avg >= 5.0 ? "PASSED" : "NOT PASSED");
      }
    }
    return new ArrayList<>(result.values());
  }

  private List<Map<String, Object>> attendance(long id) throws SQLException {
    var rows =
        db.query(
            "SELECT e.EnrollmentID,e.ClassCode,e.Semester,c.CourseCode AS SubjectCode,c.CourseName"
                + " AS SubjectName,t.SessionID,t.SessionDate,t.StartTime,t.EndTime,t.Room,a.AttendanceStatus FROM ((Enrollments AS e INNER"
                + " JOIN Courses AS c ON e.CourseID=c.CourseID) LEFT JOIN TimetableSessions AS t ON"
                + " e.EnrollmentID=t.EnrollmentID) LEFT JOIN AttendanceRecords AS a ON"
                + " t.SessionID=a.SessionID AND a.StudentID=e.StudentID WHERE e.StudentID=? ORDER BY"
                + " e.EnrollmentID,t.SessionDate,t.StartTime",
            id);
    Map<Object, Map<String, Object>> result = new LinkedHashMap<>();
    for (var r : rows) {
      Object key = r.get("EnrollmentID");
      Map<String, Object> item =
          result.computeIfAbsent(
              key,
              k -> {
                Map<String, Object> x = new LinkedHashMap<>();
                x.put("EnrollmentID", r.get("EnrollmentID"));
                x.put("Sessions", new ArrayList<Map<String, Object>>());
                x.put("Absent", 0);
                x.put("Future", 0);
                x.put("Unrecorded", 0);
                x.put("SubjectCode", r.get("SubjectCode"));
                x.put("SubjectName", r.get("SubjectName"));
                x.put("ClassCode", r.get("ClassCode"));
                x.put("Semester", r.get("Semester"));
                x.put("Attended", 0);
                x.put("TotalSessions", 0);
                x.put("StartDate", null);
                x.put("EndDate", null);
                return x;
              });
      Object date = r.get("SessionDate");
      if (date != null) {
        String status = Objects.toString(r.get("AttendanceStatus"), "");
        if (status.isBlank()) {
          status = LocalDate.parse(date.toString().substring(0, 10)).isAfter(LocalDate.now())
              ? "Future" : "Unrecorded";
        }
        String countKey = switch (status.toLowerCase(java.util.Locale.ROOT)) {
          case "absent" -> "Absent";
          case "future" -> "Future";
          case "unrecorded" -> "Unrecorded";
          default -> null;
        };
        if (countKey != null) item.put(countKey, ((Integer) item.get(countKey)) + 1);
        Map<String, Object> session = new LinkedHashMap<>();
        session.put("SessionID", r.get("SessionID"));
        session.put("SessionDate", date);
        session.put("StartTime", time(r.get("StartTime")));
        session.put("EndTime", time(r.get("EndTime")));
        session.put("Room", r.get("Room"));
        session.put("AttendanceStatus", status);
        @SuppressWarnings("unchecked")
        var sessions = (List<Map<String, Object>>) item.get("Sessions");
        sessions.add(session);
        item.put("TotalSessions", ((Integer) item.get("TotalSessions")) + 1);
        String d = date.toString();
        if (item.get("StartDate") == null) item.put("StartDate", d);
        item.put("EndDate", d);
      }
      if ("present".equalsIgnoreCase(Objects.toString(r.get("AttendanceStatus"), "")))
        item.put("Attended", ((Integer) item.get("Attended")) + 1);
    }
    return new ArrayList<>(result.values());
  }

  private String time(Object o) {
    if (o == null) return "";
    if (o instanceof java.sql.Timestamp t)
      return t.toLocalDateTime().toLocalTime().toString().substring(0, 5);
    if (o instanceof java.sql.Time t) return t.toLocalTime().toString().substring(0, 5);
    String v = o.toString();
    if (v.contains("T") && v.length() >= 16) return v.substring(11, 16);
    if (v.contains(" ") && v.length() >= 16) return v.substring(11, 16);
    return v.length() >= 5 ? v.substring(0, 5) : v;
  }
}
