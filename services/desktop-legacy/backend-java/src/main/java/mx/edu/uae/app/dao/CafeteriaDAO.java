package mx.edu.uae.app.dao;

import java.sql.SQLException;
import java.util.List;
import mx.edu.uae.app.model.Producto;

public interface CafeteriaDAO {
    List<Producto> listarProductos() throws SQLException;
}
