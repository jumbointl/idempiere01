import 'dart:convert';

import 'package:url_launcher/url_launcher.dart';

/// Build a `monalisa002://run?action=<int>&value=<jsonEncoded>` URI and try to
/// hand it off to the OS so monalisa_app_002 can open it.
///
/// `action` is one of `Memory.ACTION_*` ints (kept in sync with
/// monalisa_app_002's `DeepLinkActions`). `value` is encoded as JSON; pass an
/// empty map (or null) when there is nothing to send.
///
/// Returns `true` if the OS reported the launch as handled, `false` otherwise.
/// Will return `false` silently if monalisa_app_002 is not installed — the
/// caller decides how to surface that.
Future<bool> openInMonalisa002({
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

  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
