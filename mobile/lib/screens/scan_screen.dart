import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:go_router/go_router.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import 'camera_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final ApiClient _apiClient = ApiClient();

  File? _frontImage;
  File? _backImage;
  File? _leftImage;
  File? _rightImage;
  bool _isProcessing = false;
  bool _scanFlowActive = false;
  int _currentStep = 0;

  final List<String> _steps = ['Front', 'Back', 'Left', 'Right'];

  @override
  void initState() {
    super.initState();
  }

  /// Captures a single image via camera, crops it, and returns the File (or null if cancelled).
  Future<File?> _captureAndCrop(String side) async {
    // 1. Capture using custom camera screen
    final File? capturedFile = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CameraScreen(sideName: side)),
    );

    if (capturedFile == null) return null;

    // 2. Crop
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: capturedFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop & Align $side Label',
          toolbarColor: const Color(0xFF0F172A),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Crop & Align'),
      ],
    );

    if (croppedFile != null) {
      return File(croppedFile.path);
    }
    return null;
  }

  /// Runs the full sequential scan flow: Front (mandatory) → Back (mandatory) → Left (optional) → Right (optional)
  Future<void> _runScanFlow() async {
    setState(() {
      _scanFlowActive = true;
      _currentStep = 0;
    });

    // Step 1: Front (mandatory)
    final front = await _captureAndCrop('Front');
    if (front == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Front capture is required. Scan cancelled.')),
        );
        setState(() => _scanFlowActive = false);
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _frontImage = front;
      _currentStep = 1;
    });

    // Step 2: Back (mandatory)
    final back = await _captureAndCrop('Back');
    if (back == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Back capture is required. Scan cancelled.')),
        );
        setState(() => _scanFlowActive = false);
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _backImage = back;
      _currentStep = 2;
    });

    // Step 3: Left (optional)
    if (mounted) {
      final shouldScanLeft = await _showOptionalDialog('Left');
      if (shouldScanLeft == true) {
        final left = await _captureAndCrop('Left');
        if (left != null && mounted) {
          setState(() => _leftImage = left);
        }
      }
    }
    if (!mounted) return;
    setState(() => _currentStep = 3);

    // Step 4: Right (optional)
    if (mounted) {
      final shouldScanRight = await _showOptionalDialog('Right');
      if (shouldScanRight == true) {
        final right = await _captureAndCrop('Right');
        if (right != null && mounted) {
          setState(() => _rightImage = right);
        }
      }
    }

    // All steps done — auto-submit
    if (mounted) {
      setState(() => _scanFlowActive = false);
      await _startComplianceScan();
    }
  }

  /// Shows a dialog asking if the user wants to scan an optional side.
  Future<bool?> _showOptionalDialog(String side) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.camera_alt_outlined, color: AppTheme.accentCyan),
            const SizedBox(width: 8),
            Text('Scan $side Side?', style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Would you like to capture the $side side of the product? This is optional and can improve accuracy.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('SKIP', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.camera_alt, size: 16),
            label: const Text('SCAN'),
          ),
        ],
      ),
    );
  }

  Future<void> _startComplianceScan() async {
    if (_frontImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture front package label first.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final auth = ref.read(authProvider);

      final uploadRes = await _apiClient.uploadScanImage(
        _frontImage!.path,
        backFilePath: _backImage?.path,
        topFilePath: _leftImage?.path,
        bottomFilePath: _rightImage?.path,
        userId: auth.userId,
      );
      final String scanId = uploadRes['scan_id'];

      final result = await _apiClient.processScan(scanId);

      if (mounted) {
        setState(() => _isProcessing = false);
        context.push('/result', extra: result);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scan failed: ${e.toString()}'),
            duration: const Duration(seconds: 6),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  File? _getImageForStep(int step) {
    if (step == 0) return _frontImage;
    if (step == 1) return _backImage;
    if (step == 2) return _leftImage;
    if (step == 3) return _rightImage;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Scanner'),
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.accentCyan),
                  SizedBox(height: 24),
                  Text('Extracting declarations & evaluating...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Stepper indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (index) {
                      final isActive = index == _currentStep;
                      final isDone = _getImageForStep(index) != null;
                      return Expanded(
                        child: Column(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDone
                                    ? AppTheme.successGreen
                                    : (isActive ? AppTheme.accentCyan : Colors.transparent),
                                border: Border.all(
                                  color: isActive || isDone ? Colors.transparent : Colors.grey,
                                  width: 2,
                                ),
                              ),
                              child: isDone
                                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                                  : Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: isActive ? Colors.white : Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _steps[index],
                              style: TextStyle(
                                fontSize: 11,
                                color: isActive || isDone ? Colors.white : Colors.grey,
                                fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            if (index > 1)
                              Text(
                                '(optional)',
                                style: TextStyle(fontSize: 9, color: Colors.grey.withValues(alpha: 0.6)),
                              ),
                          ],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Preview area: shows captured images or start prompt
                  Expanded(
                    child: _frontImage == null && !_scanFlowActive
                        ? _buildStartPrompt()
                        : _buildImagePreview(),
                  ),

                  const SizedBox(height: 20),

                  // Main action button
                  if (!_scanFlowActive) ...[
                    ElevatedButton.icon(
                      onPressed: _frontImage == null ? _runScanFlow : _startComplianceScan,
                      icon: Icon(_frontImage == null ? Icons.camera_alt : Icons.analytics),
                      label: Text(_frontImage == null ? 'START SCAN' : 'SUBMIT FOR ANALYSIS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _frontImage == null ? AppTheme.accentCyan : AppTheme.successGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    if (_frontImage != null) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _frontImage = null;
                            _backImage = null;
                            _leftImage = null;
                            _rightImage = null;
                            _currentStep = 0;
                          });
                          _runScanFlow();
                        },
                        icon: const Icon(Icons.replay, color: AppTheme.warningOrange),
                        label: const Text('RESCAN ALL', style: TextStyle(color: AppTheme.warningOrange)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.warningOrange),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStartPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accentCyan.withValues(alpha: 0.1),
              border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.4), width: 2),
            ),
            child: const Icon(Icons.center_focus_strong, size: 60, color: AppTheme.accentCyan),
          ),
          const SizedBox(height: 24),
          const Text(
            'Ready to Scan',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Tap "START SCAN" to begin the guided capture flow. You will photograph the front and back (required), then optionally the left and right sides.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    final captured = <MapEntry<String, File>>[];
    if (_frontImage != null) captured.add(MapEntry('Front', _frontImage!));
    if (_backImage != null) captured.add(MapEntry('Back', _backImage!));
    if (_leftImage != null) captured.add(MapEntry('Left', _leftImage!));
    if (_rightImage != null) captured.add(MapEntry('Right', _rightImage!));

    if (captured.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.accentCyan),
            SizedBox(height: 16),
            Text('Opening camera...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: captured.length,
      itemBuilder: (context, index) {
        final entry = captured[index];
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.5), width: 2),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(entry.value, fit: BoxFit.cover),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(entry.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
