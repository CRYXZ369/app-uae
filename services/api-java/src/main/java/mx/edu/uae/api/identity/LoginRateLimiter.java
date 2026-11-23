package mx.edu.uae.api.identity;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import org.springframework.stereotype.Component;

@Component
public class LoginRateLimiter {
    private static final int MAX_ADDRESSES = 1024;
    private static final int MAX_ATTEMPTS = 10;
    private final Map<String, Window> windows = new HashMap<>();
    private final Clock clock;

    public LoginRateLimiter() {
        this(Clock.systemUTC());
    }

    LoginRateLimiter(Clock clock) {
        this.clock = clock;
    }

    synchronized boolean allow(String address) {
        Instant now = clock.instant();
        windows.entrySet().removeIf(entry -> !entry.getValue().until().isAfter(now));
        Window window = windows.get(address);
        if (window == null) {
            if (windows.size() >= MAX_ADDRESSES) return false;
            windows.put(address, new Window(now.plus(Duration.ofMinutes(1)), 1));
            return true;
        }
        if (window.attempts() >= MAX_ATTEMPTS) return false;
        windows.put(address, new Window(window.until(), window.attempts() + 1));
        return true;
    }

    private record Window(Instant until, int attempts) {}
}
