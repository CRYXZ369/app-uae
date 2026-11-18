package mx.edu.uae.app.model;

import java.time.LocalDateTime;

public class Anuncio {
    private final long id;
    private final String titulo;
    private final String contenido;
    private final String categoria;
    private final LocalDateTime fechaPublicacion;
    private final long idAutor;

    public Anuncio(long id, String titulo, String contenido, String categoria,
                   LocalDateTime fechaPublicacion, long idAutor) {
        this.id = id;
        this.titulo = titulo;
        this.contenido = contenido;
        this.categoria = categoria;
        this.fechaPublicacion = fechaPublicacion;
        this.idAutor = idAutor;
    }

    public long getId() { return id; }
    public String getTitulo() { return titulo; }
    public String getContenido() { return contenido; }
    public String getCategoria() { return categoria; }
    public LocalDateTime getFechaPublicacion() { return fechaPublicacion; }
    public long getIdAutor() { return idAutor; }
}
