package mx.edu.uae.app.model;

import java.math.BigDecimal;

public class Producto {
    private final long id;
    private final long idCategoria;
    private final String nombre;
    private final BigDecimal precio;
    private final int stock;

    public Producto(long id, long idCategoria, String nombre, BigDecimal precio, int stock) {
        this.id = id;
        this.idCategoria = idCategoria;
        this.nombre = nombre;
        this.precio = precio;
        this.stock = stock;
    }

    public long getId() { return id; }
    public long getIdCategoria() { return idCategoria; }
    public String getNombre() { return nombre; }
    public BigDecimal getPrecio() { return precio; }
    public int getStock() { return stock; }
}
