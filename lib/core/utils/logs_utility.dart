import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LogUtils {
  static const int _chunkSize = 800;

  /// Prints FULL logs to terminal (no truncation)
  static void printFull(String message) {
    for (int i = 0; i < message.length; i += _chunkSize) {
      print(message.substring(
        i,
        i + _chunkSize > message.length ? message.length : i + _chunkSize,
      ));
    }
  }

  /// Saves FULL logs to a file and prints file path
  static Future<void> saveToFile(
    String fileName,
    dynamic data,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');

    final encoder = JsonEncoder.withIndent('  ');
    final content = data is String ? data : encoder.convert(data);

    await file.writeAsString(content, flush: true);

    print('✅ FULL LOG SAVED AT: ${file.path}');
  }
}
