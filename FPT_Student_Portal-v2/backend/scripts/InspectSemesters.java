import java.sql.*;

public class InspectSemesters {
  public static void main(String[] args) throws Exception {
    try (var c = DriverManager.getConnection("jdbc:ucanaccess://" + args[0] + ";memory=true")) {
      for (String sql : new String[] {
          "SELECT StudentID,FullName,Email FROM Students ORDER BY StudentID",
          "SELECT StudentID,Semester,COUNT(*) AS EnrollmentCount FROM Enrollments GROUP BY StudentID,Semester ORDER BY StudentID,Semester",
          "SELECT MIN(SessionDate) AS FirstSession,MAX(SessionDate) AS LastSession,COUNT(*) AS SessionCount FROM TimetableSessions",
          "SELECT CourseID,CourseCode,CourseName FROM Courses ORDER BY CourseID"}) {
        System.out.println("RESULT " + sql);
        try (var p = c.prepareStatement(sql); var r = p.executeQuery()) {
          var md = r.getMetaData();
          while (r.next()) {
            StringBuilder row = new StringBuilder("DATA ");
            for (int i = 1; i <= md.getColumnCount(); i++) row.append(md.getColumnLabel(i)).append('=').append(r.getObject(i)).append(" | ");
            System.out.println(row);
          }
        }
      }
    }
  }
}
