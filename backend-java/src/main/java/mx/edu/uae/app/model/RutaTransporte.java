package mx.edu.uae.app.model;

import java.time.LocalTime;

public class RutaTransporte {
    private final long id;
    private final String nombreRuta;
    private final LocalTime horarioSalida;
    private final String estatus;

    public RutaTransporte(long id, String nombreRuta, LocalTime horarioSalida, String estatus) {
        this.id = id;
        this.nombreRuta = nombreRuta;
        this.horarioSalida = horarioSalida;
        this.estatus = estatus;
    }

    public long getId() { return id; }
    public String getNombreRuta() { return nombreRuta; }
    public LocalTime getHorarioSalida() { return horarioSalida; }
    public String getEstatus() { return estatus; }
}
