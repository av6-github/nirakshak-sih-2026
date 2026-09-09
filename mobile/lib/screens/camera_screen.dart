import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme.dart';

class CameraScreen extends StatefulWidget {
  final String sideName;
  final String? instruction;

  const CameraScreen({
    super.key,
    required this.sideName,
    this.instruction,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      if (mounted) Navigator.pop(context, null);
      return;
    }

    CameraDescription? backCamera;
    for (var camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.back) {
        backCamera = camera;
        break;
      }
    }
    
    backCamera ??= cameras.first;

    _controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      if (mounted) Navigator.pop(context, null);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _controller!.value.isTakingPicture) {
      return;
    }

    try {
      final XFile image = await _controller!.takePicture();
      if (mounted) {
        Navigator.pop(context, File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking picture: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image != null && mounted) {
        Navigator.pop(context, File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppTheme.emerald500)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview (Fullscreen)
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),

          // Scanning Guide Box Overlay with Emerald Corner Brackets (matching Home Scanner aesthetic)
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height * 0.52,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.emerald400.withValues(alpha: 0.35), width: 1.5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  // Top-Left Corner Guide
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppTheme.emerald400, width: 3.5),
                          left: BorderSide(color: AppTheme.emerald400, width: 3.5),
                        ),
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(24)),
                      ),
                    ),
                  ),
                  // Top-Right Corner Guide
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppTheme.emerald400, width: 3.5),
                          right: BorderSide(color: AppTheme.emerald400, width: 3.5),
                        ),
                        borderRadius: BorderRadius.only(topRight: Radius.circular(24)),
                      ),
                    ),
                  ),
                  // Bottom-Left Corner Guide
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppTheme.emerald400, width: 3.5),
                          left: BorderSide(color: AppTheme.emerald400, width: 3.5),
                        ),
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24)),
                      ),
                    ),
                  ),
                  // Bottom-Right Corner Guide
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppTheme.emerald400, width: 3.5),
                          right: BorderSide(color: AppTheme.emerald400, width: 3.5),
                        ),
                        borderRadius: BorderRadius.only(bottomRight: Radius.circular(24)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Safe Area Top Overlay Bar (leaves full space below status/notification bar)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button with protective rounded container
                      GestureDetector(
                        onTap: () => Navigator.pop(context, null),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        ),
                      ),

                      // Central Guidance Pill
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.emerald400, width: 1.5),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.center_focus_strong_rounded, color: AppTheme.emerald400, size: 18),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'ALIGN ${widget.sideName.toUpperCase()}',
                                      style: const TextStyle(
                                        color: AppTheme.emerald400,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.instruction != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  widget.instruction!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Placeholder for symmetry
                      const SizedBox(width: 42),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Safe Area Bottom Capture and Gallery Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0, left: 16.0, right: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery Button
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 32),
                          onPressed: _pickFromGallery,
                        ),
                        const Text('Gallery', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),

                    // Capture Button
                    GestureDetector(
                      onTap: _takePicture,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.emerald400, width: 4),
                        ),
                        child: Center(
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.emerald400,
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: AppTheme.slate900, size: 28),
                          ),
                        ),
                      ),
                    ),

                    // Balance placeholder
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
