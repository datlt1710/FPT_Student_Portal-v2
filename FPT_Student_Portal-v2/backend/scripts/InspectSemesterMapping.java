import java.sql.*;

public class InspectSemesterMapping {
  public static void main(String[] args) throws Exception {
    try (var c = DriverManager.getConnection("jdbc:ucanaccess://" + args[0] + ";memory=true")) {
      for (String sql : new String[] {
          "SELECT SemesterID,SemesterCode,SemesterName,StartDate,EndDate FROM Semesters ORDER BY StartDate",
          "SELECT COUNT(*) AS TotalEnrollments FROM Enrollments",
          "SELECT COUNT(*) AS MissingMappings FROM Enrollments WHERE SemesterID IS NULL",
          "SELECT COUNT(*) AS InvalidMappings FROM Enrollments AS E LEFT JOIN Semesters AS S ON E.SemesterID=S.SemesterID WHERE S.SemesterID IS NULL",
          "SELECT COUNT(*) AS ConflictingLabels FROM Enrollments AS E INNER JOIN Semesters AS S ON E.SemesterID=S.SemesterID WHERE E.Semester<>S.SemesterName"}) {
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
