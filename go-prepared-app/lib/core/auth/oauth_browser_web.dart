import 'dart:html' as html;

/// Removes OAuth hash/query from the address bar so MSAL is not re-triggered on reload.
void clearOAuthBrowserUrl(String path) {
  html.window.history.replaceState(null, '', path);
}

bool get hasOAuthCallbackInBrowserUrl {
  final search = html.window.location.search ?? '';
  final hash = html.window.location.hash ?? '';
  if (_hasOAuthParams(search) || _hasOAuthParams(hash)) {
    return true;
  }
  return html.window.sessionStorage['gp_msal_return']?.isNotEmpty == true;
}

bool _hasOAuthParams(String value) => value.contains('code=') || value.contains('error=');

void clearMicrosoftOAuthSessionFlag() {
  html.window.sessionStorage.remove('gp_msal_handling');
}

void setMicrosoftOAuthSessionFlag() {
  html.window.sessionStorage['gp_msal_handling'] = '1';
}

bool get isMicrosoftOAuthSessionInProgress =>
    html.window.sessionStorage['gp_msal_handling'] == '1';

/// Persist MSAL config before redirect so index.html can init MSAL before Flutter starts.
void prepareMicrosoftOAuthRedirect({
  required String clientId,
  required String tenantId,
  required String redirectUri,
}) {
  final storage = html.window.sessionStorage;
  storage['gp_msal_client_id'] = clientId;
  storage['gp_msal_tenant_id'] = tenantId;
  storage['gp_msal_redirect_uri'] = redirectUri;
  storage['gp_msal_pending'] = '1';
}

void clearMicrosoftOAuthRedirectState() {
  final storage = html.window.sessionStorage;
  storage.remove('gp_msal_client_id');
  storage.remove('gp_msal_tenant_id');
  storage.remove('gp_msal_redirect_uri');
  storage.remove('gp_msal_pending');
  storage.remove('gp_msal_return');
  storage.remove('gp_msal_early_init');
  storage.remove('gp_msal_error');
}

bool get hasMicrosoftOAuthReturn =>
    html.window.sessionStorage['gp_msal_return']?.isNotEmpty == true;

String? takeMicrosoftOAuthError() {
  final storage = html.window.sessionStorage;
  final raw = storage['gp_msal_error'];
  if (raw == null || raw.isEmpty) return null;
  storage.remove('gp_msal_error');
  return _formatMicrosoftOAuthError(raw);
}

String _formatMicrosoftOAuthError(String raw) {
    if (raw.contains('9002326') || raw.contains('Single-Page Application')) {
    return 'Azure Entra app must be registered as a Single-page application (SPA), not Web.\n\n'
        'In Azure Portal → App registrations → Authentication:\n'
        '1. Add platform "Single-page application"\n'
        '2. Add redirect URIs:\n'
        '   • http://localhost:51518/auth (local dev)\n'
        '   • http://goprepared.tailce422e.ts.net/auth (production PWA)\n'
        '3. Remove the same URIs from the "Web" platform if listed there\n\n'
        'See Docs/oauth-setup.md for details.';
  }
  return raw;
}
