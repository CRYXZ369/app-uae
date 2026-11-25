package mx.edu.uae.api;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;

class DatabaseTlsGuardTest {
    @Test
    void acceptsLoopbackAndPrivateAddresses() {
        assertDoesNotThrow(() -> new DatabaseTlsGuard(
            "jdbc:postgresql://localhost:5432/postgres", "127.0.0.1"
        ));
        assertDoesNotThrow(() -> new DatabaseTlsGuard(
            "jdbc:postgresql://localhost:5432/postgres", "192.168.8.46"
        ));
        assertDoesNotThrow(() -> new DatabaseTlsGuard(
            "jdbc:postgresql://localhost:5432/postgres", "10.0.0.5"
        ));
        assertDoesNotThrow(() -> new DatabaseTlsGuard(
            "jdbc:postgresql://localhost:5432/postgres", "0.0.0.0"
        ));
    }

    @Test
    void rejectsPublicAddress() {
        assertThrows(IllegalArgumentException.class, () -> new DatabaseTlsGuard(
            "jdbc:postgresql://localhost:5432/postgres", "8.8.8.8"
        ));
    }
}
