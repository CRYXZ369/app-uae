package mx.edu.uae.app.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import mx.edu.uae.app.config.DatabaseConnection;
import mx.edu.uae.app.model.Producto;

public class JdbcCafeteriaDAO implements CafeteriaDAO {
    @Override
    public List<Producto> listarProductos() throws SQLException {
        List<Producto> productos = new ArrayList<>();
        try (Connection connection = DatabaseConnection.getInstance().getConnection();
             PreparedStatement statement = connection.prepareStatement(
                     "SELECT id_producto, id_categoria, nombre, precio, stock FROM productos ORDER BY nombre");
             ResultSet result = statement.executeQuery()) {
            while (result.next()) {
                productos.add(new Producto(result.getLong("id_producto"), result.getLong("id_categoria"),
                        result.getString("nombre"), result.getBigDecimal("precio"), result.getInt("stock")));
            }
        }
        return productos;
    }
}
