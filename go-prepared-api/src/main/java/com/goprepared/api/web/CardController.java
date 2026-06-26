package com.goprepared.api.web;

import com.goprepared.api.domain.User;
import com.goprepared.api.service.CardService;
import com.goprepared.api.web.dto.ApiDtos.AskRequest;
import com.goprepared.api.web.dto.ApiDtos.AskResponse;
import com.goprepared.api.web.dto.ApiDtos.CardResponse;
import com.goprepared.api.web.support.SecuritySupport;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/cards")
@RequiredArgsConstructor
@Tag(name = "Cards")
@SecurityRequirement(name = "bearerAuth")
public class CardController {

    private final CardService cardService;

    @GetMapping("/{id}")
    public CardResponse getCard(@AuthenticationPrincipal User user, @PathVariable Long id) {
        return cardService.getCard(SecuritySupport.requireUser(user), id);
    }

    @PostMapping("/{id}/ask")
    public AskResponse askCard(
            @AuthenticationPrincipal User user,
            @PathVariable Long id,
            @Valid @RequestBody AskRequest request) {
        return cardService.askCard(SecuritySupport.requireUser(user), id, request.question());
    }
}
