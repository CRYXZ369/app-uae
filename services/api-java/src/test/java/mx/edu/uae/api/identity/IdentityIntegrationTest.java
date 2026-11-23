package mx.edu.uae.api.identity;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.Base64;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
@EnabledIfEnvironmentVariable(named = "RUN_IDENTITY_DB_TESTS", matches = "true")
class IdentityIntegrationTest {
    @Autowired MockMvc mvc;
    @Autowired JdbcTemplate db;
    @Autowired ObjectMapper json;

    @Test
    void loginRolesRevocationAndExpiration() throws Exception {
        String password = "clave-ficticia-de-prueba";
        byte[] salt = new byte[16];
        byte[] key = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256")
            .generateSecret(new PBEKeySpec(password.toCharArray(), salt, 210_000, 256)).getEncoded();
        String hash = "pbkdf2_sha256$210000$" + Base64.getEncoder().encodeToString(salt)
            + "$" + Base64.getEncoder().encodeToString(key);
        for (String role : new String[] {"ESTUDIANTE", "DOCENTE"}) {
            long id = db.queryForObject("""
                INSERT INTO usuarios (nombre_completo,email,password_hash,rol)
                VALUES (?, ?, ?, ?) RETURNING id_usuario
                """, Long.class, "Cuenta ficticia", role.toLowerCase() + "@uae.edu.mx", hash, role);
            long roleId = db.queryForObject("INSERT INTO roles (codigo,nombre) VALUES (?,?) RETURNING id_rol",
                Long.class, role, role);
            db.update("INSERT INTO usuario_roles (id_usuario,id_rol) VALUES (?,?)", id, roleId);
            String body = json.writeValueAsString(new IdentityController.LoginRequest(role.toLowerCase() + "@uae.edu.mx", password));
            String content = mvc.perform(post("/api/v1/sessions").contentType("application/json").content(body))
                .andExpect(status().isOk()).andExpect(header().string("Cache-Control", "no-store"))
                .andReturn().getResponse().getContentAsString();
            JsonNode result = json.readTree(content);
            String token = result.get("accessToken").asText();
            assertEquals(role, result.get("roles").get(0).asText());
            assertEquals(1, db.queryForObject("SELECT count(*) FROM sesiones_identidad WHERE id_usuario = ?", Integer.class, id));
            mvc.perform(get("/api/v1/sessions/current").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk()).andExpect(jsonPath("$.roles[0]").value(role));
            mvc.perform(post("/api/v1/sessions/current/revoke").header("Authorization", "Bearer " + token))
                .andExpect(status().isNoContent());
            mvc.perform(get("/api/v1/sessions/current").header("Authorization", "Bearer " + token))
                .andExpect(status().isUnauthorized());
        }
        mvc.perform(post("/api/v1/sessions").contentType("application/json")
            .content("{\"email\":\"nadie@uae.edu.mx\",\"password\":\"incorrecta\"}"))
            .andExpect(status().isUnauthorized());
        mvc.perform(post("/api/v1/sessions").contentType("application/json")
            .content("{\"email\":\"estudiante@uae.edu.mx\",\"password\":\"incorrecta\"}"))
            .andExpect(status().isUnauthorized());

        String body = json.writeValueAsString(new IdentityController.LoginRequest("estudiante@uae.edu.mx", password));
        String content = mvc.perform(post("/api/v1/sessions").contentType("application/json").content(body))
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        String expired = json.readTree(content).get("accessToken").asText();
        db.update("UPDATE sesiones_identidad SET creada_en = now() - interval '2 hours', expira_en = now() - interval '1 hour'");
        mvc.perform(get("/api/v1/sessions/current").header("Authorization", "Bearer " + expired))
            .andExpect(status().isUnauthorized());
    }
}
