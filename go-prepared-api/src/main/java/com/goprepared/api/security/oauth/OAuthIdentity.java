package com.goprepared.api.security.oauth;

public record OAuthIdentity(
        OAuthProvider provider,
        String subject,
        String email,
        String name,
        String picture) {}
