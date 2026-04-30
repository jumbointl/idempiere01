import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Outcome of [openInMonalisa002] — distinguishes the three failure modes
/// so the caller can show a meaningful message instead of a generic
/// "not installed".
enum OpenInMonalisa002Result {
  /// `launchUrl` succeeded — the OS handed off to monalisa_app_002 (or
  /// whoever is registered for the `monalisa002://` scheme).
  ok,

  /// `canLaunchUrl` returned false. Either monalisa_app_002 is not
  /// installed, or the calling app is missing the `<queries>` entry for
  /// the `monalisa002` scheme in its AndroidManifest (Android 11+).
  cannotLaunch,

  /// `canLaunchUrl` said yes but `launchUrl` itself returned false.
  launchFailed,

  /// `launchUrl` threw an exception. The message is in [errorMessage].
  exception,
}

class OpenInMonalisa002Outcome {
  OpenInMonalisa002Outcome(this.result, {this.errorMessage});

  final OpenInMonalisa002Result result;
  final String? errorMessage;

  bool get ok => result == OpenInMonalisa002Result.ok;
}

/// Build a `monalisa002://run?action=<int>&value=<jsonEncoded>` URI and try to
/// hand it off to the OS so monalisa_app_002 can open it.
///
/// `action` is one of `Memory.ACTION_*` ints (kept in sync with
/// monalisa_app_002's `DeepLinkActions`). `value` is encoded as JSON; pass an
/// empty map (or null) when there is nothing to send.
///
/// Returns an [OpenInMonalisa002Outcome] explaining what happened. The
/// caller decides how to surface a failure. See [OpenInMonalisa002Result]
/// for the failure modes.
Future<OpenInMonalisa002Outcome> openInMonalisa002({
  required int action,
  Map<String, dynamic>? value,
}) async {
  final json = jsonEncode(value ?? const <String, dynamic>{});
  final uri = Uri(
    scheme: 'monalisa002',
    host: 'run',
    queryParameters: <String, String>{
      'action': action.toString(),
      'value': json,
    },
  );

  debugPrint('[openInMonalisa002] uri=$uri');

  final bool canLaunch;
  try {
    canLaunch = await canLaunchUrl(uri);
  } catch (e) {
    debugPrint('[openInMonalisa002] canLaunchUrl threw: $e');
    return OpenInMonalisa002Outcome(
      OpenInMonalisa002Result.exception,
      errorMessage: 'canLaunchUrl: $e',
    );
  }

  debugPrint('[openInMonalisa002] canLaunch=$canLaunch');

  if (!canLaunch) {
    return OpenInMonalisa002Outcome(OpenInMonalisa002Result.cannotLaunch);
  }

  try {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    debugPrint('[openInMonalisa002] launchUrl returned $launched');
    if (!launched) {
      return OpenInMonalisa002Outcome(OpenInMonalisa002Result.launchFailed);
    }
    return OpenInMonalisa002Outcome(OpenInMonalisa002Result.ok);
  } catch (e) {
    debugPrint('[openInMonalisa002] launchUrl threw: $e');
    return OpenInMonalisa002Outcome(
      OpenInMonalisa002Result.exception,
      errorMessage: 'launchUrl: $e',
    );
  }
}
