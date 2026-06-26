package com.goprepared.api.service;

import com.goprepared.api.domain.CommunityInsightEntity;
import com.goprepared.api.domain.Journey;
import java.util.Arrays;
import java.util.LinkedHashSet;
import java.util.Locale;
import java.util.Set;
import java.util.stream.Collectors;

/** Scores community insights against a journey for hub-scoped feeds. */
final class CommunityJourneyMatcher {

    private CommunityJourneyMatcher() {}

    static int score(CommunityInsightEntity insight, Journey journey) {
        if (insight.getJourney() != null && journey.getId() != null
                && insight.getJourney().getId().equals(journey.getId())) {
            return 100;
        }

        Set<String> journeyTokens = journeyTokens(journey);
        Set<String> insightTokens = insightTokens(insight);
        if (journeyTokens.isEmpty() || insightTokens.isEmpty()) {
            return 0;
        }

        int overlap = overlapCount(journeyTokens, insightTokens);
        if (overlap == 0) {
            return 0;
        }

        int score = overlap * 15;
        if (locationMatch(journey, insightTokens)) {
            score += 35;
        }
        if (subtypeMatch(journey, insightTokens)) {
            score += 25;
        }
        if (typeMatch(journey, insightTokens)) {
            score += 15;
        }
        return Math.min(score, 95);
    }

    private static boolean locationMatch(Journey journey, Set<String> insightTokens) {
        String location = token(journey.getLocation() != null ? journey.getLocation().getName() : null);
        return !location.isEmpty() && insightTokens.contains(location);
    }

    private static boolean subtypeMatch(Journey journey, Set<String> insightTokens) {
        String subtype = token(journey.getJourneySubtype() != null ? journey.getJourneySubtype().getName() : null);
        if (!subtype.isEmpty() && insightTokens.contains(subtype)) {
            return true;
        }
        String activity = token(journey.getActivity() != null ? journey.getActivity().getName() : null);
        return !activity.isEmpty() && insightTokens.contains(activity);
    }

    private static boolean typeMatch(Journey journey, Set<String> insightTokens) {
        String type = token(journey.getJourneyType() != null ? journey.getJourneyType().getName() : null);
        return !type.isEmpty() && insightTokens.contains(type);
    }

    private static int overlapCount(Set<String> journeyTokens, Set<String> insightTokens) {
        int count = 0;
        for (String j : journeyTokens) {
            for (String i : insightTokens) {
                if (tokensMatch(j, i)) {
                    count++;
                }
            }
        }
        return count;
    }

    private static boolean tokensMatch(String a, String b) {
        if (a.equals(b)) {
            return true;
        }
        if (a.length() >= 4 && b.length() >= 4 && (a.contains(b) || b.contains(a))) {
            return true;
        }
        return false;
    }

    private static Set<String> journeyTokens(Journey journey) {
        Set<String> tokens = new LinkedHashSet<>();
        addTokens(tokens, journey.getTitle());
        addTokens(tokens, journey.getOriginalQuery());
        if (journey.getJourneyType() != null) {
            addTokens(tokens, journey.getJourneyType().getName());
        }
        if (journey.getJourneySubtype() != null) {
            addTokens(tokens, journey.getJourneySubtype().getName());
        }
        if (journey.getActivity() != null) {
            addTokens(tokens, journey.getActivity().getName());
        }
        if (journey.getLocation() != null) {
            addTokens(tokens, journey.getLocation().getName());
        }
        return tokens.stream().filter(CommunityJourneyMatcher::isSignificant).collect(Collectors.toCollection(LinkedHashSet::new));
    }

    private static Set<String> insightTokens(CommunityInsightEntity insight) {
        Set<String> tokens = new LinkedHashSet<>();
        addTokens(tokens, insight.getJourneyContext());
        addTokens(tokens, insight.getTitle());
        return tokens.stream().filter(CommunityJourneyMatcher::isSignificant).collect(Collectors.toCollection(LinkedHashSet::new));
    }

    private static void addTokens(Set<String> tokens, String raw) {
        if (raw == null || raw.isBlank()) {
            return;
        }
        Arrays.stream(raw.toLowerCase(Locale.ROOT).split("[|\\s,/\\-—]+"))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .forEach(tokens::add);
    }

    private static String token(String raw) {
        return raw == null ? "" : raw.trim().toLowerCase(Locale.ROOT);
    }

    private static boolean isSignificant(String token) {
        if (token.length() < 2) {
            return false;
        }
        return switch (token) {
            case "the", "and", "for", "your", "with", "from", "that", "this", "day", "pre", "prep" -> false;
            default -> true;
        };
    }
}
