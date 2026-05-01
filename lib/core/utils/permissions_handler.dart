import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsHandler {
  // static Future<bool> requestStoragePermission(BuildContext context) async {
  //   if (!Platform.isAndroid) return true;

  //   bool permissionGranted = false;

  //   Map<Permission, PermissionStatus> statuses = await [
  //     Permission.storage,
  //     Permission.audio,
  //   ].request();

  //   if (statuses[Permission.storage] == PermissionStatus.granted ||
  //       statuses[Permission.audio] == PermissionStatus.granted) {
  //     permissionGranted = true;
  //   }

  //   if (!permissionGranted) {
  //     if (statuses[Permission.storage] == PermissionStatus.permanentlyDenied ||
  //         statuses[Permission.audio] == PermissionStatus.permanentlyDenied) {
  //       if (context.mounted) {
  //         _showSettingsDialog(
  //           context,
  //           "Storage Permission Required",
  //           "This app requires access to your storage to create ringtones. Please enable it in settings.",
  //         );
  //       }
  //     }
  //   }

  //   return permissionGranted;
  // }

  static Future<bool> requestStoragePermission(BuildContext context) async {
    if (!Platform.isAndroid) return true;

    // 1. Try the old Android 10/11 permission first (For your Redmi Note 8 Pro)
    PermissionStatus storageStatus = await Permission.storage.request();
    if (storageStatus.isGranted) return true;

    // 2. If the first one isn't applicable, try the new Android 13+ permission
    PermissionStatus audioStatus = await Permission.audio.request();
    if (audioStatus.isGranted) return true;

    // 3. If both fail, trigger your excellent settings dialog
    if (storageStatus.isPermanentlyDenied || audioStatus.isPermanentlyDenied) {
      if (context.mounted) {
        _showSettingsDialog(
          context,
          "Storage Permission Required",
          "This app requires access to your storage to create ringtones. Please enable it in settings."
        );
      }
    }

    return false;
  }

  static Future<bool> requestMicrophonePermission(BuildContext context) async {
    PermissionStatus status = await Permission.microphone.request();

    if (status == PermissionStatus.granted) {
      return true;
    }

    if (status == PermissionStatus.permanentlyDenied) {
      if (context.mounted) {
        _showSettingsDialog(
          context,
          "Microphone Permission Required",
          "This app requires access to your microphone to record audio. Please enable it in settings.",
        );
      }
    }

    return false;
  }

  static void _showSettingsDialog(
    BuildContext context,
    String title,
    String content,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // FIXED: Now it dynamically uses the text you pass into the function!
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
              child: const Text("Open Settings"),
            ),
          ],
        );
      },
    );
  }
}
