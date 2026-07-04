import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/tts_service.dart';
import 'services/audio_storage_service.dart';
import 'services/audio_player_service.dart';
import 'services/theme_service.dart';
import 'services/permission_service.dart';
import 'services/model_service.dart';
import 'screens/audio_list_screen.dart';
import 'screens/settings_screen.dart';
import 'models/voice_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AuraApp());
}

class AuraApp extends StatefulWidget {
  const AuraApp({super.key});

  @override
  State<AuraApp> createState() => _AuraAppState();
}

class _AuraAppState extends State<AuraApp> {
  final ThemeService _themeService = ThemeService();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeService,
      builder: (context, _) {
        return MaterialApp(
          title: 'Aura',
          debugShowCheckedModeBanner: false,
          theme: _themeService.getLightTheme(),
          darkTheme: _themeService.getDarkTheme(),
          themeMode: _themeService.isDarkMode 
              ? ThemeMode.dark 
              : ThemeMode.light,
          scrollBehavior: SmoothScrollBehavior(),
          home: HomePage(themeService: _themeService),
        );
      },
    );
  }
}

class SmoothScrollBehavior extends MaterialScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}

class HomePage extends StatefulWidget {
  final ThemeService themeService;

  const HomePage({super.key, required this.themeService});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> 
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final TTSService _ttsService = TTSService();
  final AudioStorageService _storageService = AudioStorageService();
  final AudioPlayerService _playerService = AudioPlayerService();
  final PermissionService _permissionService = PermissionService();
  final ModelService _modelService = ModelService();

  bool _isGenerating = false;
  double _generationProgress = 0.0;
  int _audioCount = 0;
  VoiceCharacter _selectedVoice = VoiceCharacter.characters.first;
  
  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadAudioCount();
    
    // Setup simple fade in
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    );
    
    _animationController.forward();
  }

  Future<void> _initializeServices() async {
    await _permissionService.requestStoragePermission();
    
    // Check for Model
    final modelPath = await _modelService.getModelPath();
    if (modelPath == null) {
      if (mounted) {
         _showDownloadDialog();
      }
    } else {
      await _ttsService.initialize();
    }
  }

  Future<void> _showDownloadDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        double progress = 0.0;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            
            // Trigger download once
            if (progress == 0.0) {
               _modelService.downloadModel((p) {
                 setDialogState(() => progress = p);
                  if (p >= 1.0) {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      _ttsService.initialize();
                      _showSnackBar("High Quality AI Voice Model Installed!");
                    }
                  }
                }).catchError((e) {
                   if (context.mounted) {
                     Navigator.of(context).pop();
                     _showSnackBar("Download Failed: $e", isError: true);
                   }
                });
            }

            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              title: const Text("Installing AI Voice Engine"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   const Text("Downloading 50MB 'Ultra-Realistic' English Piper Model..."),
                   const SizedBox(height: 20),
                   LinearProgressIndicator(
                     value: progress, 
                     color: Theme.of(context).colorScheme.secondary,
                     backgroundColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                   ),
                   const SizedBox(height: 10),
                   Text("${(progress * 100).toInt()}%"),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadAudioCount() async {
    try {
      final count = await _storageService.getAudioCount();
      setState(() => _audioCount = count);
    } catch (_) {}
  }

  Future<void> _generateAudio() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _showSnackBar('Please enter some text first', isError: true);
      return;
    }

    // Data-driven crash prevention: 
    // The underlying Sherpa-ONNX model (en_US) crashes on non-Latin scripts (e.g., Urdu/Arabic).
    // We strictly filter for supported characters (Latin + Standard Punctuation)
    if (!_isTextSupported(text)) {
      _showSnackBar('Unsupported Language: Please use English text only.', isError: true);
      return;
    }

    // Hide keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isGenerating = true;
    });

    try {
      await _ttsService.setVoice(_selectedVoice);
      
      final auraDir = await _storageService.getDownloadsAuraDirectory();
      final filename = await _storageService.generateAudioFilename();
      final destPath = '${auraDir.path}/$filename';
      
      // Pass the VOICE object and progress callback
      final savedPath = await _ttsService.synthesizeToFile(
        text, 
        destPath, 
        voice: _selectedVoice,
        onProgress: (p) => setState(() => _generationProgress = p),
      );
      
      // Save metadata
      final savedFile = File(savedPath);
      final stat = await savedFile.stat();
      final metadata = AudioMetadata(
        filePath: savedPath,
        fileName: filename,
        createdAt: DateTime.now(),
        fileSize: stat.size,
      );
      
      final prefs = await SharedPreferences.getInstance();
      var list = prefs.getStringList('aura_audio_files') ?? [];
      list.insert(0, jsonEncode(metadata.toJson()));
      await prefs.setStringList('aura_audio_files', list);
      
      setState(() {
        _isGenerating = false;
        _generationProgress = 0.0;
      });
      await _loadAudioCount();
      _showSnackBar('Audio generated successfully');
      
    } catch (e) {
      if (mounted) {
         setState(() => _isGenerating = false);
         _showSnackBar('Failed: ${e.toString()}', isError: true); // Error 
      }
    }
  }

  bool _isTextSupported(String text) {
    // Only allow Latin-1 characters (English, some European) + standard punctuation.
    // Blocks Arabic, Hebrew, CJK, Devanagari, Emojis, etc. to prevent crash.
    final supportedRegex = RegExp(r'^[\u0000-\u00FF\u2000-\u206F\s]+$');
    return supportedRegex.hasMatch(text);
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textController.dispose();
    _playerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Core Palette
    final primaryBg = theme.scaffoldBackgroundColor;
    final surface = theme.cardColor;
    final accent = theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: primaryBg,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Aura"),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? accent.withValues(alpha: 0.15) : theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.mic_rounded, size: 16, color: accent),
            )
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => SettingsScreen(themeService: widget.themeService))
            ),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Voice Selector
              Text(
                "Voice Persona",
                style: theme.textTheme.titleMedium?.copyWith(
                   fontWeight: FontWeight.bold,
                   color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7)
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: VoiceCharacter.characters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final voice = VoiceCharacter.characters[index];
                    final isSelected = _selectedVoice.id == voice.id;
                    
                    return GestureDetector(
                      onTap: () {
                         setState(() => _selectedVoice = voice);
                         _ttsService.previewVoice(voice);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 90,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? accent 
                              : (isDark ? surface : theme.colorScheme.secondaryContainer.withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected 
                                ? accent 
                                : (isDark ? Colors.transparent : theme.colorScheme.secondary.withValues(alpha: 0.1)),
                            width: 2,
                          ),
                          boxShadow: [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              voice.icon,
                              size: 32,
                              color: isSelected ? Colors.white : theme.iconTheme.color?.withOpacity(0.6),
                            ),
                            const Spacer(),
                            Text(
                              voice.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Input Card
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: isDark ? surface : theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(24),
                  border: isDark 
                      ? null 
                      : Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.1), width: 1.5),
                  boxShadow: [],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        maxLines: null,
                        expands: true,
                        style: TextStyle(
                          fontSize: 18, 
                          height: 1.5,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                        decoration: const InputDecoration(
                          hintText: "What should I say?",
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          fillColor: Colors.transparent,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _textController,
                          builder: (context, value, child) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "${value.text.length} chars",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // CTA
              SizedBox(
                height: 64,
                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _generateAudio,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                    disabledBackgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.5),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _isGenerating 
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // const SizedBox(
                          //   width: 20, height: 20,
                          //   child: CircularProgressIndicator(
                          //     color: Colors.white,
                          //     strokeWidth: 2,
                          //   ),
                          // ),
                          const SizedBox(width: 16),
                          Text(
                            "Processing... ${(_generationProgress * 100).toInt()}%",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           const Icon(Icons.auto_awesome, color: Colors.white),
                           const SizedBox(width: 12),
                           const Text(
                             "Generate Voice",
                             style: TextStyle(
                               fontSize: 18,
                               fontWeight: FontWeight.bold,
                               color: Colors.white
                             ),
                           ),
                        ],
                    ),
                ),
              ),

              const SizedBox(height: 40),

              // Library Preview
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recent Creations",
                    style: theme.textTheme.titleMedium?.copyWith(
                       fontWeight: FontWeight.bold,
                       color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7)
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const AudioListScreen()
                      )).then((_) => _loadAudioCount());
                    },
                    child: Text(
                      "View All",
                      style: TextStyle(color: accent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),

              if (_audioCount == 0)
                Container(
                  padding: const EdgeInsets.all(24),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.graphic_eq, size: 40, color: theme.disabledColor),
                      const SizedBox(height: 12),
                      Text(
                        "No audio generated yet", 
                        style: TextStyle(color: theme.disabledColor),
                      ),
                    ],
                  ),
                )
              else
                GestureDetector(
                  onTap: () {
                     Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const AudioListScreen()
                      )).then((_) => _loadAudioCount());
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? surface : theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                      border: isDark 
                          ? null 
                          : Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.1)),
                      boxShadow: [],
                    ),
                    child: Row(
                       children: [
                          Container(
                             padding: const EdgeInsets.all(12),
                             // decoration: BoxDecoration(
                             //   color: accent.withValues(alpha: 0.1),
                             //   borderRadius: BorderRadius.circular(14),
                             // ),
                             child: Icon(Icons.library_music_rounded, color: accent),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                  Text(
                                    "Library",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  Text(
                                    "$_audioCount files available",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                                    ),
                                  ),
                               ],
                             ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, size: 16, color: theme.disabledColor),
                       ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
