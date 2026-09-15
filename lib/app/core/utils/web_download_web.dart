// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Inapakua (download) bytes kama faili kwenye browser - toleo hili
/// linatumika TU kwenye Flutter Web (linachaguliwa kiotomatiki na
/// 'web_download.dart' kupitia conditional export).
/// Inatumia "Blob + anchor click" trick ya kawaida ya JavaScript/Dart web.
void downloadBytesAsFile(List<int> bytes, String fileName) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

/// "Tazama Awali" (Preview) - inafungua PDF kwenye tab MPYA ya browser
/// (badala ya kuipakua moja kwa moja) - kwa ajili ya kuiangalia kwanza
/// kabla ya kuipakua/kuichapisha.
void openPdfBytesInNewTab(List<int> bytes) {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  // NB: 'revokeObjectUrl' HAIITWI hapa kwa makusudi - tab mpya inahitaji
  // 'url' hii ibaki hai ili iweze kuipakia PDF; itasafishwa na browser
  // yenyewe baada ya session kuisha.
}
