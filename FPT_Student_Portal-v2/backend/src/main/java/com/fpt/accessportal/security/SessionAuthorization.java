package com.fpt.accessportal.security;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

@Component
public class SessionAuthorization {
  private final SessionTokens tokens;

  public SessionAuthorization(SessionTokens tokens) {
    this.tokens = tokens;
  }

  public String bearer(HttpServletRequest request) {
    String h = request.getHeader("Authorization");
    return h != null && h.startsWith("Bearer ") ? h.substring(7).trim() : null;
  }

  public long require(HttpServletRequest request) {
    Long id = tokens.lookup(bearer(request));
    if (id == null)
      throw new ResponseStatusException(
          HttpStatus.UNAUTHORIZED, "Chưa đăng nhập hoặc token đã hết hạn");
    return id;
  }

  public void authorize(HttpServletRequest request, long studentId) {
    if (require(request) != studentId)
      throw new ResponseStatusException(
          HttpStatus.FORBIDDEN, "Không được đọc dữ liệu sinh viên khác");
  }
}
