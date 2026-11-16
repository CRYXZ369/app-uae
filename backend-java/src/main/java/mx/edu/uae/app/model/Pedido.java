package mx.edu.uae.app.model;

import java.time.LocalDateTime;

public class Pedido {
    private final long id;
    private final long idUsuario;
    private final LocalDateTime fechaHora;
    private final String estado;

    public Pedido(long id, long idUsuario, LocalDateTime fechaHora, String estado) {
        this.id = id;
        this.idUsuario = idUsuario;
        this.fechaHora = fechaHora;
        this.estado = estado;
    }

    public long getId() { return id; }
    public long getIdUsuario() { return idUsuario; }
    public LocalDateTime getFechaHora() { return fechaHora; }
    public String getEstado() { return estado; }
}
