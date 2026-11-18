package mx.edu.uae.app.model;

public class Usuario {
    private final long id;
    private final String nombreCompleto;
    private final String email;
    private final String rol;
    private final Integer semestre;
    private final String grupo;

    public Usuario(long id, String nombreCompleto, String email, String rol, Integer semestre, String grupo) {
        this.id = id;
        this.nombreCompleto = nombreCompleto;
        this.email = email;
        this.rol = rol;
        this.semestre = semestre;
        this.grupo = grupo;
    }

    public long getId() { return id; }
    public String getNombreCompleto() { return nombreCompleto; }
    public String getEmail() { return email; }
    public String getRol() { return rol; }
    public Integer getSemestre() { return semestre; }
    public String getGrupo() { return grupo; }
}
