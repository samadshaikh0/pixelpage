import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'view_images.dart';
import 'qr_decoder.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController _cameraController = MobileScannerController();
  bool _isScanning = true;
  final String _qrPrefix = "BsFyKhSwTa";
  String? _directoryStatus;
  String? _createdDirectoryPath;

  List<File> _images = [];

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }



  Future<bool> _requestStoragePermission() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 33) {
      final status = await [Permission.photos, Permission.videos].request();
      return status[Permission.photos]!.isGranted || status[Permission.videos]!.isGranted;
    } else if (sdkInt >= 30) {
      return await Permission.manageExternalStorage.request().isGranted;
    } else {
      return await Permission.storage.request().isGranted;
    }
  }

  Future<Directory?> _getBaseDirectory() async {
    final baseDir = await getExternalStorageDirectory();
    if (baseDir == null) {
      _setStatus('Could not access storage directory');
      return null;
    }
    return baseDir;
  }

  Future<void> _createFolderStructure(String bookId, String qrId) async {
    if (!await _requestStoragePermission()) {
      _setStatus('Storage permission denied');
      return;
    }

    final baseDir = await _getBaseDirectory();
    if (baseDir == null) return;

    try {
      final bookFolder = Directory('${baseDir.path}/$bookId');
      if (!await bookFolder.exists()) {
        await bookFolder.create(recursive: true);
      }

      final qrFolder = Directory('${bookFolder.path}/$qrId');
      if (!await qrFolder.exists()) {
        await qrFolder.create(recursive: true);
      }

      _createdDirectoryPath = qrFolder.path;
      _setStatus('Scanned Successfully!');
    } catch (e) {
      _setStatus('Error creating folders: $e');
    }
  }

  Future<List<File>> _loadImages(String bookId, String qrId) async {
    final baseDir = await _getBaseDirectory();
    if (baseDir == null) return [];

    try {
      final dir = Directory('${baseDir.path}/$bookId/$qrId');
      if (!await dir.exists()) {
        _setStatus('Images directory does not exist');
        return [];
      }

      return dir
          .listSync()
          .whereType<File>()
          .where((file) => const ['.jpg', '.jpeg', '.png']
          .any((ext) => file.path.toLowerCase().endsWith(ext)))
          .toList();
    } catch (e) {
      _setStatus('Error loading images: $e');
      return [];
    }
  }

  void _handleDetection(BarcodeCapture barcodeCapture) async {
    if (!_isScanning) return;

    final encryptedText = barcodeCapture.barcodes.first.rawValue ?? '';
    final data = decryptQRData(encryptedText);

    final bookId = data?['bookId'];
    final qrId = data?['qrId'];

    if (data == null || !data.containsKey('bookId') || !data.containsKey('qrId')) {
      _showInvalidQrDialog("Invalid or tampered QR Code. book ID : $bookId\nQR id : $qrId");
      return;
    }


    if (bookId.toString().isEmpty || qrId.toString().isEmpty) {
      _showInvalidQrDialog("Book ID or QR ID is missing.");
      return;
    }

    _isScanning = false;
    await _cameraController.stop();
    await _createFolderStructure(bookId, qrId);
    final loadedImages = await _loadImages(bookId, qrId);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (_, __, ___) =>
              ViewImages(images: loadedImages, qrId: qrId, bookId: bookId),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    }
  }


  void _showInvalidQrDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.deepOrange, size: 28),
            SizedBox(width: 8),
            Text(
              'Invalid QR Code',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
            },
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              _isScanning = true; // resume scanning
            },
            child: const Text(
              'RESCAN',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _setStatus(String status) {
    if (mounted) {
      setState(() => _directoryStatus = status);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text(
          'QR Scanner',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ⚠ Warning Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                border: Border.all(color: const Color(0xFFFFEEBA)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Scan QRs only from the book",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            // QR Scanner box
            Expanded(
              flex: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: MobileScanner(
                    controller: _cameraController,
                    onDetect: _handleDetection,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Status Text
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Icon(Icons.qr_code_scanner, size: 40, color: Colors.deepPurple),
                  const SizedBox(height: 10),
                  const Text(
                    'Point your camera at a QR code',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _directoryStatus ?? '',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
