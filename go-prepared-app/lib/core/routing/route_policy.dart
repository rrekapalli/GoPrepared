/// Shared route auth policy for go_router and shell navigation.
bool isPublicRoute(String location) {
  return location == '/login' || location == '/auth' || location.startsWith('/explore');
}

bool isProtectedRoute(String location) {
  if (isPublicRoute(location)) return false;
  return location.startsWith('/home') ||
      location.startsWith('/journeys') ||
      location.startsWith('/me') ||
      location.startsWith('/cards');
}

bool isOAuthCallbackUri(Uri uri) {
  if (uri.path == '/auth') return true;
  if (uri.queryParameters.containsKey('code') || uri.queryParameters.containsKey('error')) {
    return true;
  }
  final path = uri.path;
  if (path.startsWith('/code=') || path.startsWith('code=')) return true;
  return false;
}
