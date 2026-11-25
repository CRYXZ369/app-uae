package mx.edu.uae.api;

import java.net.InetAddress;
import java.net.URI;
import java.util.Arrays;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class DatabaseTlsGuard {
    public DatabaseTlsGuard(@Value("${spring.datasource.url}") String jdbcUrl,
                            @Value("${server.address:127.0.0.1}") String address) {
        if (!isLocalOrPrivateAddress(address)) {
            throw new IllegalArgumentException("Esta API de desarrollo solo admite 127.0.0.1 o direcciones privadas de red local.");
        }
        if (!jdbcUrl.startsWith("jdbc:postgresql://")) {
            throw new IllegalArgumentException("DB_URL debe ser una URL JDBC de PostgreSQL.");
        }
        URI uri = URI.create(jdbcUrl.substring("jdbc:".length()));
        boolean local = "localhost".equals(uri.getHost()) || "127.0.0.1".equals(uri.getHost());
        long sslModes = uri.getRawQuery() == null ? 0 : Arrays.stream(uri.getRawQuery().split("&"))
            .filter(part -> part.toLowerCase(java.util.Locale.ROOT).startsWith("sslmode="))
            .count();
        boolean verified = uri.getRawQuery() != null && Arrays.asList(uri.getRawQuery().split("&"))
            .contains("sslmode=verify-full");
        if (!local && (sslModes != 1 || !verified)) {
            throw new IllegalArgumentException("DB_URL remoto requiere sslmode=verify-full y CA confiable.");
        }
    }

    private static boolean isLocalOrPrivateAddress(String host) {
        if ("127.0.0.1".equals(host) || "localhost".equals(host) || "0.0.0.0".equals(host)) {
            return true;
        }
        try {
            if (host == null || !host.matches("[0-9]{1,3}(\\.[0-9]{1,3}){3}")) return false;
            byte[] address = InetAddress.getByName(host).getAddress();
            int first = Byte.toUnsignedInt(address[0]);
            int second = Byte.toUnsignedInt(address[1]);
            return first == 10 || first == 127 ||
                (first == 172 && second >= 16 && second <= 31) ||
                (first == 192 && second == 168);
        } catch (Exception ignored) {
            return false;
        }
    }
}
