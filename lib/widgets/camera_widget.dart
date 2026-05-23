import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';

class CameraWidget extends StatefulWidget {
  const CameraWidget({super.key});

  @override
  State<CameraWidget> createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget>
    with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  bool _isInitialized = false;
  bool _isTakingPicture = false;
  FlashMode _currentFlashMode = FlashMode.off;
  String? _bannerMessage;

  // Permission state
  bool _cameraPermissionDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestPermissionsAndInit();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      setState(() => _isInitialized = false);
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _requestPermissionsAndInit();
    }
  }

  Future<void> _requestPermissionsAndInit() async {
    // Camera permission
    final cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      if (mounted) setState(() => _cameraPermissionDenied = true);
      return;
    }

    // Gallery/storage permission for saving
    // On Android 13+ this is READ_MEDIA_IMAGES; gal handles the right one
    await Permission.photos.request();   // iOS
    await Permission.storage.request();  // Android ≤ 12

    if (mounted) setState(() => _cameraPermissionDenied = false);
    await _initializeSystem();
  }

  Future<void> _initializeSystem() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) await _initCamera(_selectedCameraIndex);
    } catch (e) {
      debugPrint('Error finding cameras: $e');
    }
  }

  Future<void> _initCamera(int index) async {
    final old = _controller;
    if (old != null) {
      setState(() => _isInitialized = false);
      await old.dispose();
      _controller = null;
    }

    final controller = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isIOS
          ? ImageFormatGroup.bgra8888
          : ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
      await controller.setFlashMode(_currentFlashMode);
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  void _toggleCamera() {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    _initCamera(_selectedCameraIndex);
  }

  Future<void> _cycleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final next = switch (_currentFlashMode) {
      FlashMode.off => FlashMode.always,
      FlashMode.always => FlashMode.torch,
      _ => FlashMode.off,
    };
    try {
      await controller.setFlashMode(next);
      if (mounted) setState(() => _currentFlashMode = next);
    } catch (e) {
      debugPrint('Flash error: $e');
    }
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isTakingPicture) return;

    setState(() => _isTakingPicture = true);

    try {
      final XFile tempFile = await controller.takePicture();

      // Save directly to the device gallery
      await Gal.putImage(tempFile.path, album: 'SiteSee');

      // Clean up temp file
      await File(tempFile.path).delete();

      _showBanner('Photo saved to gallery!');
    } catch (e) {
      debugPrint('Capture error: $e');
      _showBanner('Failed to save photo');
    } finally {
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  void _showBanner(String message) {
    if (!mounted) return;
    setState(() => _bannerMessage = message);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _bannerMessage = null);
    });
  }

  IconData _flashIcon() => switch (_currentFlashMode) {
    FlashMode.always => Icons.flash_on,
    FlashMode.torch => Icons.flashlight_on,
    _ => Icons.flash_off,
  };

  Widget _buildFullBleedPreview(double w, double h) {
    // Permission denied screen
    if (_cameraPermissionDenied) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography, color: Colors.white54, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Camera permission required',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => openAppSettings(),
                child: const Text('Open Settings',
                    style: TextStyle(color: Colors.yellow)),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _controller;
    if (!_isInitialized ||
        controller == null ||
        !controller.value.isInitialized) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator(color: Colors.yellow)),
      );
    }

    final camAspect = controller.value.aspectRatio;
    return ClipRect(
      child: OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        alignment: Alignment.center,
        child: SizedBox(
          width: h * camAspect > w ? h * camAspect : w,
          height: w / camAspect > h ? w / camAspect : h,
          child: CameraPreview(controller),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: preview ────────────────────────────────────────────
          _buildFullBleedPreview(size.width, size.height),

          // ── Layer 2: UI overlay ─────────────────────────────────────────
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(_flashIcon(),
                            color: Colors.white, size: 28),
                        onPressed: _cycleFlash,
                      ),
                      IconButton(
                        icon: const Icon(Icons.flip_camera_ios,
                            color: Colors.white, size: 28),
                        onPressed: _toggleCamera,
                      ),
                    ],
                  ),
                ),

                // Bottom HUD
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_bannerMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(_bannerMessage!,
                              style:
                              const TextStyle(color: Colors.white)),
                        ),

                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('CAMERA',
                              style: TextStyle(
                                  color: Colors.yellow,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          const Icon(Icons.photo_library,
                              color: Colors.white, size: 28),

                          GestureDetector(
                            onTap: _isTakingPicture ? null : _takePicture,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              height: 84,
                              width: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isTakingPicture
                                    ? Colors.white24
                                    : Colors.transparent,
                                border: Border.all(
                                    color: Colors.white, width: 5),
                              ),
                              child: _isTakingPicture
                                  ? const Center(
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              )
                                  : null,
                            ),
                          ),

                          const Icon(Icons.face,
                              color: Colors.white, size: 28),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}