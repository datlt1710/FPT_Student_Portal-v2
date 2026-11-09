package com.fpt.accessportal.controller;

import com.fpt.accessportal.repository.AccessDb;
import java.sql.SQLException;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {
  private final AccessDb db;

  public HealthController(AccessDb db) {
    this.db = db;
  }

  @GetMapping("/api/health")
  public Map<String, Object> health() throws SQLException {
    db.query("SELECT TOP 1 StudentID FROM Students");
    return Map.of(
        "status",
        "UP",
        "service",
        "FPT Student Portal Access Backend",
        "database",
        "Microsoft Access");
  }
}
