// lib/screens/vr_model_viewer_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../models/place_model.dart';

class VRModelViewerScreen extends StatefulWidget {
  final PlaceModel place;

  const VRModelViewerScreen({super.key, required this.place});

  @override
  State<VRModelViewerScreen> createState() => _VRModelViewerScreenState();
}

class _VRModelViewerScreenState extends State<VRModelViewerScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    // Check if model file exists
    _checkModelAvailability();
  }

  Future<void> _checkModelAvailability() async {
    // Set a timeout for loading
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Model is taking too long to load. Please check your internet connection or try again.';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          widget.place.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      child: Stack(
        children: [
          // 3D Model Viewer
          Container(
            color: CupertinoColors.black,
            child: Center(
              child: _errorMessage != null
                  ? _buildErrorWidget()
                  : _buildModelViewer(),
            ),
          ),
          // Info Card (with swipe down to hide)
          if (_showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: GestureDetector(
                onVerticalDragEnd: (details) {
                  // Swipe down to hide
                  if (details.primaryVelocity != null && details.primaryVelocity! > 500) {
                    setState(() {
                      _showControls = false;
                    });
                  }
                },
                child: _buildInfoCard(),
              ),
            ),
          // Show controls button when hidden
          if (!_showControls)
            Positioned(
              bottom: 20,
              right: 20,
              child: CupertinoButton(
                padding: const EdgeInsets.all(12),
                color: CupertinoColors.systemBlue.withOpacity(0.8),
                borderRadius: BorderRadius.circular(30),
                onPressed: () {
                  setState(() {
                    _showControls = true;
                  });
                },
                child: const Icon(
                  CupertinoIcons.chevron_up,
                  color: CupertinoColors.white,
                ),
              ),
            ),
          // Loading Indicator
          if (_isLoading)
            const Center(
              child: CupertinoActivityIndicator(
                radius: 20,
                color: CupertinoColors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModelViewer() {
    if (kIsWeb) {
      // For web, use iframe with model-viewer
      return _buildWebModelViewer();
    } else {
      // For mobile, show placeholder or use native 3D viewer
      return _buildMobileModelViewer();
    }
  }

  Widget _buildWebModelViewer() {
    final modelPath = widget.place.modelPath;
    // For web, use asset path directly
    return ModelViewer(
      src: modelPath,
      alt: widget.place.name,
      ar: true,
      autoRotate: true,
      cameraControls: true,
      backgroundColor: CupertinoColors.black,
      disableZoom: false,
      interactionPrompt: InteractionPrompt.whenFocused,
    );
  }

  Widget _buildMobileModelViewer() {
    final modelPath = widget.place.modelPath;
    // For mobile, ensure we're using asset path correctly
    String assetPath = modelPath;
    if (!assetPath.startsWith('assets/') && !assetPath.startsWith('http')) {
      assetPath = 'assets/$assetPath';
    }
    
    // ModelViewer will handle loading automatically
    // Set loading to false after a delay to allow model to load
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    });
    
    return ModelViewer(
      src: assetPath,
      alt: widget.place.name,
      ar: true,
      autoRotate: true,
      cameraControls: true,
      backgroundColor: CupertinoColors.black,
      disableZoom: false,
      interactionPrompt: InteractionPrompt.whenFocused,
    );
  }

  Widget _buildErrorWidget() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle,
            size: 64,
            color: CupertinoColors.systemRed,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Error loading model',
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: const BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  CupertinoIcons.info,
                  color: CupertinoColors.systemBlue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Controls',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildControlItem(
              CupertinoIcons.hand_point_left,
              'Touch & Drag',
              'Rotate the view',
            ),
            _buildControlItem(
              CupertinoIcons.zoom_in,
              'Pinch to Zoom',
              'Zoom in/out',
            ),
            _buildControlItem(
              CupertinoIcons.move,
              'Two Finger Drag',
              'Pan the view',
            ),
            const SizedBox(height: 12),
            Container(
              height: 0.5,
              color: CupertinoColors.separator,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  CupertinoIcons.location,
                  size: 16,
                  color: CupertinoColors.secondaryLabel,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.place.location,
                  style: const TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: CupertinoColors.systemBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel,
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

