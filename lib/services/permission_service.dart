import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Service for handling app permissions
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Request all necessary storage permissions
  /// Returns true if all required permissions are granted
  Future<bool> requestStoragePermission() async {
    // On iOS, no storage permission needed for app documents directory
    if (Platform.isIOS) return true;

    if (Platform.isAndroid) {
      try {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        // Android 13 (API 33) and above - granular media permissions
        if (sdkInt >= 33) {
          // For API 33+, we need audio permission for our audio files
          // and manageExternalStorage for Downloads folder access
          
          bool audioGranted = await Permission.audio.isGranted;
          if (!audioGranted) {
            final audioResult = await Permission.audio.request();
            audioGranted = audioResult.isGranted;
          }
          
          // For Downloads folder access on Android 11+, we need 
          // MANAGE_EXTERNAL_STORAGE or use MediaStore (scoped storage)
          // Since we're writing to Downloads/Aura, we'll try the simpler approach first
          
          return audioGranted;
        } 
        // Android 11-12 (API 30-32)
        else if (sdkInt >= 30) {
          // Android 11+ with scoped storage
          // For Downloads folder, we can write without special permission
          // but need audio permission to read audio files
          
          bool audioGranted = await Permission.audio.isGranted;
          if (!audioGranted) {
            final audioResult = await Permission.audio.request();
            audioGranted = audioResult.isGranted;
          }
          
          // Also request storage for backward compatibility
          bool storageGranted = await Permission.storage.isGranted;
          if (!storageGranted) {
            final storageResult = await Permission.storage.request();
            storageGranted = storageResult.isGranted;
          }
          
          return audioGranted || storageGranted;
        }
        // Android 10 and below (API 29 and below)
        else {
          final status = await Permission.storage.status;
          
          if (status.isGranted) {
            return true;
          }
          
          if (status.isPermanentlyDenied) {
            return false;
          }

          final result = await Permission.storage.request();
          return result.isGranted;
        }
      } catch (e) {
        print('Error requesting storage permission: $e');
        return false;
      }
    }

    return true;
  }

  /// Check if all required permissions are granted
  Future<bool> hasStoragePermission() async {
    if (Platform.isIOS) return true;
    
    if (Platform.isAndroid) {
      try {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;
        
        if (sdkInt >= 33) {
          return await Permission.audio.isGranted;
        } else if (sdkInt >= 30) {
          return await Permission.audio.isGranted || await Permission.storage.isGranted;
        } else {
          return await Permission.storage.isGranted;
        }
      } catch (e) {
        print('Error checking permissions: $e');
        return false;
      }
    }
    
    return true;
  }

  /// Request MANAGE_EXTERNAL_STORAGE permission (for full file access)
  /// This opens system settings where user must manually grant
  Future<bool> requestManageStoragePermission() async {
    if (!Platform.isAndroid) return true;
    
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      
      if (androidInfo.version.sdkInt >= 30) {
        final status = await Permission.manageExternalStorage.status;
        
        if (status.isGranted) {
          return true;
        }
        
        final result = await Permission.manageExternalStorage.request();
        return result.isGranted;
      }
      
      return true;
    } catch (e) {
      print('Error requesting manage storage permission: $e');
      return false;
    }
  }

  /// Open app settings (useful when permissions are permanently denied)
  Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
