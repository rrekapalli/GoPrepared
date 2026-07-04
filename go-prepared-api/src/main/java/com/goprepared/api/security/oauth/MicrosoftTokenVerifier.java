package com.goprepared.api.security.oauth;

import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.jwk.source.JWKSource;
import com.nimbusds.jose.jwk.source.RemoteJWKSet;
import com.nimbusds.jose.proc.JWSKeySelector;
import com.nimbusds.jose.proc.JWSVerificationKeySelector;
import com.nimbusds.jose.proc.SecurityContext;
import com.nimbusds.jose.util.DefaultResourceRetriever;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.proc.ConfigurableJWTProcessor;
import com.nimbusds.jwt.proc.DefaultJWTProcessor;
import java.net.URL;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.server.ResponseStatusException;

@Component
public class MicrosoftTokenVerifier {

    private final String clientId;
    private final String issuer;
    private final ConfigurableJWTProcessor<SecurityContext> jwtProcessor;

    public MicrosoftTokenVerifier(
            @Value("${goprepared.microsoft.client-id:}") String clientId,
            @Value("${goprepared.microsoft.tenant-id:common}") String tenantId) {
        this.clientId = clientId;
        this.issuer = "https://login.microsoftonline.com/" + tenantId + "/v2.0";
        this.jwtProcessor = buildProcessor(tenantId);
    }

    private static ConfigurableJWTProcessor<SecurityContext> buildProcessor(String tenantId) {
        try {
            URL jwkUrl = new URL("https://login.microsoftonline.com/" + tenantId + "/discovery/v2.0/keys");
            JWKSource<SecurityContext> keySource = new RemoteJWKSet<>(jwkUrl, new DefaultResourceRetriever(5000, 5000));
            JWSKeySelector<SecurityContext> keySelector =
                    new JWSVerificationKeySelector<>(JWSAlgorithm.RS256, keySource);
            ConfigurableJWTProcessor<SecurityContext> processor = new DefaultJWTProcessor<>();
            processor.setJWSKeySelector(keySelector);
            return processor;
        } catch (Exception ex) {
            throw new IllegalStateException("Failed to initialize Microsoft JWT processor", ex);
        }
    }

    public OAuthIdentity verify(String idToken) {
        if (!StringUtils.hasText(clientId)) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Microsoft OAuth is not configured");
        }
        try {
            JWTClaimsSet claims = jwtProcessor.process(idToken, null);
            validateClaims(claims);
            String email = resolveEmail(claims);
            if (!StringUtils.hasText(email)) {
                throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Microsoft account email is missing");
            }
            return new OAuthIdentity(
                    OAuthProvider.MICROSOFT,
                    claims.getSubject(),
                    email,
                    claims.getStringClaim("name"),
                    null);
        } catch (ResponseStatusException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Failed to verify Microsoft ID token");
        }
    }

    private void validateClaims(JWTClaimsSet claims) {
        List<String> audience = claims.getAudience();
        if (audience == null || !audience.contains(clientId)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid Microsoft token audience");
        }
        String tokenIssuer = claims.getIssuer();
        if (!issuer.equals(tokenIssuer)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid Microsoft token issuer");
        }
    }

    private static String resolveEmail(JWTClaimsSet claims) {
        try {
            String email = claims.getStringClaim("email");
            if (StringUtils.hasText(email)) {
                return email;
            }
            String preferred = claims.getStringClaim("preferred_username");
            if (StringUtils.hasText(preferred) && preferred.contains("@")) {
                return preferred;
            }
        } catch (java.text.ParseException ex) {
            return null;
        }
        return null;
    }
}
