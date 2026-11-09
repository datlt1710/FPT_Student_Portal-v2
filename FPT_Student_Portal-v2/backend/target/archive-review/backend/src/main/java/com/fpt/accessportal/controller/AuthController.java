package com.fpt.accessportal.controller;

import com.fpt.accessportal.repository.AccessDb;
import com.fpt.accessportal.security.GoogleIdentityVerifier;
import com.fpt.accessportal.security.SessionAuthorization;
import com.fpt.accessportal.security.SessionTokens;
import jakarta.servlet.http.HttpServletRequest;
import java.sql.SQLException;
import java.util.Map;
import java.util.Objects;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
public class AuthController {
  private final AccessDb db;
  private final SessionTokens tokens;
  private final GoogleIdentityVerifier googleVerifier;
  private final SessionAuthorization authorization;

  @Value("${demo.enabled:false}")
  private boolean demo;

  @Value("${demo.email}")
  private String demoEmail;

  @Value("${demo.password:}")
  private String demoPassword;

  public AuthController(
      AccessDb db,
      SessionTokens tokens,
      GoogleIdentityVerifier googleVerifier,
      SessionAuthorization authorization) {
    this.db = db;
    this.tokens = tokens;
    this.googleVerifier = googleVerifier;
    this.authorization = authorization;
  }

  @PostMapping("/api/auth/login")
  public Map<String, Object> login(@RequestBody Map<String, Object> data) throws SQLException {
    String email = Objects.toString(data.get("email"), "").trim();
    String password = Objects.toString(data.get("password"), "");
    if (!demo
        || demoPassword.isBlank()
        || !email.equalsIgnoreCase(demoEmail)
        || !java.security.MessageDigest.isEqual(
            password.getBytes(java.nio.charset.StandardCharsets.UTF_8),
            demoPassword.getBytes(java.nio.charset.StandardCharsets.UTF_8)))
      throw new ResponseStatusException(
          HttpStatus.UNAUTHORIZED, "Demo login không hợp lệ; cần cấu hình xác thực thực tế");
    var rows =
        db.query(
            "SELECT StudentID, StudentCode, FullName, Email, Campus FROM Students WHERE Email=?",
            email);
    if (rows.isEmpty())
      throw new ResponseStatusException(
          HttpStatus.UNAUTHORIZED, "Không tìm thấy sinh viên demo trong Access");
    Map<String, Object> student = rows.get(0);
    long id = ((Number) student.get("StudentID")).longValue();
    return Map.of(
        "success",
        true,
        "student",
        student,
        "accessToken",
        tokens.issue(id),
        "tokenType",
        "Bearer");
  }

  @GetMapping("/api/auth/google/status")
  public Map<String, Object> googleStatus() {
    return Map.of(
        "googleConfigured",
        googleVerifier.isConfigured(),
        "endpoint",
        "/api/auth/google",
        "database",
        "Microsoft Access");
  }

  @PostMapping("/api/auth/google")
  public Map<String, Object> google(@RequestBody Map<String, Object> data) throws SQLException {
    String rawToken = Objects.toString(data.get("idToken"), "").trim();
    if (rawToken.isBlank())
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Thiếu Google ID token");
    GoogleIdentityVerifier.Identity identity = googleVerifier.verify(rawToken);
    // Link to an existing, enrolled student ONLY. Never auto-map all Google users to demo student
    // #1.
    var rows =
        db.query(
            "SELECT StudentID, StudentCode, FullName, Email, Campus FROM Students WHERE Email=?",
            identity.email());
    if (rows.isEmpty())
      throw new ResponseStatusException(
          HttpStatus.FORBIDDEN,
          "Email Google không có hồ sơ sinh viên trong Microsoft Access. Liên hệ quản trị viên để"
              + " đăng ký email.");
    if (rows.size() != 1)
      throw new ResponseStatusException(
          HttpStatus.CONFLICT, "Email sinh viên không duy nhất trong Access");
    Map<String, Object> student = rows.get(0);
    long id = ((Number) student.get("StudentID")).longValue();
    return Map.of(
        "success",
        true,
        "student",
        student,
        "accessToken",
        tokens.issue(id),
        "tokenType",
        "Bearer");
  }

  @PostMapping("/api/auth/student/{operation}")
  public ResponseEntity<Map<String, Object>> unavailable(@PathVariable String operation) {
    return ResponseEntity.status(HttpStatus.NOT_IMPLEMENTED)
        .body(
            Map.of(
                "success",
                false,
                "message",
                "Chức năng "
                    + operation
                    + " chưa cấu hình xác minh email. Không lưu tài khoản giả."));
  }

  @GetMapping("/api/auth/me")
  public Map<String, Object> me(HttpServletRequest request) throws SQLException {
    var l =
        db.query(
            "SELECT StudentID,StudentCode,FullName,Email,Campus FROM Students WHERE StudentID=?",
            authorization.require(request));
    if (l.isEmpty()) throw new ResponseStatusException(HttpStatus.NOT_FOUND);
    return l.get(0);
  }

  @PostMapping("/api/auth/logout")
  public Map<String, Boolean> logout(HttpServletRequest request) {
    tokens.revoke(authorization.bearer(request));
    return Map.of("success", true);
  }
}
