package com.goprepared.api.service;

import com.goprepared.api.domain.User;
import com.goprepared.api.repository.UserRepository;
import com.goprepared.api.security.JwtService;
import com.goprepared.api.security.oauth.GoogleTokenVerifier;
import com.goprepared.api.security.oauth.MicrosoftTokenVerifier;
import com.goprepared.api.security.oauth.OAuthIdentity;
import com.goprepared.api.security.oauth.OAuthProvider;
import com.goprepared.api.web.dto.ApiDtos.*;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import org.springframework.web.server.ResponseStatusException;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final JwtService jwtService;
    private final GoogleTokenVerifier googleTokenVerifier;
    private final MicrosoftTokenVerifier microsoftTokenVerifier;

    @Value("${goprepared.auth.dev-enabled:true}")
    private boolean devEnabled;

    @Transactional
    public AuthResponse devLogin(DevAuthRequest request) {
        if (!devEnabled) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Dev auth is disabled");
        }
        User user = userRepository
                .findByEmail(request.email())
                .orElseGet(() -> userRepository.save(User.builder()
                        .email(request.email())
                        .name(request.name() != null ? request.name() : "Dev User")
                        .googleId("dev-" + request.email())
                        .build()));
        return tokenFor(user);
    }

    @Transactional
    public AuthResponse googleLogin(GoogleAuthRequest request) {
        OAuthIdentity identity = googleTokenVerifier.verify(request.idToken());
        return tokenFor(upsertOAuthUser(identity));
    }

    @Transactional
    public AuthResponse microsoftLogin(MicrosoftAuthRequest request) {
        OAuthIdentity identity = microsoftTokenVerifier.verify(request.idToken());
        return tokenFor(upsertOAuthUser(identity));
    }

    public UserResponse toUserResponse(User user) {
        return new UserResponse(user.getId(), user.getName(), user.getEmail(), user.getProfilePicture());
    }

    private User upsertOAuthUser(OAuthIdentity identity) {
        User user = findByProvider(identity)
                .or(() -> userRepository.findByEmail(identity.email()))
                .orElseGet(() -> User.builder()
                        .email(identity.email())
                        .name(defaultName(identity))
                        .build());

        applyProviderId(user, identity);
        applyProfile(user, identity);
        return userRepository.save(user);
    }

    private java.util.Optional<User> findByProvider(OAuthIdentity identity) {
        return switch (identity.provider()) {
            case GOOGLE -> userRepository.findByGoogleId(identity.subject());
            case MICROSOFT -> userRepository.findByMicrosoftId(identity.subject());
        };
    }

    private static void applyProviderId(User user, OAuthIdentity identity) {
        switch (identity.provider()) {
            case GOOGLE -> user.setGoogleId(identity.subject());
            case MICROSOFT -> user.setMicrosoftId(identity.subject());
        }
    }

    private static void applyProfile(User user, OAuthIdentity identity) {
        if (StringUtils.hasText(identity.name())) {
            user.setName(identity.name());
        } else if (!StringUtils.hasText(user.getName())) {
            user.setName(defaultName(identity));
        }
        if (StringUtils.hasText(identity.picture())) {
            user.setProfilePicture(identity.picture());
        }
    }

    private static String defaultName(OAuthIdentity identity) {
        if (StringUtils.hasText(identity.name())) {
            return identity.name();
        }
        int at = identity.email().indexOf('@');
        return at > 0 ? identity.email().substring(0, at) : identity.email();
    }

    private AuthResponse tokenFor(User user) {
        String token = jwtService.generateToken(user.getId(), user.getEmail());
        return new AuthResponse(token, toUserResponse(user));
    }
}
