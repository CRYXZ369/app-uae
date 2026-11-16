package mx.edu.uae.app.model;

import java.time.LocalDateTime;

public class AlertaSalud {
    private final long id;
    private final long idUsuario;
    private final String tipoEmergencia;
    private final String ubicacionCampus;
    private final String descripcion;
    private final String estado;
    private final LocalDateTime fechaHora;

    public AlertaSalud(long id, long idUsuario, String tipoEmergencia, String ubicacionCampus,
                       String descripcion, String estado, LocalDateTime fechaHora) {
        this.id = id;
        this.idUsuario = idUsuario;
        this.tipoEmergencia = tipoEmergencia;
        this.ubicacionCampus = ubicacionCampus;
        this.descripcion = descripcion;
        this.estado = estado;
        this.fechaHora = fechaHora;
    }

    public long getId() { return id; }
    public long getIdUsuario() { return idUsuario; }
    public String getTipoEmergencia() { return tipoEmergencia; }
    public String getUbicacionCampus() { return ubicacionCampus; }
    public String getDescripcion() { return descripcion; }
    public String getEstado() { return estado; }
    public LocalDateTime getFechaHora() { return fechaHora; }
}
