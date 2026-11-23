package mx.edu.uae.api.identity;

import static org.junit.jupiter.api.Assertions.*;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.Base64;
import java.util.UUID;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.jdbc.core.JdbcTemplate;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@EnabledIfEnvironmentVariable(named = "RUN_IDENTITY_DB_TESTS", matches = "true")
class IdentityHttpIntegrationTest {
    @LocalServerPort int port;
    @Autowired JdbcTemplate db;
    @Autowired ObjectMapper json;

    @Test
    void actualHttpLoginAndRevocation() throws Exception {
        String password = "clave-ficticia-de-prueba";
        byte[] salt = new byte[16];
        byte[] key = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256")
            .generateSecret(new PBEKeySpec(password.toCharArray(), salt, 210_000, 256)).getEncoded();
        String hash = "pbkdf2_sha256$210000$" + Base64.getEncoder().encodeToString(salt)
            + "$" + Base64.getEncoder().encodeToString(key);
        String email = "test-" + UUID.randomUUID() + "@uae.edu.mx";
        long id = db.queryForObject("""
            INSERT INTO usuarios (nombre_completo,email,password_hash,rol)
            VALUES (?, ?, ?, ?) RETURNING id_usuario
            """, Long.class, "Cuenta ficticia", email, hash, "ESTUDIANTE");
        try {
            URI endpoint = URI.create("http://127.0.0.1:" + port + "/api/v1/sessions");
            HttpClient client = HttpClient.newHttpClient();
            String body = json.writeValueAsString(new IdentityController.LoginRequest(email, password));
            HttpResponse<String> login = client.send(HttpRequest.newBuilder(endpoint)
                .header("Content-Type", "application/json").POST(HttpRequest.BodyPublishers.ofString(body)).build(),
                HttpResponse.BodyHandlers.ofString());
            assertEquals(200, login.statusCode());
            String token = json.readTree(login.body()).get("accessToken").asText();
            HttpResponse<String> revoke = client.send(HttpRequest.newBuilder(URI.create(endpoint + "/current/revoke"))
                .header("Authorization", "Bearer " + token).POST(HttpRequest.BodyPublishers.noBody()).build(),
                HttpResponse.BodyHandlers.ofString());
            assertEquals(204, revoke.statusCode());
            HttpResponse<String> current = client.send(HttpRequest.newBuilder(URI.create(endpoint + "/current"))
                .header("Authorization", "Bearer " + token).GET().build(), HttpResponse.BodyHandlers.ofString());
            assertEquals(401, current.statusCode());
        } finally {
            db.update("DELETE FROM usuarios WHERE id_usuario = ?", id);
        }
    }
}
