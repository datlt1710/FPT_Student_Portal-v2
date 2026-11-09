package com.fpt.accessportal.controller;

import com.fpt.accessportal.security.SessionAuthorization;
import com.fpt.accessportal.service.StudentPortalService;
import jakarta.servlet.http.HttpServletRequest;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/students/{id}")
public class StudentPortalController {
  private final StudentPortalService service;
  private final SessionAuthorization authorization;

  public StudentPortalController(StudentPortalService service, SessionAuthorization authorization) {
    this.service = service;
    this.authorization = authorization;
  }

  @GetMapping("/portal/{section}")
  public List<Map<String, Object>> list(
      HttpServletRequest request, @PathVariable long id, @PathVariable String section,
      @RequestParam(required = false) String semester)
      throws SQLException {
    authorization.authorize(request, id);
    var rows = service.list(id, section);
    if (semester == null || semester.isBlank()) return rows;
    String selected = semester.replaceAll("\\s+", "");
    return rows.stream().filter(row -> matchesSemester(row, selected, "Semester", "SemesterCode", "SemesterID"))
        .toList();
  }

  @GetMapping("/portal/{section}/{enrollmentId}")
  public Map<String, Object> detail(
      HttpServletRequest request, @PathVariable long id, @PathVariable String section,
      @PathVariable long enrollmentId) throws SQLException {
    authorization.authorize(request, id);
    return service.detail(id, section, enrollmentId);
  }

  @PostMapping("/portal/{section}")
  public ResponseEntity<Map<String, Boolean>> submit(
      HttpServletRequest request,
      @PathVariable long id,
      @PathVariable String section,
      @RequestBody Map<String, Object> data)
      throws SQLException {
    authorization.authorize(request, id);
    service.submit(id, section, data);
    return ResponseEntity.status(HttpStatus.CREATED).body(Map.of("success", true));
  }

  @GetMapping("/timetable")
  public List<Map<String, Object>> timetable(
      HttpServletRequest request,
      @PathVariable long id,
      @RequestParam LocalDate start,
      @RequestParam LocalDate end,
      @RequestParam(required = false) String semester)
      throws SQLException {
    authorization.authorize(request, id);
    var rows = service.timetable(id, start, end);
    if (semester == null || semester.isBlank()) return rows;
    String selected = semester.replaceAll("\\s+", "");
    return rows.stream().filter(row -> matchesSemester(row, selected, "semester", "semesterCode", "semesterId"))
        .toList();
  }

  private boolean matchesSemester(Map<String, Object> row, String selected, String... fields) {
    for (String field : fields)
      if (selected.equalsIgnoreCase(java.util.Objects.toString(row.get(field), "").replaceAll("\\s+", ""))) return true;
    return false;
  }
}
