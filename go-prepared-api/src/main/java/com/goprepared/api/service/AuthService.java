package com.goprepared.api.service;

import com.goprepared.api.domain.User;
import com.goprepared.api.repository.UserRepository;
import com.goprepared.api.security.JwtService;
import com.goprepared.api.web.dto.ApiDtos.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final JwtService jwtService;

    @Transactional
    public AuthResponse devLogin(DevAuthRequest request) {
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
        // Scaffold: treat idToken as email for local dev when Google verification not configured
        String email = request.idToken() != null && request.idToken().contains("@")
                ? request.idToken()
                : "user@gmail.com";
        User user = userRepository
                .findByEmail(email)
                .orElseGet(() -> userRepository.save(User.builder()
                        .email(email)
                        .name("Google User")
                        .googleId("google-" + email)
                        .build()));
        return tokenFor(user);
    }

    public UserResponse toUserResponse(User user) {
        return new UserResponse(user.getId(), user.getName(), user.getEmail(), user.getProfilePicture());
    }

    private AuthResponse tokenFor(User user) {
        String token = jwtService.generateToken(user.getId(), user.getEmail());
        return new AuthResponse(token, toUserResponse(user));
    }
}
