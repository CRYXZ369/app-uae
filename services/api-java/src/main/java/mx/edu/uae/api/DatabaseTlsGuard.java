package mx.edu.uae.api;

import java.net.URI;
import java.util.Arrays;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class DatabaseTlsGuard {
    public DatabaseTlsGuard(@Value("${spring.datasource.url}") String jdbcUrl,
                            @Value("${server.address}") String address) {
        if (!"127.0.0.1".equals(address)) {
            throw new IllegalArgumentException("Esta API de desarrollo solo admite 127.0.0.1.");
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
}
