 import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/audio_storage_service.dart';
import '../services/audio_player_service.dart';
import '../services/theme_service.dart';

class AudioListScreen extends StatefulWidget {
  const AudioListScreen({super.key});

  @override
  State<AudioListScreen> createState() => _AudioListScreenState();
}

class _AudioListScreenState extends State<AudioListScreen> 
    with SingleTickerProviderStateMixin {
  final AudioStorageService _storageService = AudioStorageService();
  final AudioPlayerService _playerService = AudioPlayerService();
  
  List<AudioMetadata> _audioFiles = [];
  bool _isLoading = true;
  String? _currentlyPlayingPath;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Selection mode state
  bool _isSelectionMode = false;
  final Set<String> _selectedPaths = {};

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadAudioFiles();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  Future<void> _loadAudioFiles() async {
    setState(() => _isLoading = true);

    try {
      final files = await _storageService.getSavedAudioMetadata();
      setState(() {
        _audioFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Failed to load library', isError: true);
    }
  }

  Future<void> _playAudio(AudioMetadata audio) async {
    if (_currentlyPlayingPath == audio.filePath && _playerService.isPlaying) {
      await _playerService.stop();
      setState(() => _currentlyPlayingPath = null);
    } else {
      await _playerService.playFile(audio.filePath);
      setState(() => _currentlyPlayingPath = audio.filePath);
      _monitorPlayback();
    }
  }

  void _monitorPlayback() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        if (!_playerService.isPlaying && !_playerService.isPaused) {
          setState(() => _currentlyPlayingPath = null);
        } else if (_playerService.isPlaying) {
          _monitorPlayback();
        }
      }
    });
  }

  void _toggleSelection(String path) {
    setState(() {
      if (_selectedPaths.contains(path)) {
        _selectedPaths.remove(path);
        if (_selectedPaths.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedPaths.add(path);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedPaths.length == _audioFiles.length) {
        _selectedPaths.clear();
        _isSelectionMode = false;
      } else {
        _selectedPaths.clear();
        for (var file in _audioFiles) {
          _selectedPaths.add(file.filePath);
        }
        _isSelectionMode = true;
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedPaths.isEmpty) return;

    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text('Delete ${_selectedPaths.length} items?'),
        content: Text('This action cannot be undone.', 
           style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: theme.colorScheme.secondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.deleteMultipleAudioFiles(_selectedPaths.toList());
      setState(() {
        _isSelectionMode = false;
        _selectedPaths.clear();
      });
      _loadAudioFiles();
      _showSnackBar('Deleted successfully');
    }
  }

  Future<void> _deleteAudio(AudioMetadata audio) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: const Text('Delete Recording?'),
        content: Text('This action cannot be undone.', 
           style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: theme.colorScheme.secondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.deleteAudioFile(audio.filePath);
      _loadAudioFiles();
      _showSnackBar('Deleted successfully');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
     final theme = Theme.of(context);
     ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : theme.colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: _isSelectionMode 
          ? IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => setState(() {
                _isSelectionMode = false;
                _selectedPaths.clear();
              }),
            )
          : null,
        title: Text(_isSelectionMode ? "${_selectedPaths.length} Selected" : "Audio Library"),
        actions: [
          if (_isSelectionMode) ...[
            // IconButton(
            //   icon: Icon(
            //     _selectedPaths.length == _audioFiles.length
            //       ? Icons.deselect_rounded
            //       : Icons.select_all_rounded
            //   ),
            //   onPressed: _selectAll,
            //   tooltip: 'Select All',
            // ),
            IconButton(
              icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
              onPressed: _deleteSelected,
              tooltip: 'Delete Selected',
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadAudioFiles,
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.secondary))
          : _audioFiles.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.music_off_rounded, size: 64, color: theme.disabledColor.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text(
                      "Your library is empty",
                      style: TextStyle(color: theme.disabledColor),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: _audioFiles.length + (_isSelectionMode ? 1 : 0),
                separatorBuilder: (_, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (_isSelectionMode && index == 0) {
                    final allSelected = _selectedPaths.length == _audioFiles.length;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: _selectAll,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          child: Row(
                            children: [
                              Checkbox(
                                value: allSelected,
                                onChanged: (_) => _selectAll(),
                                activeColor: theme.colorScheme.secondary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Select All",
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "${_selectedPaths.length} / ${_audioFiles.length}",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final audio = _audioFiles[_isSelectionMode ? index - 1 : index];
                  final isPlaying = _currentlyPlayingPath == audio.filePath;
                  final accent = theme.colorScheme.secondary;
                  final cardColor = theme.cardColor;

                  final isSelected = _selectedPaths.contains(audio.filePath);

                  return GestureDetector(
                    onLongPress: () {
                      if (!_isSelectionMode) {
                        setState(() {
                          _isSelectionMode = true;
                          _selectedPaths.add(audio.filePath);
                        });
                      }
                    },
                    onTap: () {
                      if (_isSelectionMode) {
                        _toggleSelection(audio.filePath);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? accent.withOpacity(0.05) : cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: (isPlaying || isSelected)
                            ? Border.all(color: accent, width: 2)
                            : null,
                        boxShadow: [
                           BoxShadow(
                             color: Colors.black.withOpacity(0.05),
                             blurRadius: 8,
                             offset: const Offset(0, 2),
                           )
                        ],
                      ),
                      child: Row(
                        children: [
                          if (_isSelectionMode) ...[
                            Checkbox(
                              value: isSelected,
                              onChanged: (_) => _toggleSelection(audio.filePath),
                              activeColor: accent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            const SizedBox(width: 8),
                          ],
                          GestureDetector(
                            onTap: _isSelectionMode ? null : () => _playAudio(audio),
                            child: Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                color: isPlaying ? accent : accent.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: isPlaying ? Colors.white : accent,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  audio.fileName,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isPlaying ? accent : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${audio.formattedDate} • ${audio.formattedSize}",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!_isSelectionMode)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.download_rounded, color: accent, size: 22),
                                  tooltip: 'Save to Downloads',
                                  onPressed: () async {
                                    final success = await _storageService.exportToPublicDownloads(
                                      audio.filePath, 
                                      audio.fileName
                                    );
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            success 
                                              ? 'Saved to Downloads folder' 
                                              : 'Failed to save file'
                                          ),
                                          backgroundColor: success ? theme.colorScheme.secondary : Colors.redAccent,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, color: theme.disabledColor, size: 22),
                                  onPressed: () => _deleteAudio(audio),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
