package mx.edu.uae.api.identity;

import java.util.Set;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Component
public class IdentitySchema {
    private final String emailColumn;
    private final boolean activeUsers;
    private final boolean activeRoles;

    public IdentitySchema(JdbcTemplate db) {
        Set<String> users = Set.copyOf(db.queryForList("""
            SELECT column_name FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = 'usuarios'
            """, String.class));
        Set<String> roles = Set.copyOf(db.queryForList("""
            SELECT column_name FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = 'roles'
            """, String.class));
        if (users.contains("correo_institucional")) {
            emailColumn = "correo_institucional";
        } else if (users.contains("email")) {
            emailColumn = "email";
        } else {
            throw new IllegalStateException("La tabla usuarios no tiene una columna de correo compatible.");
        }
        if (!users.containsAll(Set.of("id_usuario", "password_hash")) || !roles.contains("codigo")) {
            throw new IllegalStateException("El esquema de identidad no es compatible.");
        }
        activeUsers = users.contains("activo");
        activeRoles = roles.contains("activo");
    }

    String emailColumn() { return emailColumn; }
    String userActiveFilter() { return activeUsers ? " AND u.activo = true" : ""; }
    String roleActiveFilter() { return activeRoles ? " AND r.activo = true" : ""; }
}
