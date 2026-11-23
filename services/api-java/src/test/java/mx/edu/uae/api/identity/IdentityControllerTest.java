package mx.edu.uae.api.identity;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import java.security.SecureRandom;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Base64;
import java.util.List;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockHttpServletRequest;

class IdentityControllerTest {
    private static String hash(String password) throws Exception {
        byte[] salt = new byte[16];
        new SecureRandom().nextBytes(salt);
        PBEKeySpec spec = new PBEKeySpec(password.toCharArray(), salt, 210_000, 256);
        return "pbkdf2_sha256$210000$" + Base64.getEncoder().encodeToString(salt) + "$" +
            Base64.getEncoder().encodeToString(SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256")
                .generateSecret(spec).getEncoded());
    }

    @Test
    void verifierAcceptsLegacyHashAndRejectsBadPassword() throws Exception {
        PasswordVerifier verifier = new PasswordVerifier();
        String encoded = hash("prueba-ficticia");
        assertTrue(verifier.verify("prueba-ficticia".toCharArray(), encoded));
        assertFalse(verifier.verify("incorrecta".toCharArray(), encoded));
        assertFalse(verifier.verify("prueba-ficticia".toCharArray(), "invalido"));
    }

    @Test
    void limitsAttemptsPerAddress() {
        LoginRateLimiter limiter = new LoginRateLimiter(Clock.fixed(Instant.EPOCH, ZoneOffset.UTC));
        for (int i = 0; i < 10; i++) assertTrue(limiter.allow("127.0.0.1"));
        assertFalse(limiter.allow("127.0.0.1"));
        assertTrue(limiter.allow("127.0.0.2"));
    }

    @Test
    void noUserDoesNotAuthenticate() throws Exception {
        JdbcTemplate db = mock(JdbcTemplate.class);
        when(db.query(anyString(), any(org.springframework.jdbc.core.RowMapper.class), any(Object.class)))
            .thenReturn(List.of());
        IdentityController controller = new IdentityController(db, new PasswordVerifier(), new LoginRateLimiter());
        var result = controller.login(new IdentityController.LoginRequest("ausente@uae.edu.mx", "prueba"),
            new MockHttpServletRequest());
        assertEquals(HttpStatus.UNAUTHORIZED, result.getStatusCode());
        verify(db, never()).update(anyString(), any(), any(), any());
    }
}
