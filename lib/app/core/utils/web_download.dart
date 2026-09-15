/// Kiungo (entry point) kimoja kinachotumiwa na mfumo mzima kwa ajili ya
/// "download" na "preview" ya bytes (kwa mfano PDF). Kwa sababu 'dart:html'
/// inapatikana TU kwenye Flutter Web na haipatikani kwenye Linux/Windows/
/// macOS/Android/iOS, faili hii inatumia "conditional export" ya Dart
/// kuchagua kiotomatiki toleo sahihi kutegemea jukwaa (platform) mfumo
/// unapojengwa (build) kwa ajili yake:
///   - Web        -> web_download_web.dart (dart:html)
///   - Vinginevyo -> web_download_io.dart (package:printing)
/// Hakuna sehemu nyingine ya code inayotakiwa kubadilika - zote zinaendelea
/// kuita 'downloadBytesAsFile(...)' na 'openPdfBytesInNewTab(...)' kama kawaida.
export 'web_download_io.dart' if (dart.library.html) 'web_download_web.dart';
