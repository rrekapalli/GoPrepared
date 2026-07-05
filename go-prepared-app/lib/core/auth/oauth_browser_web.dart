import 'dart:html' as html;

/// OAuth persistence — localStorage survives iOS Safari ↔ PWA context switches better than sessionStorage.
html.Storage get _oauthStorage => html.window.localStorage;

html.Storage get _oauthStorageLegacy => html.window.sessionStorage;

String? _readOAuthKey(String key) =>
    _oauthStorage[key]?.isNotEmpty == true ? _oauthStorage[key] : _oauthStorageLegacy[key];

void _writeOAuthKey(String key, String value) {
  _oauthStorage[key] = value;
  _oauthStorageLegacy[key] = value;
}

void _removeOAuthKey(String key) {
  _oauthStorage.remove(key);
  _oauthStorageLegacy.remove(key);
}

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
  return _readOAuthKey('gp_msal_return')?.isNotEmpty == true;
}

bool _hasOAuthParams(String value) => value.contains('code=') || value.contains('error=');

void clearMicrosoftOAuthSessionFlag() {
  _removeOAuthKey('gp_msal_handling');
}

void setMicrosoftOAuthSessionFlag() {
  _writeOAuthKey('gp_msal_handling', '1');
}

bool get isMicrosoftOAuthSessionInProgress => _readOAuthKey('gp_msal_handling') == '1';

/// Persist MSAL config before redirect so index.html can init MSAL before Flutter starts.
void prepareMicrosoftOAuthRedirect({
  required String clientId,
  required String tenantId,
  required String redirectUri,
}) {
  _writeOAuthKey('gp_msal_client_id', clientId);
  _writeOAuthKey('gp_msal_tenant_id', tenantId);
  _writeOAuthKey('gp_msal_redirect_uri', redirectUri);
  _writeOAuthKey('gp_msal_pending', '1');
}

void clearMicrosoftOAuthRedirectState() {
  for (final key in [
    'gp_msal_client_id',
    'gp_msal_tenant_id',
    'gp_msal_redirect_uri',
    'gp_msal_pending',
    'gp_msal_return',
    'gp_msal_early_init',
    'gp_msal_error',
  ]) {
    _removeOAuthKey(key);
  }
}

bool get hasMicrosoftOAuthReturn => _readOAuthKey('gp_msal_return')?.isNotEmpty == true;

String? takeMicrosoftOAuthError() {
  final raw = _readOAuthKey('gp_msal_error');
  if (raw == null || raw.isEmpty) return null;
  _removeOAuthKey('gp_msal_error');
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
  if (raw.contains('500011') || raw.toLowerCase().contains('redirect')) {
    return '$raw\n\nConfirm Azure SPA redirect URI matches exactly: ${html.window.location.origin}/auth';
  }
  return raw;
}
