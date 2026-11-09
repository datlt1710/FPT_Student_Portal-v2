package com.fpt.accessportal.security;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

/** Verifies Google JWT signature, issuer, expiry, and OAuth audience on the server. */
@Component
public class GoogleIdentityVerifier {
  private final GoogleIdTokenVerifier verifier;

  public record Identity(String subject, String email) {}

  public GoogleIdentityVerifier(@Value("${google.web.client-id:}") String googleClientId) {
    String clientId = googleClientId.trim();
    this.verifier =
        clientId.isBlank()
            ? null
            : new GoogleIdTokenVerifier.Builder(
                    new NetHttpTransport(), GsonFactory.getDefaultInstance())
                .setAudience(List.of(clientId))
                .build();
  }

  public boolean isConfigured() {
    return verifier != null;
  }

  public Identity verify(String idToken) {
    if (verifier == null) {
      throw new ResponseStatusException(
          HttpStatus.SERVICE_UNAVAILABLE, "Chưa cấu hình GOOGLE_WEB_CLIENT_ID trên backend");
    }
    try {
      GoogleIdToken token = verifier.verify(idToken);
      if (token == null || token.getPayload() == null) {
        throw new ResponseStatusException(
            HttpStatus.UNAUTHORIZED, "Google ID token không hợp lệ hoặc hết hạn");
      }
      GoogleIdToken.Payload payload = token.getPayload();
      String email = payload.getEmail();
      String sub = payload.getSubject();
      if (!Boolean.TRUE.equals(payload.getEmailVerified())
          || email == null
          || email.isBlank()
          || sub == null
          || sub.isBlank()) {
        throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Google chưa xác minh email");
      }
      return new Identity(sub, email.trim());
    } catch (GeneralSecurityException | IOException e) {
      throw new ResponseStatusException(
          HttpStatus.UNAUTHORIZED, "Không thể xác thực Google ID token", e);
    }
  }
}
