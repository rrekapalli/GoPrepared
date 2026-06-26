package com.goprepared.api.web;

import com.goprepared.api.service.AuthService;
import com.goprepared.api.web.dto.ApiDtos.AuthResponse;
import com.goprepared.api.web.dto.ApiDtos.DevAuthRequest;
import com.goprepared.api.web.dto.ApiDtos.GoogleAuthRequest;
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

    @PostMapping("/google")
    public AuthResponse googleAuth(@Valid @RequestBody GoogleAuthRequest request) {
        return authService.googleLogin(request);
    }

    @PostMapping("/dev")
    public AuthResponse devAuth(@Valid @RequestBody DevAuthRequest request) {
        return authService.devLogin(request);
    }
}
