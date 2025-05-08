import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../services/image_picker_service.dart';

class ViewImages extends StatefulWidget {
  final List<File> images;
  final String qrId;
  final String bookId;
  const ViewImages({
    super.key,
    required this.images,
    required this.qrId,
    required this.bookId,
  });

  @override
  State<ViewImages> createState() => _ViewImagesState();
}

class _ViewImagesState extends State<ViewImages> {
  List<File> _images = [];
  bool deleteMode = false;
  bool shareMode = false;
  bool _isLoading = false;
  final Set<File> selectedImages = {};
  final ImagePickerService _pickerService = ImagePickerService();

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.images);
  }

  void _showStyledSnackBar(String message, {IconData icon = Icons.info, bool isError = false}) {
    final backgroundColor = isError ? Colors.redAccent : Colors.deepPurple;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        duration: const Duration(seconds: 3),
        backgroundColor: backgroundColor,
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }

  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.grey[100],
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.deepPurple),
              title: const Text(
                'Camera',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _pickAndSaveImages(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.deepPurple),
              title: const Text(
                'Gallery',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _pickAndSaveImages(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.grey),
              title: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSaveImages(ImageSource source) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      final images = await _pickerService.pickImages(
        context: context,
        source: source,
      );
      if (images != null && images.isNotEmpty) {
        debugPrint('Picked ${images.length} images');
        final savedImages = await _pickerService.saveImages(
          context: context,
          images: images,
          bookId: widget.bookId,
          qrId: widget.qrId,
        );
        if (savedImages != null && mounted) {
          setState(() {
            _images = savedImages;
            debugPrint('Updated UI with ${_images.length} images');
          });
          _showStyledSnackBar('Images saved successfully!', icon: Icons.check_circle_outline);
        } else {
          debugPrint('No images saved');
        }
      } else {
        debugPrint('No images picked');
      }
    } catch (e) {
      debugPrint('Error in pickAndSaveImages: $e');
      if (mounted) {
        _showStyledSnackBar('Error processing images: $e', icon: Icons.error_outline, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _shareSelectedImages() async {
    if (selectedImages.isEmpty || _isLoading) return;

    setState(() => _isLoading = true);
    try {
      final externalDir = await getApplicationDocumentsDirectory();
      List<String> sharePaths = [];

      for (var file in selectedImages) {
        final newPath = '${externalDir.path}/${file.path.split('/').last}';
        final sharedCopy = await file.copy(newPath);
        sharePaths.add(sharedCopy.path);
      }

      await Share.shareFiles(sharePaths);
      setState(() {
        selectedImages.clear();
        shareMode = false;
      });
      _showStyledSnackBar('Images shared successfully!', icon: Icons.check_circle_outline);
    } catch (e) {
      debugPrint('Sharing error: $e');
      _showStyledSnackBar('Error sharing images: $e', icon: Icons.error_outline, isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _confirmAndDeleteSelected() async {
    if (selectedImages.isEmpty || _isLoading) return;

    bool? confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.deepOrange, size: 28),
            SizedBox(width: 8),
            Text(
              'Delete Images',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text('Are you sure you want to delete selected images?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'DELETE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        for (final file in selectedImages) {
          if (await file.exists()) {
            await file.delete();
            _images.remove(file);
          }
        }
        setState(() {
          selectedImages.clear();
          deleteMode = false;
        });
        _showStyledSnackBar('Images deleted successfully!', icon: Icons.check_circle_outline);
      } catch (e) {
        _showStyledSnackBar('Error deleting images: $e', icon: Icons.error_outline, isError: true);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text(
          'Images',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(shareMode ? Icons.close : Icons.share, color: Colors.white),
            onPressed: _isLoading
                ? null
                : () {
              setState(() {
                shareMode = !shareMode;
                deleteMode = false;
                selectedImages.clear();
              });
            },
          ),
          IconButton(
            icon: Icon(deleteMode ? Icons.close : Icons.delete, color: Colors.white),
            onPressed: _isLoading
                ? null
                : () {
              setState(() {
                deleteMode = !deleteMode;
                shareMode = false;
                selectedImages.clear();
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _showImageSourceBottomSheet,
        backgroundColor: Colors.deepPurple,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.add_a_photo, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: Stack(
        children: [
          _images.isEmpty
              ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No images found for this QR',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          )
              : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _images.length,
            itemBuilder: (context, index) {
              final image = _images[index];
              final isSelected = selectedImages.contains(image);

              return GestureDetector(
                onTap: _isLoading
                    ? null
                    : () {
                  if (shareMode || deleteMode) {
                    setState(() {
                      if (isSelected) {
                        selectedImages.remove(image);
                      } else {
                        selectedImages.add(image);
                      }
                    });
                  } else {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 250),
                        pageBuilder: (_, __, ___) => ImageViewerPage(
                          images: _images,
                          initialIndex: index,
                        ),
                        transitionsBuilder: (_, animation, __, child) =>
                            FadeTransition(opacity: animation, child: child),
                      ),
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: isSelected
                        ? Border.all(color: Colors.deepPurple, width: 3)
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.file(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(Icons.error, color: Colors.red),
                            ),
                            cacheHeight: 200,
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.deepPurple,
                              radius: 12,
                              child: const Icon(Icons.check, color: Colors.white, size: 16),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          if ((deleteMode || shareMode) && selectedImages.isNotEmpty)
            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (deleteMode)
                    FloatingActionButton(
                      heroTag: "delete",
                      onPressed: _isLoading ? null : _confirmAndDeleteSelected,
                      backgroundColor: Colors.red,
                      child: const Icon(Icons.delete_forever, color: Colors.white),
                    ),
                  if (deleteMode && shareMode) const SizedBox(height: 8),
                  if (shareMode)
                    FloatingActionButton(
                      heroTag: "share",
                      onPressed: _isLoading ? null : _shareSelectedImages,
                      backgroundColor: Colors.deepPurple,
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                ],
              ),
            ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.deepPurple),
              ),
            ),
        ],
      ),
    );
  }
}

class ZoomableImage extends StatefulWidget {
  final File file;
  final ValueChanged<bool> onZoomChanged; // Callback to notify zoom state

  const ZoomableImage({
    super.key,
    required this.file,
    required this.onZoomChanged,
  });

  @override
  State<ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<ZoomableImage> {
  final TransformationController _controller = TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    // Listen to transformation changes to detect zoom level
    _controller.addListener(() {
      final scale = _controller.value.getMaxScaleOnAxis();
      widget.onZoomChanged(scale > 1.0); // Notify if zoomed in
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (details) {
        _doubleTapDetails = details;
      },
      onDoubleTap: () {
        final position = _doubleTapDetails?.localPosition;
        if (_controller.value != Matrix4.identity()) {
          _controller.value = Matrix4.identity();
        } else if (position != null) {
          _controller.value = Matrix4.identity()
            ..translate(-position.dx * 2, -position.dy * 2)
            ..scale(3.0);
        }
      },
      child: InteractiveViewer(
        transformationController: _controller,
        minScale: 1.0,
        maxScale: 5.0,
        panEnabled: true,
        scaleEnabled: true,
        child: Image.file(
          widget.file,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          cacheWidth: 1000,
          errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.error, color: Colors.red, size: 50),
        ),
      ),
    );
  }
}

class ImageViewerPage extends StatefulWidget {
  final List<File> images;
  final int initialIndex;

  const ImageViewerPage({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isZoomed = false; // Track zoom state

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text(
          "${_currentIndex + 1} / ${widget.images.length}",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.black,
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // Disable PageView scrolling when zoomed
          if (_isZoomed && notification is ScrollStartNotification) {
            return true; // Consume the scroll event
          }
          return false;
        },
        child: PageView.builder(
          controller: _pageController,
          physics: _isZoomed
              ? const NeverScrollableScrollPhysics() // Disable swipe when zoomed
              : const PageScrollPhysics(), // Enable swipe when not zoomed
          itemCount: widget.images.length,
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
            // Reset zoom state when changing pages
            setState(() => _isZoomed = false);
          },
          itemBuilder: (context, index) {
            return Center(
              child: ZoomableImage(
                file: widget.images[index],
                onZoomChanged: (isZoomed) {
                  setState(() => _isZoomed = isZoomed);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}