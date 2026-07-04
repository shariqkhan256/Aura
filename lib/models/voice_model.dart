import 'dart:ui';
import 'package:flutter/material.dart';

/// Model representing a character voice option with optimized Piper parameters
class VoiceCharacter {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  
  // Optimized Piper/VITS Parameters
  final double lengthScale;   // Determines speed (inverse of playback rate)
  final double noiseScale;    // Controls variety/emotion (realism)
  final double noiseScaleW;   // Controls duration variety (stochasticity)
  final double pitchScale;    // Target pitch adjustment

  const VoiceCharacter({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.lengthScale = 1.0,
    this.noiseScale = 0.667,
    this.noiseScaleW = 0.8,
    this.pitchScale = 1.0,
  });

  /// Optimized Voice Profiles as per Recommended Guidelines
  static const List<VoiceCharacter> characters = [
    // 1. Liam - Warm & Natural Male
    VoiceCharacter(
      id: 'liam',
      name: 'Liam',
      description: 'Warm & Natural',
      icon: Icons.face_rounded,
      color: Color(0xFF3F51B5),
      lengthScale: 1.00,
      noiseScale: 0.40,
      noiseScaleW: 0.80,
      pitchScale: 1.00,
    ),

    // 2. Robin - Young & Energetic
    VoiceCharacter(
      id: 'robin',
      name: 'Robin',
      description: 'Lively & Bright', 
      icon: Icons.bolt_rounded,
      color: Color(0xFFD32F2F),
      lengthScale: 0.95,
      noiseScale: 0.48,
      noiseScaleW: 0.95,
      pitchScale: 1.05,
    ),

    // 3. Lily - Small, Sweet, Expressive
    VoiceCharacter(
      id: 'lily',
      name: 'Lily',
      description: 'Small & Sweet',
      icon: Icons.child_care_rounded,
      color: Color(0xFFE91E63),
      lengthScale: 1.02,
      noiseScale: 0.52,
      noiseScaleW: 1.00,
      pitchScale: 1.10,
    ),

    // 4. Elsa - Professional, Calm, Deep
    VoiceCharacter(
      id: 'elsa',
      name: 'Elsa',
      description: 'Professional & Calm',
      icon: Icons.face_3_rounded,
      color: Color(0xFF607D8B),
      lengthScale: 1.05,
      noiseScale: 0.35,
      noiseScaleW: 0.75,
      pitchScale: 0.95,
    ),

    // 5. Emma - Soft & Feminine
    VoiceCharacter(
      id: 'emma',
      name: 'Emma',
      description: 'Soft & Feminine',
      icon: Icons.face_4_rounded,
      color: Color(0xFFFF9800),
      lengthScale: 1.03,
      noiseScale: 0.45,
      noiseScaleW: 0.90,
      pitchScale: 1.08,
    ),
  ];

  static VoiceCharacter getById(String id) {
    return characters.firstWhere(
      (c) => c.id == id,
      orElse: () => characters.first,
    );
  }
}
