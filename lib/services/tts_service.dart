import 'dart:async';
import 'dart:io';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import '../models/voice_model.dart';
import 'model_service.dart';
import 'audio_player_service.dart';

class TTSService {
  // Piper Engine (Advanced)
  sherpa.OfflineTts? _sherpaTts;
  bool _isInitialized = false;
  final ModelService _modelService = ModelService();

  TTSService();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // On Flutter, we must initialize the native library once
      sherpa.initBindings();

      final path = await _modelService.getModelPath();
      print("[TTS] Checking advanced model path: $path");

      if (path != null) {
        final onnxPath = "$path/en_US-libritts_r-medium.onnx";
        final tokensPath = "$path/tokens.txt";
        final dataDirPath = "$path/espeak-ng-data";

        print("[TTS] ONNX exists: ${File(onnxPath).existsSync()}");
        print("[TTS] Tokens exists: ${File(tokensPath).existsSync()}");
        print("[TTS] DataDir exists: ${Directory(dataDirPath).existsSync()}");

        // Define Model Config
        final modelConfig = sherpa.OfflineTtsModelConfig(
          vits: sherpa.OfflineTtsVitsModelConfig(
            model: onnxPath,
            tokens: tokensPath,
            dataDir: dataDirPath,
          ),
          numThreads: 2,
          debug: false,
          provider: "cpu",
        );

        final config = sherpa.OfflineTtsConfig(model: modelConfig);

        _sherpaTts = sherpa.OfflineTts(config);
        _isInitialized = true;
        print("[TTS] SUCCESS: Advanced Piper Engine Ready!");
      } else {
        print("[TTS] Advanced Model folder not found yet.");
      }
    } catch (e) {
      print("[TTS] ERROR: Failed to init Sherpa: $e");
    }
  }

  Future<void> setVoice(VoiceCharacter character) async {
    // In Piper, customization happens during generation via sid and speed.
    // This method is kept for API compatibility but doesn't need to do much.
  }

  Future<void> previewVoice(VoiceCharacter voice) async {
    if (!_isInitialized) await initialize();
    if (_sherpaTts == null) return;

    try {
      print("[TTS] Generating real-time preview for ${voice.name}...");
      
      // Use a temporary file for the preview
      final tempDir = await _modelService.getModelPath(); 
      if (tempDir == null) return;
      
      final previewPath = "${Directory.systemTemp.path}/preview_${voice.id}.wav";
      
      // Short friendly greeting for the character
      final text = "Hello, I am ${voice.name}. How can I help you today?";
      
      await synthesizeToFile(text, previewPath, voice: voice);
      
      // Play using the shared player service
      final player = AudioPlayerService();
      await player.playFile(previewPath);
      
    } catch (e) {
      print("[TTS] Preview Error: $e");
    }
  }

  Future<void> stop() async {
    // Sherpa generation is synchronous per chunk, so we don't 'stop' mid-generation 
    // in this simplified implementation.
  }

  Future<String> synthesizeToFile(
    String text,
    String fullPath, {
    VoiceCharacter? voice,
    Function(double)? onProgress,
  }) async {
    if (!_isInitialized) await initialize();

    if (_sherpaTts == null) {
      throw Exception("Piper engine not initialized. Please download the model first.");
    }

    print('[TTS] Generating audio with Piper Engine');

    int sid = 0;
    double speed = 1.0;

    if (voice != null) {
      switch (voice.id) {
        case 'liam': sid = 230; break;
        case 'elsa': sid = 180; break;
        case 'robin': sid = 405; break;
        case 'emma': sid = 12; break;
        case 'lily': sid = 510; break;
      }
      // Calculate speed based on lengthScale (speed = 1.0 / lengthScale)
      speed = 1.0 / voice.lengthScale;
    }

    // Safe Chunking + Dynamic Prosody
    final chunks = _splitIntoSentences(text);
    final allSamples = <double>[];
    int sampleRate = 22050;

    for (var i = 0; i < chunks.length; i++) {
      final chunk = chunks[i].trim();
      if (chunk.isEmpty) continue;

      // Update Progress
      if (onProgress != null) {
        onProgress(i / chunks.length);
        await Future.delayed(Duration.zero);
      }

      // Dynamic Intonation Logic (Adjust speed based on punctuation)
      double chunkSpeed = speed;
      if (chunk.endsWith('!')) {
         chunkSpeed = speed * 1.1; // Slightly faster for excitement
      } else if (chunk.endsWith('?')) {
         chunkSpeed = speed * 0.9; // Slightly slower for inquiry
      }

      final result = _sherpaTts!.generate(
        text: chunk,
        sid: sid,
        speed: chunkSpeed,
      );
      
      allSamples.addAll(result.samples);
      sampleRate = result.sampleRate;

      // Add 300ms Natural Breathing Pause
      if (i < chunks.length - 1) {
         final pauseSamples = (sampleRate * 0.3).toInt();
         allSamples.addAll(List.filled(pauseSamples, 0.0));
      }
    }

    if (onProgress != null) onProgress(1.0);

    if (allSamples.isEmpty) throw Exception("No audio generated.");

    final success = _writeWavFile(fullPath, allSamples, sampleRate);
    if (success) {
      return fullPath;
    } else {
      throw Exception("Piper generation failed.");
    }
  }

  List<String> _splitIntoSentences(String text) {
    final exp = RegExp(r'(?<=[.!?])\s+|\n+');
    return text.split(exp).where((s) => s.trim().isNotEmpty).toList();
  }

  bool _writeWavFile(String path, List<double> samples, int sampleRate) {
    try {
      final file = File(path);
      final int numSamples = samples.length;
      final int numChannels = 1;
      final int bitsPerSample = 16;
      final int byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
      final int blockAlign = numChannels * (bitsPerSample ~/ 8);
      final int subChunk2Size = numSamples * numChannels * (bitsPerSample ~/ 8);
      final int chunkSize = 36 + subChunk2Size;

      final bytes = <int>[];

      // RIFF header
      _addString(bytes, 'RIFF');
      _addInt32(bytes, chunkSize);
      _addString(bytes, 'WAVE');

      // fmt chunk
      _addString(bytes, 'fmt ');
      _addInt32(bytes, 16);
      _addInt16(bytes, 1);
      _addInt16(bytes, numChannels);
      _addInt32(bytes, sampleRate);
      _addInt32(bytes, byteRate);
      _addInt16(bytes, blockAlign);
      _addInt16(bytes, bitsPerSample);

      // data chunk
      _addString(bytes, 'data');
      _addInt32(bytes, subChunk2Size);

      for (final sample in samples) {
        var s = sample;
        if (s > 1.0) s = 1.0;
        if (s < -1.0) s = -1.0;
        final int val = (s * 32767).toInt();
        _addInt16(bytes, val);
      }

      file.writeAsBytesSync(bytes);
      return true;
    } catch (e) {
      print("[TTS] WAV Write Error: $e");
      return false;
    }
  }

  void _addString(List<int> bytes, String s) {
    bytes.addAll(s.codeUnits);
  }

  void _addInt32(List<int> bytes, int value) {
    bytes.add(value & 0xff);
    bytes.add((value >> 8) & 0xff);
    bytes.add((value >> 16) & 0xff);
    bytes.add((value >> 24) & 0xff);
  }

  void _addInt16(List<int> bytes, int value) {
    bytes.add(value & 0xff);
    bytes.add((value >> 8) & 0xff);
  }

  bool get hasAdvancedEngine => _isInitialized;
}
