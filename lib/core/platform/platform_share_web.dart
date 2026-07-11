// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_util' as js_util;

/// Web: uses Web Share API, returns false if unavailable.
Future<bool> platformShare(String text, String title) async {
  final navigator = html.window.navigator;
  if (js_util.hasProperty(navigator, 'share')) {
    final shareData = js_util.newObject<Object>();
    js_util.setProperty(shareData, 'text', text);
    js_util.setProperty(shareData, 'title', title);
    await js_util.promiseToFuture(
        js_util.callMethod(navigator, 'share', [shareData]));
    return true;
  }
  return false;
}

bool get platformCanShare {
  final navigator = html.window.navigator;
  return js_util.hasProperty(navigator, 'share');
}
