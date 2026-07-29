import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Liest Assets direkt von der Platte statt aus dem gebauten Bündel.
///
/// `rootBundle` kennt im Test nur, was zuvor über den Asset-Manifest-Kanal
/// bereitgestellt wurde. Für Daten, die ohnehin als Dateien im Projekt liegen,
/// ist der direkte Weg einfacher und deckt zusätzlich ab, dass die Pfade in
/// `pubspec.yaml` und im Code zusammenpassen.
class FileAssetBundle extends CachingAssetBundle {
  FileAssetBundle({this.root = '.'});

  /// Wurzel relativ zum Arbeitsverzeichnis der Tests — das ist `app/`.
  final String root;

  @override
  Future<ByteData> load(String key) async {
    final file = File('$root/$key');
    if (!file.existsSync()) {
      throw FlutterError('Asset nicht gefunden: ${file.path}');
    }
    return ByteData.sublistView(Uint8List.fromList(await file.readAsBytes()));
  }
}
