package com.goprepared.api.web;

import com.goprepared.api.domain.User;
import com.goprepared.api.service.JourneyService;
import com.goprepared.api.service.JourneyStatusService;
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
@RequestMapping("/api/v1/journeys")
@RequiredArgsConstructor
@Tag(name = "Journeys")
@SecurityRequirement(name = "bearerAuth")
public class JourneyController {

    private final JourneyService journeyService;
    private final JourneyStatusService journeyStatusService;

    @PostMapping
    public JourneyResponse createJourney(
            @AuthenticationPrincipal User user, @Valid @RequestBody CreateJourneyRequest request) {
        return journeyService.createJourney(SecuritySupport.requireUser(user), request.query());
    }

    @PostMapping("/{id}/generate")
    public GenerateJourneyResponse generateJourney(@AuthenticationPrincipal User user, @PathVariable Long id) {
        return journeyService.generateCards(SecuritySupport.requireUser(user), id);
    }

    @GetMapping
    public List<JourneyResponse> listJourneys(@AuthenticationPrincipal User user) {
        return journeyService.listJourneys(SecuritySupport.requireUser(user));
    }

    @GetMapping("/similar")
    public List<SimilarJourneyResponse> similarJourneys(
            @AuthenticationPrincipal User user, @RequestParam String query) {
        return journeyService.findSimilar(SecuritySupport.requireUser(user), query);
    }

    @GetMapping("/{id}")
    public JourneyResponse getJourney(@AuthenticationPrincipal User user, @PathVariable Long id) {
        return journeyService.getJourney(SecuritySupport.requireUser(user), id);
    }

    @GetMapping("/{id}/status")
    public JourneyStatusResponse getStatus(@AuthenticationPrincipal User user, @PathVariable Long id) {
        return journeyStatusService.getStatus(SecuritySupport.requireUser(user), id);
    }

    @GetMapping("/{id}/cards")
    public List<CardResponse> getCards(@AuthenticationPrincipal User user, @PathVariable Long id) {
        return journeyService.getCards(SecuritySupport.requireUser(user), id);
    }

    @PostMapping("/{id}/ask")
    public AskResponse askJourney(
            @AuthenticationPrincipal User user,
            @PathVariable Long id,
            @Valid @RequestBody AskRequest request) {
        return journeyService.askJourney(SecuritySupport.requireUser(user), id, request.question());
    }
}
