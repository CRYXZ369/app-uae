package mx.edu.uae.app.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import mx.edu.uae.app.config.DatabaseConnection;
import mx.edu.uae.app.model.Votacion;

public class JdbcVotacionDAO implements VotacionDAO {
    @Override
    public List<Votacion> listarVigentes() throws SQLException {
        List<Votacion> votaciones = new ArrayList<>();
        String sql = "SELECT id_votacion, titulo, descripcion, fecha_inicio, fecha_fin, activa FROM votaciones "
                + "WHERE activa = TRUE AND CURRENT_TIMESTAMP >= fecha_inicio AND CURRENT_TIMESTAMP < fecha_fin";
        try (Connection connection = DatabaseConnection.getInstance().getConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet result = statement.executeQuery()) {
            while (result.next()) {
                votaciones.add(new Votacion(result.getLong("id_votacion"), result.getString("titulo"),
                        result.getString("descripcion"), result.getTimestamp("fecha_inicio").toLocalDateTime(),
                        result.getTimestamp("fecha_fin").toLocalDateTime(), result.getBoolean("activa")));
            }
        }
        return votaciones;
    }

    @Override
    public boolean registrarVoto(long idVotacion, long idUsuario, long idOpcion) throws SQLException {
        String sql = "INSERT INTO votos_usuarios (id_votacion, id_usuario, id_opcion) "
                + "SELECT v.id_votacion, ?, o.id_opcion FROM votaciones v "
                + "JOIN opciones_votacion o ON o.id_votacion = v.id_votacion "
                + "WHERE v.id_votacion = ? AND o.id_opcion = ? AND v.activa = TRUE "
                + "AND CURRENT_TIMESTAMP >= v.fecha_inicio AND CURRENT_TIMESTAMP < v.fecha_fin";
        try (Connection connection = DatabaseConnection.getInstance().getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setLong(1, idUsuario);
            statement.setLong(2, idVotacion);
            statement.setLong(3, idOpcion);
            return statement.executeUpdate() == 1;
        }
    }
}
