package mx.edu.uae.app.dao;

import java.sql.SQLException;
import java.util.List;
import mx.edu.uae.app.model.Votacion;

public interface VotacionDAO {
    List<Votacion> listarVigentes() throws SQLException;
    boolean registrarVoto(long idVotacion, long idUsuario, long idOpcion) throws SQLException;
}
