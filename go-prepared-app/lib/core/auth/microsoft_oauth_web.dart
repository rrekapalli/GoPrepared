/// Calls patched [completeRedirect] in web/msalv2_goprepared.js.
@JS('aadOauth')
library gp_msauth;

import 'dart:async';

import 'package:js/js.dart';

@JS('completeRedirect')
external void jsCompleteRedirect(
  void Function(dynamic) onSuccess,
  void Function(dynamic) onError,
);

Future<void> completeMicrosoftOAuthRedirectJs() {
  final completer = Completer<void>();
  jsCompleteRedirect(
    allowInterop((_) {
      if (!completer.isCompleted) completer.complete();
    }),
    allowInterop((error) {
      if (!completer.isCompleted) {
        completer.completeError(error ?? 'Microsoft sign-in could not be completed.');
      }
    }),
  );
  return completer.future;
}
