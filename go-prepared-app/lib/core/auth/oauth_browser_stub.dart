void clearOAuthBrowserUrl(String path) {}

void clearMicrosoftOAuthSessionFlag() {}

void setMicrosoftOAuthSessionFlag() {}

bool get isMicrosoftOAuthSessionInProgress => false;

bool get hasOAuthCallbackInBrowserUrl => false;

void prepareMicrosoftOAuthRedirect({
  required String clientId,
  required String tenantId,
  required String redirectUri,
}) {}

void clearMicrosoftOAuthRedirectState() {}

bool get hasMicrosoftOAuthReturn => false;

/// Returns and clears a MSAL/Azure error captured during early redirect handling.
String? takeMicrosoftOAuthError() => null;
