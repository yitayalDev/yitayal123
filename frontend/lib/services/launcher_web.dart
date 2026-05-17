import 'dart:js' as js;

void openWebUrl(String url) {
  js.context.callMethod('open', [url]);
}
