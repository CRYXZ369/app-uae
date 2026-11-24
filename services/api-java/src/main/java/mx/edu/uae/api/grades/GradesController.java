package mx.edu.uae.api.grades;

import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/grades")
public class GradesController {
    private final JdbcTemplate db;

    public GradesController(JdbcTemplate db) { this.db = db; }

    @GetMapping("/courses")
    public ResponseEntity<?> courses(@RequestHeader(value = HttpHeaders.AUTHORIZATION, required = false) String authorization)
            throws GeneralSecurityException {
        String token = bearer(authorization);
        if (token == null) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("code", "INVALID_SESSION"));
        byte[] tokenHash = MessageDigest.getInstance("SHA-256").digest(token.getBytes(StandardCharsets.US_ASCII));
        List<Long> users = db.query("""
            SELECT s.id_usuario FROM sesiones_identidad s
            JOIN usuarios u ON u.id_usuario = s.id_usuario
            WHERE s.token_hash = ? AND s.expira_en > now() AND u.activo = true
            """, (rs, row) -> rs.getLong(1), tokenHash);
        if (users.isEmpty()) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("code", "INVALID_SESSION"));
        long userId = users.get(0);
        List<String> roles = db.queryForList("""
            SELECT r.codigo FROM usuario_roles ur JOIN roles r ON r.id_rol = ur.id_rol
            WHERE ur.id_usuario = ? AND r.activo = true
            """, String.class, userId);
        if (!roles.contains("ESTUDIANTE")) return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("code", "STUDENT_ROLE_REQUIRED"));
        List<Map<String, Object>> result = db.queryForList("""
            SELECT p.id_plan, p.codigo_materia, p.materia, p.ponderacion_total,
                   p.progreso_curso, p.entregables_totales, p.entregables_calificados,
                   p.promedio_estimado, p.plan_completo, p.escala_maxima,
                   COALESCE(jsonb_agg(jsonb_build_object(
                     'name', e.entregable,
                     'weightPercentage', e.peso_porcentual,
                     'grade', e.calificacion
                   ) ORDER BY e.id_evaluacion) FILTER (WHERE e.id_evaluacion IS NOT NULL), '[]'::jsonb)::text AS assessments
            FROM vista_progreso_calificaciones_estudiante p
            LEFT JOIN vista_evaluaciones_estudiante e ON e.id_plan = p.id_plan AND e.id_usuario = p.id_usuario
            WHERE p.id_usuario = ?
            GROUP BY p.id_plan, p.codigo_materia, p.materia, p.ponderacion_total,
                     p.progreso_curso, p.entregables_totales, p.entregables_calificados,
                     p.promedio_estimado, p.plan_completo, p.escala_maxima
            ORDER BY p.materia
            """, userId);
        return ResponseEntity.ok().cacheControl(org.springframework.http.CacheControl.noStore()).body(result);
    }

    private static String bearer(String header) {
        if (header == null || !header.startsWith("Bearer ")) return null;
        String token = header.substring(7);
        return token.matches("[A-Za-z0-9_-]{43}") ? token : null;
    }
}
