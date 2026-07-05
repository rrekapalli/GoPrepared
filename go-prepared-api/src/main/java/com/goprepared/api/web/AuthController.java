package com.goprepared.api.web;

import com.goprepared.api.service.AuthService;
import com.goprepared.api.web.dto.ApiDtos.AuthResponse;
import com.goprepared.api.web.dto.ApiDtos.DevAuthRequest;
import com.goprepared.api.web.dto.ApiDtos.GoogleAuthRequest;
import com.goprepared.api.web.dto.ApiDtos.MicrosoftAuthRequest;
import com.goprepared.api.web.dto.ApiDtos.OAuthConfigResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
@Tag(name = "Auth")
public class AuthController {

    private final AuthService authService;

    @GetMapping("/config")
    public OAuthConfigResponse oauthConfig() {
        return authService.getOAuthConfig();
    }

    @PostMapping("/google")
    public AuthResponse googleAuth(@Valid @RequestBody GoogleAuthRequest request) {
        return authService.googleLogin(request);
    }

    @PostMapping("/microsoft")
    public AuthResponse microsoftAuth(@Valid @RequestBody MicrosoftAuthRequest request) {
        return authService.microsoftLogin(request);
    }

    @PostMapping("/dev")
    public AuthResponse devAuth(@Valid @RequestBody DevAuthRequest request) {
        return authService.devLogin(request);
    }
}
