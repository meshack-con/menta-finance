import 'dart:typed_data';

import 'package:printing/printing.dart';

/// Toleo la Desktop/Mobile (Linux, Windows, macOS, Android, iOS) - 'dart:html'
/// HAIPO kwenye majukwaa haya, hivyo hatuwezi kutumia Blob/AnchorElement.
/// Badala yake tunatumia 'package:printing' (ambayo tayari ni dependency ya
/// mfumo huu) - inafanya kazi kwenye majukwaa yote bila ya kuongeza package
/// mpya. 'Printing.sharePdf' inafungua dirisha la native la "Save/Share"
/// la mfumo wa uendeshaji ili mtumiaji ahifadhi faili yake.
void downloadBytesAsFile(List<int> bytes, String fileName) {
  Printing.sharePdf(bytes: Uint8List.fromList(bytes), filename: fileName);
}

/// "Tazama Awali" (Preview) kwenye Desktop/Mobile - hakuna dhana ya "tab
/// mpya ya browser" nje ya Web, hivyo tunatumia dirisha la native la
/// print-preview la 'Printing.layoutPdf' ili mtumiaji aone PDF kabla ya
/// kuichapisha au kuihifadhi.
void openPdfBytesInNewTab(List<int> bytes) {
  Printing.layoutPdf(onLayout: (format) async => Uint8List.fromList(bytes));
}
