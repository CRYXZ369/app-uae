package mx.edu.uae.api.identity;

import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Arrays;
import java.util.Base64;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.transaction.annotation.Transactional;

@RestController
@RequestMapping("/api/v1/sessions")
public class IdentityController {
    private static final String DUMMY_HASH =
        "pbkdf2_sha256$210000$AAAAAAAAAAAAAAAAAAAAAA==$AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    private final JdbcTemplate db;
    private final PasswordVerifier verifier;
    private final LoginRateLimiter limiter;
    private final IdentitySchema schema;
    private final SecureRandom random = new SecureRandom();

    public IdentityController(JdbcTemplate db, PasswordVerifier verifier, LoginRateLimiter limiter, IdentitySchema schema) {
        this.db = db;
        this.verifier = verifier;
        this.limiter = limiter;
        this.schema = schema;
    }

    record LoginRequest(String email, String password) {}
    record User(long id, String email, String hash) {}
    record LoginResponse(String accessToken, String email, Instant expiresAt, List<String> roles) {}
    record IdentityResponse(String email, List<String> roles) {}

    @PostMapping
    @Transactional
    public ResponseEntity<?> login(@RequestBody LoginRequest request, HttpServletRequest httpRequest) throws GeneralSecurityException {
        if (!limiter.allow(httpRequest.getRemoteAddr())) return error(HttpStatus.TOO_MANY_REQUESTS, "RATE_LIMITED");
        if (request.email() == null || request.password() == null ||
            request.email().length() > 254 || request.password().isEmpty() || request.password().length() > 1024) {
            return error(HttpStatus.BAD_REQUEST, "INVALID_REQUEST");
        }
        String email = request.email().strip().toLowerCase(Locale.ROOT);
        List<User> users = db.query(
            "SELECT u.id_usuario, u." + schema.emailColumn() + ", u.password_hash FROM public.usuarios u WHERE lower(u."
                + schema.emailColumn() + ") = ?" + schema.userActiveFilter(),
            (row, n) -> new User(row.getLong(1), row.getString(2), row.getString(3)), email);
        Optional<User> user = users.stream().findFirst();
        char[] password = request.password().toCharArray();
        boolean valid;
        try {
            valid = verifier.verify(password, user.map(User::hash).orElse(DUMMY_HASH));
        } finally {
            Arrays.fill(password, '\0');
        }
        if (!valid || user.isEmpty()) return error(HttpStatus.UNAUTHORIZED, "INVALID_CREDENTIALS");
        User authenticated = user.orElseThrow();
        byte[] bytes = new byte[32];
        random.nextBytes(bytes);
        String token = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
        Instant expires = Instant.now().plus(1, ChronoUnit.HOURS);
        db.update("INSERT INTO sesiones_identidad (token_hash, id_usuario, expira_en) VALUES (?, ?, ?)",
            digest(token), authenticated.id(), Timestamp.from(expires));
        return ResponseEntity.ok().cacheControl(org.springframework.http.CacheControl.noStore())
            .body(new LoginResponse(token, authenticated.email(), expires, roles(authenticated.id())));
    }

    @GetMapping("/current")
    public ResponseEntity<?> current(@RequestHeader(value = HttpHeaders.AUTHORIZATION, required = false) String authorization)
            throws GeneralSecurityException {
        String token = bearer(authorization);
        if (token == null) return error(HttpStatus.UNAUTHORIZED, "INVALID_SESSION");
        String sql = "SELECT u.id_usuario, u." + schema.emailColumn()
            + ", '' AS password_hash FROM sesiones_identidad s "
            + "JOIN public.usuarios u ON u.id_usuario = s.id_usuario "
            + "WHERE s.token_hash = ? AND s.expira_en > now()" + schema.userActiveFilter();
        List<User> users = db.query(sql,
            (row, n) -> new User(row.getLong(1), row.getString(2), row.getString(3)), digest(token));
        if (users.isEmpty()) return error(HttpStatus.UNAUTHORIZED, "INVALID_SESSION");
        User user = users.get(0);
        return ResponseEntity.ok().cacheControl(org.springframework.http.CacheControl.noStore())
            .body(new IdentityResponse(user.email(), roles(user.id())));
    }

    @PostMapping("/current/revoke")
    public ResponseEntity<?> revoke(@RequestHeader(value = HttpHeaders.AUTHORIZATION, required = false) String authorization)
            throws GeneralSecurityException {
        String token = bearer(authorization);
        if (token == null) return error(HttpStatus.UNAUTHORIZED, "INVALID_SESSION");
        db.update("DELETE FROM sesiones_identidad WHERE token_hash = ?", digest(token));
        return ResponseEntity.noContent().build();
    }

    private List<String> roles(long id) {
        return db.queryForList(
            "SELECT r.codigo FROM public.roles r JOIN public.usuario_roles ur ON ur.id_rol = r.id_rol "
            + "WHERE ur.id_usuario = ?" + schema.roleActiveFilter() + " ORDER BY r.codigo", String.class, id);
    }

    private static String bearer(String header) {
        if (header == null || !header.startsWith("Bearer ")) return null;
        String token = header.substring(7);
        return token.matches("[A-Za-z0-9_-]{43}") ? token : null;
    }

    private static byte[] digest(String token) throws GeneralSecurityException {
        return MessageDigest.getInstance("SHA-256").digest(token.getBytes(StandardCharsets.US_ASCII));
    }

    private static ResponseEntity<Map<String, String>> error(HttpStatus status, String code) {
        return ResponseEntity.status(status).cacheControl(org.springframework.http.CacheControl.noStore())
            .body(Map.of("code", code));
    }
}
