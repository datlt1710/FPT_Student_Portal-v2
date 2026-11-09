package com.fpt.accessportal.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.fpt.accessportal.exception.ApiErrors;
import com.fpt.accessportal.security.SessionAuthorization;
import com.fpt.accessportal.security.SessionTokens;
import com.fpt.accessportal.service.StudentPortalService;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

class StudentPortalControllerTest {
  private StubPortalService service;
  private SessionTokens tokens;
  private MockMvc mvc;

  @BeforeEach
  void setUp() {
    service = new StubPortalService();
    tokens = new SessionTokens();
    mvc =
        MockMvcBuilders.standaloneSetup(
                new StudentPortalController(service, new SessionAuthorization(tokens)))
            .setControllerAdvice(new ApiErrors())
            .build();
  }

  @ParameterizedTest
  @ValueSource(strings = {"/portal/semesters", "/portal/marks", "/portal/marks/12", "/portal/attendance/12", "/timetable?start=2026-11-01&end=2026-11-30"})
  void rejectsRequestsWithoutToken(String path) throws Exception {
    mvc.perform(get("/api/students/1" + path)).andExpect(status().isUnauthorized());
    assertEquals(0, service.calls);
  }

  @Test
  void rejectsAccessToAnotherStudent() throws Exception {
    mvc.perform(
            get("/api/students/2/portal/marks")
                .header("Authorization", "Bearer " + tokens.issue(1)))
        .andExpect(status().isForbidden());
    assertEquals(0, service.calls);
  }

  @Test
  void filtersSemesterIgnoringSpacesAndCase() throws Exception {
    service.marks = List.of(Map.of("Semester", "Fall 2026"), Map.of("Semester", "Summer 2026"));
    mvc.perform(get("/api/students/1/portal/exams?semester=FALL2026")
        .header("Authorization", "Bearer " + tokens.issue(1)))
        .andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(1))
        .andExpect(jsonPath("$[0].Semester").value("Fall 2026"));
  }

  @Test
  void filtersTimetableByEnrollmentSemester() throws Exception {
    service.marks = List.of(Map.of("semester", "Fall 2026"), Map.of("semester", "Summer 2026"));
    String token = "Bearer " + tokens.issue(1);
    mvc.perform(get("/api/students/1/timetable?start=2026-11-01&end=2026-11-30&semester=FALL2026")
        .header("Authorization", token))
        .andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(1))
        .andExpect(jsonPath("$[0].semester").value("Fall 2026"));
    mvc.perform(get("/api/students/1/timetable?start=2026-11-01&end=2026-11-30&semester=SPRING2026")
        .header("Authorization", token))
        .andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(0));
  }

  @Test
  void acceptsSemesterIdOrCodeIndependentOfDisplayName() throws Exception {
    service.marks = List.of(Map.of("semester", "Học kỳ mùa hè", "semesterCode", "SUM-26", "semesterId", 2));
    for (String filter : List.of("2", "SUM-26")) {
      mvc.perform(get("/api/students/1/timetable?start=2026-05-01&end=2026-05-31&semester=" + filter)
          .header("Authorization", "Bearer " + tokens.issue(1)))
          .andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(1));
    }
  }

  @Test
  void rejectsDetailForAnotherStudent() throws Exception {
    mvc.perform(get("/api/students/2/portal/marks/12")
        .header("Authorization", "Bearer " + tokens.issue(1)))
        .andExpect(status().isForbidden());
    assertEquals(0, service.calls);
  }

  @Test
  void returnsMarksForAuthenticatedStudent() throws Exception {
    service.marks = List.of(Map.of("SubjectCode", "PRF192"));
    mvc.perform(
            get("/api/students/1/portal/marks")
                .header("Authorization", "Bearer " + tokens.issue(1)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$[0].SubjectCode").value("PRF192"));
  }

  @Test
  void preservesApplicationCreatedResponse() throws Exception {
    mvc.perform(
            post("/api/students/1/portal/applications")
                .header("Authorization", "Bearer " + tokens.issue(1))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"title\":\"Request\"}"))
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.success").value(true));
    assertEquals(1, service.calls);
    assertEquals(1L, service.studentId);
    assertEquals("applications", service.section);
    assertEquals(Map.of("title", "Request"), service.data);
  }

  @Test
  void rejectsRevokedToken() throws Exception {
    String token = tokens.issue(1);
    tokens.revoke(token);
    mvc.perform(get("/api/students/1/portal/marks").header("Authorization", "Bearer " + token))
        .andExpect(status().isUnauthorized());
    assertEquals(0, service.calls);
  }
  private static class StubPortalService extends StudentPortalService {
    private int calls;
    private long studentId;
    private String section;
    private Map<String, Object> data;
    private List<Map<String, Object>> marks = List.of();

    StubPortalService() { super(null); }

    @Override
    public List<Map<String, Object>> timetable(long id, java.time.LocalDate start, java.time.LocalDate end) {
      calls++;
      return marks;
    }

    @Override
    public List<Map<String, Object>> list(long id, String section) {
      calls++;
      this.studentId = id;
      this.section = section;
      return marks;
    }

    @Override
    public void submit(long id, String section, Map<String, Object> data) {
      calls++;
      this.studentId = id;
      this.section = section;
      this.data = data;
    }
  }
}
