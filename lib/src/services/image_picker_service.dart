import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();
  final Color primaryColor = const Color(0xFF007BFF);

  // 🟢 Permission check with dialog support
  Future<bool> checkAndRequestPermissions({
    required BuildContext context,
    bool forSaving = false,
  }) async {
    if (!Platform.isAndroid) return true;

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    List<Permission> permissions = [];
    if (forSaving && sdkInt < 33) {
      permissions.add(Permission.storage);
    } else if (!forSaving) {
      permissions.add(sdkInt >= 33 ? Permission.photos : Permission.storage);
    }

    bool allGranted = true;
    for (var permission in permissions) {
      var status = await permission.status;
      if (!status.isGranted) {
        status = await permission.request();
        if (!status.isGranted) {
          if (status.isPermanentlyDenied) {
            await _showSettingsDialog(context);
          } else {
            await _showPermissionRationaleDialog(context, permission);
          }
          allGranted = false;
        }
      }
    }

    return allGranted;
  }

  // ℹ️ Rationale Dialog
  Future<void> _showPermissionRationaleDialog(
      BuildContext context, Permission permission) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange),
            const SizedBox(width: 8),
            Text('Permission Required', style: TextStyle(color: primaryColor)),
          ],
        ),
        content: Text(
          'Pixel Page needs ${permission == Permission.photos ? "gallery" : "storage"} access to continue. Please allow permission.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  // ⚠️ Settings Dialog
  Future<void> _showSettingsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.settings_outlined, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text('Permission Denied', style: TextStyle(color: primaryColor)),
          ],
        ),
        content: const Text(
          'Storage or photo access is permanently denied. Please enable it manually in your app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: Text('Open Settings', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  // 📸 Pick Image
  Future<List<File>?> pickImages({
    required BuildContext context,
    required ImageSource source,
  }) async {
    try {
      if (source == ImageSource.gallery &&
          !await checkAndRequestPermissions(context: context)) {
        return null;
      }

      if (source == ImageSource.gallery) {
        final List<XFile>? pickedFiles = await _picker.pickMultiImage();
        if (pickedFiles != null && pickedFiles.isNotEmpty) {
          return pickedFiles.map((xfile) => File(xfile.path)).toList();
        }
      } else {
        final XFile? pickedFile = await _picker.pickImage(source: source);
        if (pickedFile != null) {
          return [File(pickedFile.path)];
        }
      }

      _showSnackBar(context, 'No images selected.', icon: Icons.info_outline);
      return null;
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showSnackBar(context, 'Error picking image.', icon: Icons.error, isError: true);
      return null;
    }
  }

  // 💾 Save Image
  Future<List<File>?> saveImages({
    required BuildContext context,
    required List<File> images,
    required String bookId,
    required String qrId,
  }) async {
    if (images.isEmpty || qrId.isEmpty || bookId.isEmpty) {
      _showSnackBar(context, 'Invalid QR or Book ID.', icon: Icons.warning_amber, isError: true);
      return null;
    }

    try {
      if (!await checkAndRequestPermissions(context: context, forSaving: true)) {
        _showSnackBar(context, 'Permission denied. Cannot save.', icon: Icons.block, isError: true);
        return null;
      }

      final baseDir = await getExternalStorageDirectory();
      if (baseDir == null) {
        _showSnackBar(context, 'Storage not accessible.', icon: Icons.sd_storage, isError: true);
        return null;
      }

      final dir = Directory('${baseDir.path}/$bookId/$qrId');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final List<File> savedFiles = [];
      for (final image in images) {
        final fileName =
            'image_${DateTime.now().millisecondsSinceEpoch}_${images.indexOf(image)}.jpg';
        final newImagePath = '${dir.path}/$fileName';
        final newFile = File(newImagePath);
        await newFile.writeAsBytes(await image.readAsBytes());
        savedFiles.add(newFile);
      }

      final allImages = dir
          .listSync()
          .whereType<File>()
          .where((file) =>
      file.path.toLowerCase().endsWith('.jpg') ||
          file.path.toLowerCase().endsWith('.jpeg') ||
          file.path.toLowerCase().endsWith('.png'))
          .toList();

      _showSnackBar(context, 'Images saved successfully!', icon: Icons.check_circle_outline);
      return allImages;
    } catch (e) {
      debugPrint('SaveImages Error: $e');
      _showSnackBar(context, 'Failed to save images.', icon: Icons.error_outline, isError: true);
      return null;
    }
  }

  // 🎯 Fancy SnackBar with icon support
  void _showSnackBar(BuildContext context, String message,
      {IconData icon = Icons.info, bool isError = false}) {
    if (!context.mounted) return;

    final bgColor = isError ? Colors.redAccent : primaryColor;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
