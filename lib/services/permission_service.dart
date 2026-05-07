import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request camera permission and return true if granted
  Future<PermissionResult> requestCameraPermission() async {
    try {
      // Check current status
      final status = await Permission.camera.status;

      if (status.isGranted) {
        return PermissionResult.granted;
      }

      if (status.isPermanentlyDenied) {
        return PermissionResult.permanentlyDenied;
      }

      // Request permission
      final result = await Permission.camera.request();

      if (result.isGranted) {
        return PermissionResult.granted;
      } else if (result.isPermanentlyDenied) {
        return PermissionResult.permanentlyDenied;
      } else {
        return PermissionResult.denied;
      }
    } catch (e) {
      debugPrint('Error requesting camera permission: $e');
      return PermissionResult.error;
    }
  }

  /// Request photo library permission
  Future<PermissionResult> requestPhotoLibraryPermission() async {
    try {
      final status = await Permission.photos.status;

      if (status.isGranted || status.isLimited) {
        return PermissionResult.granted;
      }

      if (status.isPermanentlyDenied) {
        return PermissionResult.permanentlyDenied;
      }

      final result = await Permission.photos.request();

      if (result.isGranted || result.isLimited) {
        return PermissionResult.granted;
      } else if (result.isPermanentlyDenied) {
        return PermissionResult.permanentlyDenied;
      } else {
        return PermissionResult.denied;
      }
    } catch (e) {
      debugPrint('Error requesting photo library permission: $e');
      return PermissionResult.error;
    }
  }

  /// Check if camera permission is granted
  Future<bool> isCameraPermissionGranted() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Open app settings
  Future<bool> openSettings() async {
    return await openAppSettings();
  }
}

enum PermissionResult {
  granted,
  denied,
  permanentlyDenied,
  error,
}
