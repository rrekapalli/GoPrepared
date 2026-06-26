package com.goprepared.api.web;

import com.goprepared.api.domain.User;
import com.goprepared.api.service.AuthService;
import com.goprepared.api.web.dto.ApiDtos.UserResponse;
import com.goprepared.api.web.support.SecuritySupport;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
@Tag(name = "Users")
@SecurityRequirement(name = "bearerAuth")
public class UserController {

    private final AuthService authService;

    @GetMapping("/me")
    public UserResponse me(@AuthenticationPrincipal User user) {
        return authService.toUserResponse(SecuritySupport.requireUser(user));
    }
}
