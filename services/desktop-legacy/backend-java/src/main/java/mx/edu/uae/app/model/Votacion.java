package mx.edu.uae.app.model;

import java.time.LocalDateTime;

public class Votacion {
    private final long id;
    private final String titulo;
    private final String descripcion;
    private final LocalDateTime fechaInicio;
    private final LocalDateTime fechaFin;
    private final boolean activa;

    public Votacion(long id, String titulo, String descripcion, LocalDateTime fechaInicio,
                    LocalDateTime fechaFin, boolean activa) {
        this.id = id;
        this.titulo = titulo;
        this.descripcion = descripcion;
        this.fechaInicio = fechaInicio;
        this.fechaFin = fechaFin;
        this.activa = activa;
    }

    public long getId() { return id; }
    public String getTitulo() { return titulo; }
    public String getDescripcion() { return descripcion; }
    public LocalDateTime getFechaInicio() { return fechaInicio; }
    public LocalDateTime getFechaFin() { return fechaFin; }
    public boolean isActiva() { return activa; }
}
