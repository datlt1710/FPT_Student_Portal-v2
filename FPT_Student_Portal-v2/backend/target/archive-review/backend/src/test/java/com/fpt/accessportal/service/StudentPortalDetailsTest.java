package com.fpt.accessportal.service;

import static org.junit.jupiter.api.Assertions.*;

import com.fpt.accessportal.repository.AccessDb;
import java.util.*;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;

class StudentPortalDetailsTest {
  @SafeVarargs
  private final StudentPortalService service(Map<String, Object>... rows) {
    return new StudentPortalService(new AccessDb() {
      @Override public List<Map<String, Object>> query(String sql, Object... args) {
        assertEquals(7L, args[0]);
        return Arrays.stream(rows).map(LinkedHashMap::new)
            .map(row -> (Map<String, Object>) row).toList();
      }
    });
  }

  @Test void groupsAssessmentsAndCalculatesWeightedAverage() throws Exception {
    var service = service(
        Map.of("EnrollmentID", 12, "MarkID", 1, "AssessmentName", "Quiz", "Score", 8, "Weight", .25),
        Map.of("EnrollmentID", 12, "MarkID", 2, "AssessmentName", "Project", "Score", 6, "Weight", .75));
    var detail = service.detail(7, "marks", 12);
    assertEquals(6.5, detail.get("AverageMark"));
    assertEquals("PASSED", detail.get("GradeStatus"));
    assertEquals(2, ((List<?>) detail.get("Assessments")).size());
    assertThrows(ResponseStatusException.class, () -> service.detail(7, "marks", 99));
  }

  @Test void distinguishesMissingAttendanceFromAbsenceAndFuture() throws Exception {
    String future = java.time.LocalDate.now().plusDays(2).toString();
    var service = service(
        Map.of("EnrollmentID", 12, "SessionID", 1, "SessionDate", "2020-01-01", "AttendanceStatus", "Present"),
        Map.of("EnrollmentID", 12, "SessionID", 2, "SessionDate", "2020-01-02", "AttendanceStatus", "Absent"),
        Map.of("EnrollmentID", 12, "SessionID", 3, "SessionDate", "2020-01-03"),
        Map.of("EnrollmentID", 12, "SessionID", 4, "SessionDate", future));
    var detail = service.detail(7, "attendance", 12);
    assertEquals(4, detail.get("TotalSessions"));
    for (String field : List.of("Attended", "Absent", "Future", "Unrecorded"))
      assertEquals(1, detail.get(field));
    assertEquals(4, ((List<?>) detail.get("Sessions")).size());
  }

  @Test void exposesExamSemesterAndStatus() throws Exception {
    var result = service(Map.of("Semester", "Fall 2026", "ExamDate", "2020-01-01", "ExamTime", "1899-12-30T09:00:00"))
        .list(7, "exams").getFirst();
    assertEquals("PAST", result.get("ExamStatus"));
    assertEquals("09:00", result.get("ExamTime"));
    assertEquals("Fall 2026", result.get("Semester"));
  }
}
