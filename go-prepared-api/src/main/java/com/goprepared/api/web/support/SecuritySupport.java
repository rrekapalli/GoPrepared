package com.goprepared.api.web.support;

import com.goprepared.api.domain.User;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

public final class SecuritySupport {
    private SecuritySupport() {}

    public static User requireUser(User user) {
        if (user == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Authentication required");
        }
        return user;
    }
}
