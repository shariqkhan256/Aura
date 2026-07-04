import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';

class ModelService {
  static final ModelService _instance = ModelService._internal();

  factory ModelService() => _instance;

  ModelService._internal();

  static const String _modelUrl = "https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-en_US-libritts_r-medium.tar.bz2";
  static const String _modelFolderName = "vits-piper-en_US-libritts_r-medium";

  Future<String?> getModelPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final modelPath = '${dir.path}/$_modelFolderName';
    final modelDir = Directory(modelPath);
    
    if (await modelDir.exists()) {
      if (await File('$modelPath/en_US-libritts_r-medium.onnx').exists() &&
          await File('$modelPath/tokens.txt').exists() &&
          await Directory('$modelPath/espeak-ng-data').exists()) {
        return modelPath;
      }
    }
    return null;
  }

  Future<void> downloadModel(Function(double) onProgress) async {
    final dir = await getApplicationDocumentsDirectory();
    
    try {
      final request = await http.Client().send(http.Request('GET', Uri.parse(_modelUrl)));
      final totalBytes = request.contentLength ?? 50 * 1024 * 1024;
      int receivedBytes = 0;
      
      final List<int> bytes = [];
      await request.stream.listen(
        (List<int> chunk) {
          bytes.addAll(chunk);
          receivedBytes += chunk.length;
          onProgress(receivedBytes / totalBytes);
        },
        onDone: () {},
        onError: (e) { throw e; },
        cancelOnError: true,
      ).asFuture();

      // Decompress
      onProgress(1.0); // Download complete, starting extraction
      
      final archive = TarDecoder().decodeBytes(BZip2Decoder().decodeBytes(bytes));

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          final f = File('${dir.path}/$filename');
          await f.parent.create(recursive: true);
          await f.writeAsBytes(data);
        }
      }
      
    } catch (e) {
      throw Exception("Failed to download model: $e");
    }
  }
}
