package mx.edu.uae.app.dao;

import java.security.GeneralSecurityException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Optional;
import java.util.regex.Pattern;
import mx.edu.uae.app.config.DatabaseConnection;
import mx.edu.uae.app.config.PasswordHasher;
import mx.edu.uae.app.model.Usuario;

public class JdbcUsuarioDAO implements UsuarioDAO {
    private static final Pattern EMAIL = Pattern.compile("^[A-Za-z0-9._%+-]+@uae\\.edu\\.mx$", Pattern.CASE_INSENSITIVE);

    @Override
    public Optional<Usuario> login(String email, char[] password) throws SQLException, GeneralSecurityException {
        if (email == null || email.length() > 254 || !EMAIL.matcher(email).matches() || password == null) {
            return Optional.empty();
        }
        String sql = "SELECT id_usuario, nombre_completo, email, password_hash, rol, semestre, grupo "
                + "FROM usuarios WHERE email = ?";
        try (Connection connection = DatabaseConnection.getInstance().getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, email);
            try (ResultSet result = statement.executeQuery()) {
                if (!result.next() || !PasswordHasher.verify(password, result.getString("password_hash"))) {
                    return Optional.empty();
                }
                int semestre = result.getInt("semestre");
                Integer semestreOpcional = result.wasNull() ? null : semestre;
                return Optional.of(new Usuario(result.getLong("id_usuario"), result.getString("nombre_completo"),
                        result.getString("email"), result.getString("rol"), semestreOpcional, result.getString("grupo")));
            }
        }
    }
}
