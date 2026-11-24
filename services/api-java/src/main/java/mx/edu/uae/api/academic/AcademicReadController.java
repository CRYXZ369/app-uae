package mx.edu.uae.api.academic;

import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.time.LocalDate;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/academic")
public class AcademicReadController {
    private final JdbcTemplate db;
    public AcademicReadController(JdbcTemplate db) { this.db = db; }

    record AttendanceMark(Long idHorario, Long idEstudiante, LocalDate fecha, String estado) {}

    @GetMapping("/profile")
    public ResponseEntity<?> profile(@RequestHeader(value = HttpHeaders.AUTHORIZATION, required = false) String auth)
            throws GeneralSecurityException {
        Long id = userId(auth);
        if (id == null) return error(HttpStatus.UNAUTHORIZED, "INVALID_SESSION");
        return ResponseEntity.ok(db.queryForList("""
            SELECT u.nombre, u.apellidos, u.correo_institucional AS correo,
                   COALESCE(c.nombre, '') AS carrera, COALESCE(g.nombre, '') AS grupo,
                   COALESCE(g.semestre, 0) AS semestre,
                   COALESCE((SELECT jsonb_agg(r.codigo ORDER BY r.codigo)::text
                     FROM usuario_roles ur JOIN roles r ON r.id_rol=ur.id_rol
                     WHERE ur.id_usuario=u.id_usuario), '[]') AS roles
            FROM usuarios u LEFT JOIN grupos g ON g.id_grupo=u.id_grupo
            LEFT JOIN carreras c ON c.id_carrera=g.id_carrera WHERE u.id_usuario=?
            """, id));
    }

    @GetMapping("/subjects")
    public ResponseEntity<?> subjects(@RequestHeader(value = HttpHeaders.AUTHORIZATION, required = false) String auth)
            throws GeneralSecurityException {
        Long id = studentId(auth);
        if (id == null) return error(HttpStatus.UNAUTHORIZED, "INVALID_SESSION");
        if (id < 0) return error(HttpStatus.FORBIDDEN, "STUDENT_ROLE_REQUIRED");
        return ResponseEntity.ok(db.queryForList("""
            SELECT m.codigo, m.nombre AS materia, g.nombre AS grupo,
                   g.semestre, d.nombre_completo AS docente
            FROM usuarios u JOIN grupos g ON g.id_grupo=u.id_grupo
            JOIN grupo_materias_docentes gm ON gm.id_grupo=g.id_grupo
            JOIN materias m ON m.id_materia=gm.id_materia
            JOIN docentes d ON d.id_docente=gm.id_docente
            WHERE u.id_usuario=? ORDER BY m.nombre
            """, id));
    }

    @GetMapping("/schedule")
    public ResponseEntity<?> schedule(@RequestHeader(value = HttpHeaders.AUTHORIZATION, required = false) String auth)
            throws GeneralSecurityException {
        Long id = studentId(auth);
        if (id == null) return error(HttpStatus.UNAUTHORIZED, "INVALID_SESSION");
        if (id < 0) return error(HttpStatus.FORBIDDEN, "STUDENT_ROLE_REQUIRED");
        return ResponseEntity.ok(db.queryForList("""
            SELECT h.dia_semana AS dia, h.hora_inicio, h.hora_fin,
                   COALESCE(m.nombre, t.nombre) AS actividad,
                   d.nombre_completo AS docente, a.nombre AS aula
            FROM usuarios u JOIN horarios_academicos h ON h.id_grupo=u.id_grupo
            LEFT JOIN materias m ON m.id_materia=h.id_materia
            LEFT JOIN talleres t ON t.id_taller=h.id_taller
            JOIN docentes d ON d.id_docente=h.id_docente
            JOIN aulas a ON a.id_aula=h.id_aula
            WHERE u.id_usuario=? ORDER BY h.dia_semana,h.hora_inicio
            """, id));
    }

    @GetMapping("/tasks")
    public ResponseEntity<?> tasks(@RequestHeader(value = HttpHeaders.AUTHORIZATION, required = false) String auth)
            throws GeneralSecurityException {
        Long id = studentId(auth);
        if (id == null) return error(HttpStatus.UNAUTHORIZED, "INVALID_SESSION");
        if (id < 0) return error(HttpStatus.FORBIDDEN, "STUDENT_ROLE_REQUIRED");
        return ResponseEntity.ok(db.queryForList("""
            SELECT id_tarea, titulo, descripcion, materia, docente, fecha_entrega,
                   prioridad, estado, entrega_tardia
            FROM vista_tareas_estudiante WHERE id_usuario=?
            ORDER BY fecha_entrega, titulo
            """, id));
    }

    @GetMapping("/attendance")
    public ResponseEntity<?> attendance(@RequestHeader(value = HttpHeaders.AUTHORIZATION, required = false) String auth)
            throws GeneralSecurityException {
        Long id = userId(auth);
        if (id == null) return error(HttpStatus.UNAUTHORIZED, "INVALID_SESSION");
        if (hasRole(id, "ESTUDIANTE")) return ResponseEntity.ok(db.queryForList("""
            SELECT a.fecha_clase, a.estado,
                   COALESCE(m.nombre, t.nombre) AS actividad,
                   h.dia_semana AS dia, h.hora_inicio, h.hora_fin,
                   a.registrada_en
            FROM asistencias_academicas a
            JOIN horarios_academicos h ON h.id_horario=a.id_horario
            LEFT JOIN materias m ON m.id_materia=h.id_materia
            LEFT JOIN talleres t ON t.id_taller=h.id_taller
            WHERE a.id_usuario=?
            ORDER BY a.fecha_clase DESC, h.hora_inicio DESC
            LIMIT 100
            """, id));
        if (hasRole(id, "DOCENTE")) return ResponseEntity.ok(db.queryForList("""
            SELECT h.id_horario, h.dia_semana AS dia, h.hora_inicio, h.hora_fin,
                   COALESCE(m.nombre, t.nombre) AS actividad, g.nombre AS grupo,
                   count(DISTINCT u.id_usuario) FILTER (WHERE r.codigo='ESTUDIANTE') AS alumnos
            FROM docentes d JOIN horarios_academicos h ON h.id_docente=d.id_docente
            JOIN grupos g ON g.id_grupo=h.id_grupo
            LEFT JOIN materias m ON m.id_materia=h.id_materia
            LEFT JOIN talleres t ON t.id_taller=h.id_taller
            LEFT JOIN usuarios u ON u.id_grupo=g.id_grupo
            LEFT JOIN usuario_roles ur ON ur.id_usuario=u.id_usuario
            LEFT JOIN roles r ON r.id_rol=ur.id_rol
            WHERE d.id_usuario=?
            GROUP BY h.id_horario,h.dia_semana,h.hora_inicio,h.hora_fin,m.nombre,t.nombre,g.nombre
            ORDER BY h.dia_semana,h.hora_inicio
            """, id));
        return error(HttpStatus.FORBIDDEN, "ATTENDANCE_ROLE_REQUIRED");
    }

    @GetMapping("/attendance/roster")
    public ResponseEntity<?> attendanceRoster(
            @RequestHeader(value = HttpHeaders.AUTHORIZATION, required = false) String auth,
            @RequestParam long scheduleId,
            @RequestParam(required = false) LocalDate date) throws GeneralSecurityException {
        Long id = userId(auth);
        if (id == null) return error(HttpStatus.UNAUTHORIZED, "INVALID_SESSION");
        if (!hasRole(id, "DOCENTE")) return error(HttpStatus.FORBIDDEN, "TEACHER_ROLE_REQUIRED");
        LocalDate classDate = date == null ? LocalDate.now() : date;
        boolean assigned = Boolean.TRUE.equals(db.queryForObject("""
            SELECT EXISTS(SELECT 1 FROM horarios_academicos h JOIN docentes d ON d.id_docente=h.id_docente
              WHERE h.id_horario=? AND d.id_usuario=?)
            """, Boolean.class, scheduleId, id));
        if (!assigned) return error(HttpStatus.FORBIDDEN, "SCHEDULE_NOT_ASSIGNED");
        return ResponseEntity.ok(db.queryForList("""
            SELECT u.id_usuario, u.nombre || ' ' || u.apellidos AS estudiante,
                   COALESCE(a.estado, 'SIN_REGISTRO') AS estado
            FROM horarios_academicos h JOIN usuarios u ON u.id_grupo=h.id_grupo AND u.activo=true
            JOIN usuario_roles ur ON ur.id_usuario=u.id_usuario
            JOIN roles r ON r.id_rol=ur.id_rol AND r.codigo='ESTUDIANTE' AND r.activo=true
            LEFT JOIN asistencias_academicas a ON a.id_horario=h.id_horario
              AND a.id_usuario=u.id_usuario AND a.fecha_clase=?
            WHERE h.id_horario=? ORDER BY u.apellidos,u.nombre
            """, classDate, scheduleId));
    }

    @PostMapping("/attendance")
    public ResponseEntity<?> markAttendance(
            @RequestHeader(value = HttpHeaders.AUTHORIZATION, required = false) String auth,
            @RequestBody AttendanceMark mark) throws GeneralSecurityException {
        Long id = userId(auth);
        if (id == null) return error(HttpStatus.UNAUTHORIZED, "INVALID_SESSION");
        if (!hasRole(id, "DOCENTE")) return error(HttpStatus.FORBIDDEN, "TEACHER_ROLE_REQUIRED");
        if (mark == null || mark.idHorario() == null || mark.idEstudiante() == null || mark.fecha() == null ||
            mark.estado() == null ||
            !List.of("PRESENTE", "RETARDO", "FALTA", "JUSTIFICADO").contains(mark.estado())) {
            return error(HttpStatus.BAD_REQUEST, "INVALID_ATTENDANCE");
        }
        boolean assigned = Boolean.TRUE.equals(db.queryForObject("""
            SELECT EXISTS(SELECT 1 FROM horarios_academicos h JOIN docentes d ON d.id_docente=h.id_docente
              WHERE h.id_horario=? AND d.id_usuario=?)
            """, Boolean.class, mark.idHorario(), id));
        if (!assigned) return error(HttpStatus.FORBIDDEN, "SCHEDULE_NOT_ASSIGNED");
        if (mark.fecha().isAfter(LocalDate.now())) {
            return error(HttpStatus.BAD_REQUEST, "ATTENDANCE_DATE_IN_FUTURE");
        }
        String scheduledDay = db.queryForObject(
            "SELECT dia_semana FROM horarios_academicos WHERE id_horario=?",
            String.class, mark.idHorario());
        int weekday = switch (scheduledDay) {
            case "Lunes" -> 1;
            case "Martes" -> 2;
            case "Miércoles" -> 3;
            case "Jueves" -> 4;
            case "Viernes" -> 5;
            default -> 0;
        };
        if (mark.fecha().getDayOfWeek().getValue() != weekday) {
            return error(HttpStatus.BAD_REQUEST, "ATTENDANCE_DATE_MISMATCH");
        }
        db.update("""
            INSERT INTO asistencias_academicas(id_horario,id_usuario,fecha_clase,estado,registrada_por)
            VALUES (?,?,?,?,?)
            ON CONFLICT (id_horario,id_usuario,fecha_clase) DO UPDATE
              SET estado=EXCLUDED.estado,registrada_por=EXCLUDED.registrada_por
            """, mark.idHorario(), mark.idEstudiante(), mark.fecha(), mark.estado(), id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/notifications")
    public ResponseEntity<?> notifications(@RequestHeader(value = HttpHeaders.AUTHORIZATION, required = false) String auth)
            throws GeneralSecurityException {
        Long id = userId(auth);
        if (id == null) return error(HttpStatus.UNAUTHORIZED, "INVALID_SESSION");
        return ResponseEntity.ok(db.queryForList("""
            SELECT tipo, titulo, mensaje, creada_en, (leida_en IS NOT NULL) AS leida
            FROM notificaciones WHERE id_usuario=? ORDER BY creada_en DESC LIMIT 100
            """, id));
    }

    private Long studentId(String auth) throws GeneralSecurityException {
        Long id = userId(auth);
        if (id == null) return null;
        return hasRole(id, "ESTUDIANTE") ? id : -1L;
    }

    private boolean hasRole(long id, String role) {
        return Boolean.TRUE.equals(db.queryForObject("""
            SELECT EXISTS(SELECT 1 FROM usuario_roles ur JOIN roles r ON r.id_rol=ur.id_rol
              WHERE ur.id_usuario=? AND r.codigo=? AND r.activo=true)
            """, Boolean.class, id, role));
    }

    private Long userId(String auth) throws GeneralSecurityException {
        if (auth == null || !auth.startsWith("Bearer ")) return null;
        String token = auth.substring(7);
        if (!token.matches("[A-Za-z0-9_-]{43}")) return null;
        byte[] hash = MessageDigest.getInstance("SHA-256").digest(token.getBytes(StandardCharsets.US_ASCII));
        List<Long> ids = db.query("""
            SELECT s.id_usuario FROM sesiones_identidad s JOIN usuarios u ON u.id_usuario=s.id_usuario
            WHERE s.token_hash=? AND s.expira_en>now() AND u.activo=true
            """, (rs, row) -> rs.getLong(1), hash);
        return ids.isEmpty() ? null : ids.get(0);
    }

    private static ResponseEntity<Map<String, String>> error(HttpStatus status, String code) {
        return ResponseEntity.status(status).body(Map.of("code", code));
    }
}
