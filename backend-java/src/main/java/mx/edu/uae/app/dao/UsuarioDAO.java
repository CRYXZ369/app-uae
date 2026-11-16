package mx.edu.uae.app.dao;

import java.security.GeneralSecurityException;
import java.sql.SQLException;
import java.util.Optional;
import mx.edu.uae.app.model.Usuario;

public interface UsuarioDAO {
    Optional<Usuario> login(String email, char[] password) throws SQLException, GeneralSecurityException;
}
