import 'package:audioplayers/audioplayers.dart';
import 'dart:io';

/// Service for playing audio files offline
class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() {
    _instance._setupListeners();
    return _instance;
  }
  AudioPlayerService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentFilePath;
  bool _isPlaying = false;
  bool _isPaused = false;
  bool _listenersSetup = false;

  /// Get current playback state
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  String? get currentFilePath => _currentFilePath;

  void _setupListeners() {
    if (_listenersSetup) return;
    _listenersSetup = true;
    
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.playing) {
        _isPlaying = true;
        _isPaused = false;
      } else if (state == PlayerState.paused) {
        _isPlaying = false;
        _isPaused = true;
      } else if (state == PlayerState.completed) {
        _isPlaying = false;
        _isPaused = false;
      } else {
        _isPlaying = false;
        _isPaused = false;
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _isPaused = false;
    });
  }

  /// Play audio file from local path
  Future<void> playFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Audio file does not exist');
      }

      // Stop current playback if any
      if (_isPlaying || _isPaused) {
        await stop();
      }

      _currentFilePath = filePath;
      
      // Play the file
      await _audioPlayer.play(DeviceFileSource(filePath));
      _isPlaying = true;
      _isPaused = false;
    } catch (e) {
      throw Exception('Failed to play audio: $e');
    }
  }

  /// Pause current playback
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
      _isPaused = true;
      _isPlaying = false;
    } catch (e) {
      throw Exception('Failed to pause audio: $e');
    }
  }

  /// Resume paused playback
  Future<void> resume() async {
    try {
      await _audioPlayer.resume();
      _isPlaying = true;
      _isPaused = false;
    } catch (e) {
      throw Exception('Failed to resume audio: $e');
    }
  }

  /// Stop current playback
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      _isPaused = false;
      _currentFilePath = null;
    } catch (e) {
      throw Exception('Failed to stop audio: $e');
    }
  }

  /// Get current position
  Future<Duration> getPosition() async {
    return await _audioPlayer.getCurrentPosition() ?? Duration.zero;
  }

  /// Get total duration
  Future<Duration> getDuration() async {
    return await _audioPlayer.getDuration() ?? Duration.zero;
  }

  /// Seek to specific position
  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      throw Exception('Failed to seek: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _audioPlayer.dispose();
  }
}
