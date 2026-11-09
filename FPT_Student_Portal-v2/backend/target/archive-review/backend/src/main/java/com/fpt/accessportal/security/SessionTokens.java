package com.fpt.accessportal.security;

import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.stereotype.Component;

@Component
public class SessionTokens {
  private record Session(long studentId, Instant expiry) {}

  private final ConcurrentHashMap<String, Session> sessions = new ConcurrentHashMap<>();
  private final SecureRandom random = new SecureRandom();

  public String issue(long id) {
    byte[] b = new byte[32];
    random.nextBytes(b);
    String token = Base64.getUrlEncoder().withoutPadding().encodeToString(b);
    sessions.put(token, new Session(id, Instant.now().plusSeconds(8 * 3600)));
    return token;
  }

  public Long lookup(String token) {
    if (token == null) return null;
    Session s = sessions.get(token);
    if (s == null) return null;
    if (s.expiry().isBefore(Instant.now())) {
      sessions.remove(token);
      return null;
    }
    return s.studentId();
  }

  public void revoke(String token) {
    if (token != null) sessions.remove(token);
  }
}
