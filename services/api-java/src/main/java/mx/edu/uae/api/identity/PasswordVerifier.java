package mx.edu.uae.api.identity;

import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.util.Base64;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class PasswordVerifier {
    private final BCryptPasswordEncoder bcrypt = new BCryptPasswordEncoder();

    public boolean verify(char[] password, String encoded) throws GeneralSecurityException {
        if (encoded == null) return false;
        if (encoded.matches("^\\$2[aby]\\$(0[4-9]|1[0-4])\\$[./A-Za-z0-9]{53}$")) {
            return bcrypt.matches(new String(password), encoded);
        }
        String[] parts = encoded.split("\\$", -1);
        if (parts.length != 4 || !parts[0].equals("pbkdf2_sha256")) return false;
        try {
            int iterations = Integer.parseInt(parts[1]);
            byte[] salt = Base64.getDecoder().decode(parts[2]);
            byte[] expected = Base64.getDecoder().decode(parts[3]);
            if (iterations < 210_000 || iterations > 1_000_000 || salt.length != 16 || expected.length != 32) {
                return false;
            }
            PBEKeySpec spec = new PBEKeySpec(password, salt, iterations, 256);
            try {
                byte[] actual = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256").generateSecret(spec).getEncoded();
                return MessageDigest.isEqual(expected, actual);
            } finally {
                spec.clearPassword();
            }
        } catch (IllegalArgumentException ex) {
            return false;
        }
    }
}
