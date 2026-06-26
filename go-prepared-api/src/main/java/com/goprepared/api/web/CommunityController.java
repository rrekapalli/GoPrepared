package com.goprepared.api.web;

import com.goprepared.api.domain.User;
import com.goprepared.api.service.CommunityService;
import com.goprepared.api.web.dto.ApiDtos.*;
import com.goprepared.api.web.support.SecuritySupport;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/community")
@RequiredArgsConstructor
@Tag(name = "Community")
public class CommunityController {

    private final CommunityService communityService;

    @GetMapping
    public List<CommunityInsightResponse> list() {
        return communityService.listInsights();
    }

    @PostMapping("/contribute")
    @SecurityRequirement(name = "bearerAuth")
    public CommunityInsightResponse contribute(
            @AuthenticationPrincipal User user, @Valid @RequestBody ContributeInsightRequest request) {
        return communityService.contribute(SecuritySupport.requireUser(user), request);
    }

    @PostMapping("/vote")
    @SecurityRequirement(name = "bearerAuth")
    public VoteInsightResponse vote(
            @AuthenticationPrincipal User user, @Valid @RequestBody VoteInsightRequest request) {
        return communityService.vote(SecuritySupport.requireUser(user), request);
    }
}
