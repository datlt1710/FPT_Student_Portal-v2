import java.sql.*;
import java.time.LocalDate;
import java.util.*;
import com.fpt.accessportal.service.StudentPortalService;
import com.fpt.accessportal.repository.AccessDb;

/** Adds isolated demo courses without changing existing students, marks or exams. */
public class SeedDemoCases {
  static int inserted;

  static long find(Connection c, String sql, Object... args) throws SQLException {
    try (var p = c.prepareStatement(sql)) {
      for (int i = 0; i < args.length; i++) p.setObject(i + 1, args[i]);
      try (var rows = p.executeQuery()) { return rows.next() ? rows.getLong(1) : 0; }
    }
  }

  static void insert(Connection c, String sql, Object... args) throws SQLException {
    try (var p = c.prepareStatement(sql)) {
      for (int i = 0; i < args.length; i++) p.setObject(i + 1, args[i]);
      inserted += p.executeUpdate();
    }
  }

  public static void main(String[] args) throws Exception {
    if (args.length != 2 || !args[1].equals("--apply"))
      throw new IllegalArgumentException("Usage: SeedDemoCases.java <database.accdb> --apply");
    String path = java.nio.file.Path.of(args[0]).toAbsolutePath().normalize().toString();
    if (!java.nio.file.Files.isRegularFile(java.nio.file.Path.of(path)))
      throw new IllegalArgumentException("Database not found");
    try (var c = DriverManager.getConnection("jdbc:ucanaccess://" + path + ";memory=true")) {
      List<Long> students = new ArrayList<>();
      try (var p = c.prepareStatement("SELECT StudentID FROM Students ORDER BY StudentID"); var r = p.executeQuery()) {
        while (r.next()) students.add(r.getLong(1));
      }
      if (students.isEmpty()) throw new IllegalStateException("Students is empty");
      c.setAutoCommit(false);
      try {
        for (boolean passed : List.of(false, true)) {
          String code = passed ? "DEMO-PASSED" : "DEMO-NOTPASS";
          String name = passed ? "DEMO - Passed case" : "DEMO - Not passed case";
          long course = find(c, "SELECT CourseID FROM Courses WHERE CourseCode=?", code);
          if (course == 0) {
            insert(c, "INSERT INTO Courses (CourseCode,CourseName,Credits) VALUES (?,?,?)", code, name, 3);
            course = find(c, "SELECT CourseID FROM Courses WHERE CourseCode=?", code);
          }
          for (long student : students) {
            long enrollment = find(c, "SELECT EnrollmentID FROM Enrollments WHERE StudentID=? AND CourseID=? AND Semester=?",
                student, course, "Fall 2026");
            if (enrollment == 0) {
              insert(c, "INSERT INTO Enrollments (StudentID,CourseID,Semester,ClassCode) VALUES (?,?,?,?)",
                  student, course, "Fall 2026", "DEMO-CASES");
              enrollment = find(c, "SELECT EnrollmentID FROM Enrollments WHERE StudentID=? AND CourseID=? AND Semester=?",
                  student, course, "Fall 2026");
            }
            String[] names = {"Quiz 1", "Assignment 1", "Progress Test", "Final exam"};
            double[] weights = {.1, .2, .3, .4};
            for (int i = 0; i < names.length; i++) {
              if (find(c, "SELECT MarkID FROM Marks WHERE EnrollmentID=? AND AssessmentName=?", enrollment, names[i]) == 0)
                insert(c, "INSERT INTO Marks (EnrollmentID,AssessmentName,Score,Weight) VALUES (?,?,?,?)",
                    enrollment, names[i], passed ? 8.0 : 4.0, weights[i]);
            }
            if (find(c, "SELECT ExamID FROM ExamSchedules WHERE EnrollmentID=? AND ExamType=?", enrollment, "DEMO-FE") == 0) {
              LocalDate date = passed ? LocalDate.now().plusDays(7) : LocalDate.now().minusDays(7);
              insert(c, "INSERT INTO ExamSchedules (EnrollmentID,ExamDate,ExamTime,Room,ExamType) VALUES (?,?,?,?,?)",
                  enrollment, java.sql.Date.valueOf(date), java.sql.Time.valueOf("09:00:00"), "DEMO-C208", "DEMO-FE");
            }
          }
        }
        c.commit();
      } catch (Exception e) { c.rollback(); throw e; }

      // Read back through the same service used by HTTP APIs.
      var db = new AccessDb();
      var field = AccessDb.class.getDeclaredField("path");
      field.setAccessible(true);
      field.set(db, path);
      var service = new StudentPortalService(db);
      for (long student : students) {
        var marks = service.list(student, "marks");
        var exams = service.list(student, "exams");
        for (String code : List.of("DEMO-NOTPASS", "DEMO-PASSED")) {
          var mark = marks.stream().filter(r -> code.equals(r.get("SubjectCode"))).findFirst().orElseThrow();
          var exam = exams.stream().filter(r -> code.equals(r.get("SubjectCode"))).findFirst().orElseThrow();
          String expected = code.equals("DEMO-NOTPASS") ? "NOT PASSED" : "PASSED";
          if (!expected.equals(mark.get("GradeStatus"))) throw new IllegalStateException("Unexpected grade status");
          System.out.printf("StudentID=%d Course=%s Average=%s GradeStatus=%s ExamDate=%s ExamStatus=%s%n",
              student, code, mark.get("AverageMark"), mark.get("GradeStatus"), exam.get("ExamDate"), exam.get("ExamStatus"));
        }
      }
      System.out.printf("SUCCESS students=%d inserted=%d database=%s%n", students.size(), inserted, path);
    }
  }
}
