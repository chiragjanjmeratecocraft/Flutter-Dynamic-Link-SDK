import 'package:flutter/material.dart';
import 'package:my_deeplink_sdk/my_deeplink_sdk.dart';

import 'screens/link_payload_screens.dart';

/// Maps `DynamicLinkData.customData` (API field `data`) to a screen.
///
/// **URLs vs keys:** The short code (or full URL) only identifies *which link* to load.
/// The backend returns JSON; the `data` object holds keys like `Vande` / `Bharat`.
/// Use **different short codes** in the dashboard if you want different payloads
/// (e.g. one link’s `data` is `{"Vande":"Matram"}`, another’s is `{"Bharat":"Mahan"}`).
/// If a single link returns both keys, [navigateForLinkData] uses the first match
/// in [kRoutingKeyOrder].
const List<String> kRoutingKeyOrder = ['Vande', 'Bharat'];

/// Returns which key in [customData] should drive navigation, if any.
String? resolveRoutingKey(Map<String, dynamic> customData) {
  for (final key in kRoutingKeyOrder) {
    if (customData.containsKey(key)) return key;
  }
  return null;
}

void navigateForLinkData(GlobalKey<NavigatorState> navKey, DynamicLinkData data) {
  final nav = navKey.currentState;
  if (nav == null) return;

  final custom = data.customData;
  final key = resolveRoutingKey(custom);
  if (key == null) return;

  final raw = custom[key];
  final value = raw == null ? '' : raw.toString();

  final Widget page;
  switch (key) {
    case 'Vande':
      page = VandeScreen(value: value);
      break;
    case 'Bharat':
      page = BharatScreen(value: value);
      break;
    default:
      return;
  }

  nav.push(MaterialPageRoute<void>(builder: (_) => page));
}
