// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web: reads current URL from browser to support deep links.
String getInitialLocationFromUrl() {
  try {
    final path = Uri.parse(html.window.location.href).path;
    final appPath = path.startsWith('/app') ? path.substring(4) : path;
    if (appPath.startsWith('/shared/')) return appPath;
    if (appPath.startsWith('/perfume/')) return appPath;
  } catch (_) {}
  return '/login';
}
