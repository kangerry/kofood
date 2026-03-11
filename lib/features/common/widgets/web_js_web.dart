import 'dart:html' as html;
import 'dart:js_util' as js_util;

bool hasGoogleMaps() {
  final hasGoogle = js_util.hasProperty(html.window, 'google') &&
      js_util.hasProperty(js_util.getProperty(html.window, 'google'), 'maps');
  return hasGoogle;
}
