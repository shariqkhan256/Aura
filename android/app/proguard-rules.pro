# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Sherpa ONNX (Keep ONLY TTS native bindings, strip ASR)
-keep class com.k2fsa.sherpa.onnx.OfflineTts* { *; }
-keep class com.k2fsa.sherpa.onnx.GeneratedAudio { *; }
-keep class com.k2fsa.sherpa.onnx.SherpaOnnx { *; }
-keep class com.sun.jna.** { *; }
-dontwarn com.sun.jna.**
-dontwarn com.k2fsa.sherpa.onnx.**

# Flutter Play Store (Fix for R8 compilation errors)
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# AudioPlayers
-keep class com.ryanheise.audioservice.** { *; }

# Keep line numbers for debugging stack traces
-keepattributes SourceFile,LineNumberTable
