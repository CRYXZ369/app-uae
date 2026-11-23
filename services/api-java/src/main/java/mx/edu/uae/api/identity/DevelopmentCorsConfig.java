package mx.edu.uae.api.identity;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class DevelopmentCorsConfig implements WebMvcConfigurer {
    private final String origin;

    public DevelopmentCorsConfig(@Value("${DEV_WEB_ORIGIN:}") String origin) {
        if (!origin.isEmpty() && !origin.matches("http://(localhost|127\\.0\\.0\\.1):[0-9]{1,5}")) {
            throw new IllegalArgumentException("DEV_WEB_ORIGIN debe ser un origen localhost con puerto.");
        }
        this.origin = origin;
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        if (!origin.isEmpty()) {
            registry.addMapping("/api/v1/sessions/**").allowedOrigins(origin)
                .allowedMethods("GET", "POST").allowedHeaders("Authorization", "Content-Type");
        }
    }
}
