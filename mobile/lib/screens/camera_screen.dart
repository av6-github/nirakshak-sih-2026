import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme.dart';

class CameraScreen extends StatefulWidget {
  final String sideName;

  const CameraScreen({super.key, required this.sideName});

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

    // Try to find a back camera
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
        body: Center(child: CircularProgressIndicator(color: AppTheme.accentCyan)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview (Fullscreen)
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: CameraPreview(_controller!),
          ),

          // Scanning Guide Box Overlay
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height * 0.55,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.6), width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          // Overlay Guideline Text
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.accentCyan, width: 2),
              ),
              child: Column(
                children: [
                  const Text(
                    'ALIGN PRODUCT',
                    style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 2),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.center_focus_strong, color: AppTheme.accentCyan, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        widget.sideName.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.accentCyan,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Back Button
          Positioned(
            top: 50,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context, null),
            ),
          ),

          // Capture and Gallery Buttons
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gallery Button
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 36),
                      onPressed: _pickFromGallery,
                    ),
                    const Text('Gallery', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),

                // Capture Button
                GestureDetector(
                  onTap: _takePicture,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.accentCyan, width: 4),
                    ),
                    child: Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.accentCyan,
                        ),
                      ),
                    ),
                  ),
                ),

                // Empty placeholder to balance the Row
                const SizedBox(width: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
