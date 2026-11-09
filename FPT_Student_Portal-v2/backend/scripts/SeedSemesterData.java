import java.sql.*;
import java.time.LocalDate;
import java.util.*;

/** Preview by default. Explicit --apply writes only missing Spring/Summer demo rows. */
public class SeedSemesterData {
  static int added;
  static long find(Connection c, String sql, Object... args) throws SQLException {
    try (var p = c.prepareStatement(sql)) {
      for (int i = 0; i < args.length; i++) p.setObject(i + 1, args[i]);
      try (var r = p.executeQuery()) { return r.next() ? r.getLong(1) : 0; }
    }
  }
  static void insert(Connection c, String sql, Object... args) throws SQLException {
    try (var p = c.prepareStatement(sql)) {
      for (int i = 0; i < args.length; i++) p.setObject(i + 1, args[i]);
      added += p.executeUpdate();
    }
  }
  public static void main(String[] args) throws Exception {
    if (args.length < 2) throw new IllegalArgumentException("database.accdb studentIdsCommaSeparated [--apply]");
    List<Long> students = Arrays.stream(args[1].split(",")).map(Long::parseLong).distinct().toList();
    boolean apply = args.length == 3 && args[2].equals("--apply");
    try (var c = DriverManager.getConnection("jdbc:ucanaccess://" + args[0] + ";memory=true")) {
      for (long id : students)
        if (find(c, "SELECT StudentID FROM Students WHERE StudentID=?", id) == 0)
          throw new IllegalArgumentException("Student not found: " + id);
      String[][] courses = {{"DBI202", "SWE201c", "KOR321", "MLN111"}, {"PRJ301", "SWD392", "EXE101", "PRM392"}};
      String[] semesters = {"Spring 2026", "Summer 2026"};
      LocalDate[] starts = {LocalDate.of(2026, 1, 12), LocalDate.of(2026, 5, 11)};
      LocalDate[] exams = {LocalDate.of(2026, 4, 10), LocalDate.of(2026, 8, 10)};
      for (var term : courses) for (String code : term)
        if (find(c, "SELECT CourseID FROM Courses WHERE CourseCode=?", code) == 0)
          throw new IllegalStateException("Missing course: " + code);
      System.out.printf("PREVIEW students=%s semesters=Spring2026,Summer2026 coursesPerTerm=4 weeks=12%n", students);
      System.out.printf("MAX_NEW enrollments=%d sessions=%d marks=%d exams=%d attendance=%d%n",
          students.size()*8, students.size()*96, students.size()*32, students.size()*8, students.size()*96);
      System.out.println("Existing rows are skipped, never updated. Students and Fall2026 remain unchanged.");
      if (!apply) return;
      c.setAutoCommit(false);
      try {
        for (long student : students) for (int term = 0; term < 2; term++) for (int course = 0; course < 4; course++) {
          String code = courses[term][course];
          long cid = find(c, "SELECT CourseID FROM Courses WHERE CourseCode=?", code);
          long eid = find(c, "SELECT EnrollmentID FROM Enrollments WHERE StudentID=? AND CourseID=? AND Semester=?", student, cid, semesters[term]);
          if (eid == 0) {
            insert(c, "INSERT INTO Enrollments (StudentID,CourseID,Semester,ClassCode) VALUES (?,?,?,?)",
                student, cid, semesters[term], "DEMO-" + (term == 0 ? "SP26-" : "SU26-") + code);
            eid = find(c, "SELECT EnrollmentID FROM Enrollments WHERE StudentID=? AND CourseID=? AND Semester=?", student, cid, semesters[term]);
          }
          for (int week = 0; week < 12; week++) {
            var date = java.sql.Date.valueOf(starts[term].plusWeeks(week).plusDays(course));
            var time = java.sql.Time.valueOf(course % 2 == 0 ? "07:30:00" : "10:00:00");
            long session = find(c, "SELECT SessionID FROM TimetableSessions WHERE EnrollmentID=? AND SessionDate=? AND StartTime=?", eid, date, time);
            if (session == 0) {
              insert(c, "INSERT INTO TimetableSessions (EnrollmentID,SessionDate,StartTime,EndTime,Room,StudyMode,SessionStatus) VALUES (?,?,?,?,?,?,?)",
                  eid, date, time, java.sql.Time.valueOf(course % 2 == 0 ? "09:50:00" : "12:20:00"), "DEMO-"+(101+course), "Offline", "Completed");
              session = find(c, "SELECT SessionID FROM TimetableSessions WHERE EnrollmentID=? AND SessionDate=? AND StartTime=?", eid, date, time);
            }
            if (find(c, "SELECT AttendanceID FROM AttendanceRecords WHERE SessionID=? AND StudentID=?", session, student) == 0)
              insert(c, "INSERT INTO AttendanceRecords (SessionID,StudentID,AttendanceStatus) VALUES (?,?,?)", session, student, week % 5 == 4 ? "Absent" : "Present");
          }
          String[] names = {"Quiz 1", "Assignment 1", "Progress Test", "Final exam"};
          double[] weights = {.1, .2, .3, .4};
          for (int assessment = 0; assessment < 4; assessment++) {
            if (find(c, "SELECT MarkID FROM Marks WHERE EnrollmentID=? AND AssessmentName=?", eid, names[assessment]) == 0)
              insert(c, "INSERT INTO Marks (EnrollmentID,AssessmentName,Score,Weight) VALUES (?,?,?,?)",
                  eid, names[assessment], course == 0 ? 4.0 : 7.0 + course * .3, weights[assessment]);
          }
          if (find(c, "SELECT ExamID FROM ExamSchedules WHERE EnrollmentID=? AND ExamType=?", eid, "DEMO-Final") == 0)
            insert(c, "INSERT INTO ExamSchedules (EnrollmentID,ExamDate,ExamTime,Room,ExamType) VALUES (?,?,?,?,?)",
                eid, java.sql.Date.valueOf(exams[term].plusDays(course)), java.sql.Time.valueOf("09:00:00"), "DEMO-EX"+(201+course), "DEMO-Final");
        }
        c.commit();
        System.out.println("COMMITTED inserted=" + added);
      } catch (Exception e) { c.rollback(); throw e; }
    }
  }
}
