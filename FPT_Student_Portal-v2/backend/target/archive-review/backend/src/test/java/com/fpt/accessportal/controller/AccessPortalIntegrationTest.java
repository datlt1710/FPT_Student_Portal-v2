package com.fpt.accessportal.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import com.fpt.accessportal.repository.AccessDb;
import com.fpt.accessportal.security.SessionAuthorization;
import com.fpt.accessportal.security.SessionTokens;
import com.fpt.accessportal.service.StudentPortalService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

@EnabledIfEnvironmentVariable(named = "ACCESS_SMOKE_DB", matches = ".+")
class AccessPortalIntegrationTest {
  @Test void queriesActualAccessThroughAuthenticatedApi() throws Exception {
    var db = new AccessDb();
    var path = AccessDb.class.getDeclaredField("path");
    path.setAccessible(true);
    path.set(db, System.getenv("ACCESS_SMOKE_DB"));
    db.verify();
    try (var keepAlive = db.open()) {
    var students = db.query("SELECT StudentID FROM Students ORDER BY StudentID");
    var service = new StudentPortalService(db);
    var tokens = new SessionTokens();
    var mvc = MockMvcBuilders.standaloneSetup(
        new StudentPortalController(service, new SessionAuthorization(tokens))).build();
    for (var student : students) {
      long id = ((Number) student.get("StudentID")).longValue();
      String token = "Bearer " + tokens.issue(id);
      for (String section : java.util.List.of("marks", "attendance", "exams")) {
        mvc.perform(get("/api/students/" + id + "/portal/" + section)
            .header("Authorization", token)).andExpect(status().isOk())
            .andExpect(jsonPath("$").isArray());
        if (!section.equals("exams")) {
          for (var row : service.list(id, section)) {
            mvc.perform(get("/api/students/" + id + "/portal/" + section + "/" + row.get("EnrollmentID"))
                .header("Authorization", token)).andExpect(status().isOk())
                .andExpect(jsonPath("$.EnrollmentID").value(row.get("EnrollmentID")));
          }
        }
      }
    }
    }
  }
}
