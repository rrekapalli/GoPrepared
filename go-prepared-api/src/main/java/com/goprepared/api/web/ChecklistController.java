package com.goprepared.api.web;

import com.goprepared.api.domain.User;
import com.goprepared.api.service.ChecklistService;
import com.goprepared.api.web.dto.ApiDtos.AddChecklistItemRequest;
import com.goprepared.api.web.dto.ApiDtos.ChecklistItemResponse;
import com.goprepared.api.web.dto.ApiDtos.ChecklistResponse;
import jakarta.validation.Valid;
import com.goprepared.api.web.support.SecuritySupport;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@Tag(name = "Checklist")
@SecurityRequirement(name = "bearerAuth")
public class ChecklistController {

    private final ChecklistService checklistService;

    @GetMapping("/api/v1/journeys/{id}/checklist")
    public ChecklistResponse getChecklist(@AuthenticationPrincipal User user, @PathVariable Long id) {
        return checklistService.getOrGenerateChecklist(SecuritySupport.requireUser(user), id);
    }

    @PostMapping("/api/v1/checklist/{id}/complete")
    public ChecklistItemResponse completeChecklistItem(@AuthenticationPrincipal User user, @PathVariable Long id) {
        return checklistService.toggleComplete(SecuritySupport.requireUser(user), id);
    }

    @PostMapping("/api/v1/journeys/{id}/checklist/items")
    public ChecklistItemResponse addChecklistItem(
            @AuthenticationPrincipal User user,
            @PathVariable Long id,
            @Valid @RequestBody AddChecklistItemRequest request) {
        return checklistService.addUserItem(SecuritySupport.requireUser(user), id, request);
    }

    @DeleteMapping("/api/v1/checklist/{id}")
    public void deleteChecklistItem(@AuthenticationPrincipal User user, @PathVariable Long id) {
        checklistService.deleteUserItem(SecuritySupport.requireUser(user), id);
    }
}
