package mx.edu.uae.api.identity;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;

class DevelopmentCorsConfigTest {
    @Test
    void acceptsLoopbackAndPrivateLanOrigins() {
        assertDoesNotThrow(() -> new DevelopmentCorsConfig(
            "http://127.0.0.1:8081,http://192.168.8.46:8081"
        ));
    }

    @Test
    void rejectsNonPrivateOriginsAndWildcard() {
        assertThrows(IllegalArgumentException.class,
            () -> new DevelopmentCorsConfig("http://example.com:8081"));
        assertThrows(IllegalArgumentException.class,
            () -> new DevelopmentCorsConfig("*"));
    }
}
