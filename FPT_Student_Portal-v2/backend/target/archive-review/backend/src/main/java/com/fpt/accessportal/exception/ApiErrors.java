package com.fpt.accessportal.exception;

import java.sql.SQLException;
import java.util.Map;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;

@RestControllerAdvice
public class ApiErrors {
  private static final org.slf4j.Logger LOG = org.slf4j.LoggerFactory.getLogger(ApiErrors.class);

  @ExceptionHandler(ResponseStatusException.class)
  public ResponseEntity<Map<String, Object>> response(ResponseStatusException e) {
    return ResponseEntity.status(e.getStatusCode())
        .body(
            Map.of(
                "success",
                false,
                "message",
                e.getReason() == null ? "Request failed" : e.getReason()));
  }

  @ExceptionHandler(SQLException.class)
  public ResponseEntity<Map<String, Object>> db(SQLException e) {
    LOG.error("Access database query failed", e);
    return ResponseEntity.status(500)
        .body(
            Map.of(
                "success",
                false,
                "message",
                "Lỗi truy vấn Access. Kiểm tra schema và file .accdb; xem log backend."));
  }
}
