package mx.edu.uae.api.identity;

import java.net.InetAddress;
import java.net.URI;
import java.util.Arrays;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class DevelopmentCorsConfig implements WebMvcConfigurer {
    private final List<String> origins;

    public DevelopmentCorsConfig(
            @Value("${DEV_WEB_ORIGINS:${DEV_WEB_ORIGIN:}}") String configuredOrigins) {
        origins = configuredOrigins.isBlank()
            ? List.of()
            : Arrays.stream(configuredOrigins.split(","))
                .map(String::trim)
                .filter(origin -> !origin.isEmpty())
                .toList();
        if (origins.stream().anyMatch(origin -> !isLocalDevelopmentOrigin(origin))) {
            throw new IllegalArgumentException(
                "DEV_WEB_ORIGINS solo acepta orígenes HTTP localhost o de una IP privada.");
        }
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        if (!origins.isEmpty()) {
            String[] allowedOrigins = origins.toArray(String[]::new);
            registry.addMapping("/api/v1/sessions/**").allowedOrigins(allowedOrigins)
                .allowedMethods("GET", "POST").allowedHeaders("Authorization", "Content-Type");
            registry.addMapping("/api/v1/grades/**").allowedOrigins(allowedOrigins)
                .allowedMethods("GET").allowedHeaders("Authorization");
            registry.addMapping("/api/v1/academic/**").allowedOrigins(allowedOrigins)
                .allowedMethods("GET", "POST")
                .allowedHeaders("Authorization", "Content-Type");
        }
    }

    private static boolean isLocalDevelopmentOrigin(String origin) {
        try {
            URI uri = URI.create(origin);
            if (!"http".equals(uri.getScheme()) || uri.getPort() < 1 || uri.getPort() > 65535 ||
                uri.getUserInfo() != null || uri.getQuery() != null || uri.getFragment() != null ||
                (uri.getPath() != null && !uri.getPath().isEmpty())) {
                return false;
            }
            String host = uri.getHost();
            if ("localhost".equals(host)) return true;
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
