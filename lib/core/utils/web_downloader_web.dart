import 'dart:html' as html;

void downloadWeb(List<int> bytes, String fileName) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute("download", "$fileName.png")
    ..click();
  html.Url.revokeObjectUrl(url);
}
