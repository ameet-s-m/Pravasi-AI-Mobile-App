// lib/screens/reels_screen.dart
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../data/dummy_data.dart';
import '../models/models.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  late PageController _pageController;
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<int, bool> _isLiked = {};
  final Map<int, bool> _isPlaying = {};
  final Map<int, Duration> _playbackPositions = {}; // Track playback positions
  int _currentIndex = 0;
  bool _isScreenVisible = true;
  bool _wasPlayingBeforePause = false;
  Timer? _visibilityCheckTimer;

  @override
  bool get wantKeepAlive => true; // Keep state alive when switching tabs

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController();
    _initializeVideos();
    _startVisibilityCheck();
  }

  void _startVisibilityCheck() {
    // Periodically check visibility to ensure videos pause when tab is not visible
    _visibilityCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        _checkVisibility();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _visibilityCheckTimer?.cancel();
    _pageController.dispose();
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _pauseAllVideos();
    } else if (state == AppLifecycleState.resumed && _isScreenVisible) {
      _resumeCurrentVideo();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check visibility using route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }

  void _checkVisibility() {
    if (!mounted) return;
    
    final route = ModalRoute.of(context);
    if (route != null) {
      // For CupertinoTabScaffold, check if route is current (visible)
      // isCurrent is more reliable than isActive for tab navigation
      final isCurrent = route.isCurrent;
      
      if (isCurrent && !_isScreenVisible) {
        // Tab became visible
        _isScreenVisible = true;
        print('👁️ Reels tab became visible');
        // Resume after a small delay to ensure UI is ready
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _isScreenVisible) {
            _resumeCurrentVideo();
          }
        });
      } else if (!isCurrent && _isScreenVisible) {
        // Tab became hidden - pause immediately
        _isScreenVisible = false;
        _pauseAllVideos();
        print('👁️ Reels tab became hidden - paused all videos');
      }
    }
  }

  void _pauseAllVideos() {
    bool anyVideoWasPlaying = false;
    for (var entry in _videoControllers.entries) {
      final index = entry.key;
      final controller = entry.value;
      if (controller.value.isInitialized) {
        // Save current position regardless of playing state
        if (controller.value.position.inMilliseconds > 0) {
          _playbackPositions[index] = controller.value.position;
        }
        
        if (controller.value.isPlaying) {
          anyVideoWasPlaying = true;
          controller.pause();
          _isPlaying[index] = false;
          print('⏸️ Paused video $index at position: ${controller.value.position}');
        }
      }
    }
    if (anyVideoWasPlaying) {
      _wasPlayingBeforePause = true;
    }
  }

  void _resumeCurrentVideo() {
    if (!_isScreenVisible || !mounted) return;
    
    final controller = _videoControllers[_currentIndex];
    if (controller != null && controller.value.isInitialized && !controller.value.hasError) {
      // Restore position if available
      final savedPosition = _playbackPositions[_currentIndex];
      if (savedPosition != null && savedPosition < controller.value.duration) {
        controller.seekTo(savedPosition);
        print('⏩ Restored video $_currentIndex to position: $savedPosition');
      }
      
      // Auto-play when tab becomes visible (always resume if it was playing or if it's the first video)
      if (_wasPlayingBeforePause || _isPlaying[_currentIndex] == true || _currentIndex == 0) {
        controller.setLooping(true);
        controller.play();
        _isPlaying[_currentIndex] = true;
        _wasPlayingBeforePause = false;
        print('▶️ Auto-playing video $_currentIndex');
      }
    } else if (controller != null && !controller.value.isInitialized) {
      // If not initialized yet, wait for it and then play
      controller.initialize().then((_) {
        if (mounted && _isScreenVisible && controller.value.isInitialized && !controller.value.hasError) {
          final savedPosition = _playbackPositions[_currentIndex];
          if (savedPosition != null && savedPosition < controller.value.duration) {
            controller.seekTo(savedPosition);
          }
          controller.setLooping(true);
          controller.play();
          _isPlaying[_currentIndex] = true;
          print('▶️ Auto-playing video $_currentIndex after initialization');
        }
      });
    }
  }

  Future<void> _initializeVideos() async {
    // First, discover all available video assets
    await _discoverVideoAssets();
    
    for (int i = 0; i < DummyData.videos.length; i++) {
      _isLiked[i] = false;
      _isPlaying[i] = false;
      _loadVideo(i);
    }
  }

  final Map<String, String> _assetPathMap = {}; // Maps expected filename to actual asset path
  final Map<String, String> _localVideoPaths = {}; // Maps filename to local file path
  Directory? _videosDirectory;

  Future<void> _discoverVideoAssets() async {
    try {
      // Get or create videos directory in local storage
      final appDocDir = await getApplicationDocumentsDirectory();
      _videosDirectory = Directory(path.join(appDocDir.path, 'reels_videos'));
      if (!await _videosDirectory!.exists()) {
        await _videosDirectory!.create(recursive: true);
        print('✅ Created videos directory: ${_videosDirectory!.path}');
      }

      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = 
          jsonDecode(manifestContent) as Map<String, dynamic>;
      
      // Get all assets in lib/reels/
      final reelAssets = manifestMap.keys.where((key) => 
        key.contains('lib/reels/') && key.endsWith('.mp4')
      ).toList();
      
      print('📹 Found ${reelAssets.length} video assets in manifest');
      
      // Create a map for easier lookup
      for (var assetPath in reelAssets) {
        final filename = assetPath.split('/').last;
        _assetPathMap[filename] = assetPath;
        print('  - $filename -> $assetPath');
      }

      // Copy videos to local storage
      await _copyVideosToLocalStorage();
    } catch (e) {
      print('⚠️ Error discovering assets: $e');
    }
  }

  Future<void> _copyVideosToLocalStorage() async {
    if (_videosDirectory == null) return;

    print('📦 Copying videos to local storage...');
    
    for (var entry in _assetPathMap.entries) {
      final filename = entry.key;
      final assetPath = entry.value;
      final localFile = File(path.join(_videosDirectory!.path, filename));
      
      // Check if file already exists
      if (await localFile.exists()) {
        print('✅ Video already in local storage: $filename');
        _localVideoPaths[filename] = localFile.path;
        continue;
      }

      try {
        // Load asset as bytes
        final byteData = await rootBundle.load(assetPath);
        final bytes = byteData.buffer.asUint8List();
        
        // Write to local file
        await localFile.writeAsBytes(bytes);
        _localVideoPaths[filename] = localFile.path;
        print('✅ Copied to local storage: $filename (${(bytes.length / 1024 / 1024).toStringAsFixed(2)} MB)');
      } catch (e) {
        print('❌ Error copying $filename: $e');
        // Try alternative approach - use asset path directly
        _localVideoPaths[filename] = assetPath;
      }
    }
    
    print('📦 Finished copying videos. Total: ${_localVideoPaths.length}');
  }

  Future<void> _loadVideo(int index) async {
    try {
      // Get video path from dummy data
      String videoPath = DummyData.videos[index].videoUrl;
      
      // Extract filename from path
      String filename = videoPath.split('/').last;
      
      // Try to find local file path first
      String? localFilePath;
      
      // First, try exact match in local storage
      if (_localVideoPaths.containsKey(filename)) {
        localFilePath = _localVideoPaths[filename];
        print('✅ Found in local storage: $filename -> $localFilePath');
      } else {
        // Try fuzzy matching
        final normalizedFilename = filename
            .replaceAll(RegExp(r'[^\w\s-]'), '')
            .toLowerCase()
            .trim();
        
        for (var entry in _localVideoPaths.entries) {
          final normalizedKey = entry.key
              .replaceAll(RegExp(r'[^\w\s-]'), '')
              .toLowerCase()
              .trim();
          
          if (normalizedKey == normalizedFilename || 
              normalizedKey.contains(normalizedFilename) ||
              normalizedFilename.contains(normalizedKey)) {
            localFilePath = entry.value;
            print('✅ Found fuzzy match in local storage: $filename -> ${entry.key} -> $localFilePath');
            break;
          }
        }
      }
      
      // If not in local storage, try to find asset and copy it
      if (localFilePath == null) {
        String? assetPath;
        
        if (_assetPathMap.containsKey(filename)) {
          assetPath = _assetPathMap[filename];
        } else {
          // Try fuzzy matching in assets
          final normalizedFilename = filename
              .replaceAll(RegExp(r'[^\w\s-]'), '')
              .toLowerCase()
              .trim();
          
          for (var entry in _assetPathMap.entries) {
            final normalizedKey = entry.key
                .replaceAll(RegExp(r'[^\w\s-]'), '')
                .toLowerCase()
                .trim();
            
            if (normalizedKey == normalizedFilename || 
                normalizedKey.contains(normalizedFilename) ||
                normalizedFilename.contains(normalizedKey)) {
              assetPath = entry.value;
              break;
            }
          }
        }
        
        if (assetPath != null && _videosDirectory != null) {
          // Copy asset to local storage
          try {
            final localFile = File(path.join(_videosDirectory!.path, filename));
            final byteData = await rootBundle.load(assetPath);
            final bytes = byteData.buffer.asUint8List();
            await localFile.writeAsBytes(bytes);
            localFilePath = localFile.path;
            _localVideoPaths[filename] = localFilePath;
            print('✅ Copied and ready: $filename -> $localFilePath');
          } catch (e) {
            print('❌ Error copying to local storage: $e');
            // Fallback to asset path
            localFilePath = assetPath;
          }
        } else {
          // Last resort: try original path
          if (!videoPath.startsWith('lib/reels/')) {
            videoPath = 'lib/reels/$filename';
          }
          localFilePath = videoPath;
          print('⚠️ Using original path: $localFilePath');
        }
      }
      
      // Ensure we have a valid path
      if (localFilePath.isEmpty) {
        print('❌ Could not find video: $filename');
        print('Available in local storage: ${_localVideoPaths.keys.join(", ")}');
        if (mounted) {
          setState(() {});
        }
        return;
      }
      
      // Check if it's a local file path or asset path
      final file = File(localFilePath);
      final isLocalFile = await file.exists();
      
      print('📹 Loading video $index: $localFilePath (${isLocalFile ? "Local File" : "Asset"})');
      
      // Create video controller - use file() for local files, asset() for assets
      final VideoPlayerController videoController;
      if (isLocalFile) {
        videoController = VideoPlayerController.file(file);
      } else {
        videoController = VideoPlayerController.asset(localFilePath);
      }
      
      // Store controller immediately so UI can show loading state
      _videoControllers[index] = videoController;
      
      // Initialize video with better error handling
      try {
        await videoController.initialize().timeout(
          const Duration(seconds: 30), // Increased timeout for large videos
          onTimeout: () {
            print('⚠️ Video $index initialization timeout: $localFilePath');
            throw TimeoutException('Video initialization timeout');
          },
        );
        
        if (mounted && videoController.value.isInitialized && !videoController.value.hasError) {
          setState(() {
            // Auto-play first video only if screen is visible
            if (index == 0 && _isScreenVisible) {
              // Restore position if available
              final savedPosition = _playbackPositions[0];
              if (savedPosition != null && savedPosition < videoController.value.duration) {
                videoController.seekTo(savedPosition);
              }
              _isPlaying[0] = true;
              videoController.setLooping(true);
              videoController.play();
            }
          });
          print('✅ Video $index initialized successfully: $localFilePath');
        } else if (mounted && videoController.value.hasError) {
          print('❌ Video $index has error: ${videoController.value.errorDescription}');
          if (mounted) {
            setState(() {});
          }
        }
      } catch (error) {
        print('❌ Error initializing video $index: $error');
        print('Video path: $localFilePath');
        print('Error type: ${error.runtimeType}');
        // Keep controller in map so error UI can be shown
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      print('❌ Error creating video controller $index: $e');
      print('Video URL: ${DummyData.videos[index].videoUrl}');
      print('Error type: ${e.runtimeType}');
      // Don't add controller to map if creation fails
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _onPageChanged(int index) {
    // Save position of previous video before switching
    if (_videoControllers.containsKey(_currentIndex)) {
      final previousController = _videoControllers[_currentIndex];
      if (previousController != null && previousController.value.isInitialized) {
        _playbackPositions[_currentIndex] = previousController.value.position;
        previousController.pause();
        _isPlaying[_currentIndex] = false;
        print('⏸️ Paused video $_currentIndex, saved position: ${previousController.value.position}');
      }
    }
    
    _currentIndex = index;
    
    // Auto-play current video if screen is visible (no manual play button needed)
    if (_isScreenVisible && _videoControllers.containsKey(index)) {
      final currentController = _videoControllers[index];
      if (currentController != null && currentController.value.isInitialized && !currentController.value.hasError) {
        // Restore position if available
        final savedPosition = _playbackPositions[index];
        if (savedPosition != null && savedPosition < currentController.value.duration) {
          currentController.seekTo(savedPosition);
          print('⏩ Restored video $index to position: $savedPosition');
        }
        
        // Auto-play - no manual play button needed
        currentController.setLooping(true);
        currentController.play();
        _isPlaying[index] = true;
        print('▶️ Auto-playing video $index');
      } else if (currentController != null && !currentController.value.isInitialized) {
        // Try to initialize if not done yet
        currentController.initialize().then((_) {
          if (mounted && _isScreenVisible && currentController.value.isInitialized && !currentController.value.hasError) {
            // Restore position if available
            final savedPosition = _playbackPositions[index];
            if (savedPosition != null && savedPosition < currentController.value.duration) {
              currentController.seekTo(savedPosition);
            }
            
            setState(() {
              currentController.setLooping(true);
              currentController.play();
              _isPlaying[index] = true;
            });
            print('▶️ Auto-playing video $index after initialization');
          }
        }).catchError((error) {
          print('Error initializing video on page change: $error');
        });
      } else if (!_videoControllers.containsKey(index)) {
        // Video not loaded yet, try loading it
        _loadVideo(index);
      }
    }
    
    setState(() {});
  }

  void _togglePlayPause(int index) {
    if (!_videoControllers.containsKey(index)) return;
    
    final controller = _videoControllers[index]!;
    if (controller.value.isPlaying) {
      controller.pause();
      _isPlaying[index] = false;
    } else {
      controller.play();
      _isPlaying[index] = true;
    }
    setState(() {});
  }

  void _toggleLike(int index) {
    setState(() {
      _isLiked[index] = !(_isLiked[index] ?? false);
    });
    HapticFeedback.mediumImpact();
  }

  Future<void> _retryVideoLoad(int index) async {
    // Dispose old controller if exists
    _videoControllers[index]?.dispose();
    _videoControllers.remove(index);
    
    // Reload video
    await _loadVideo(index);
    
    // Try to play if it's the current video
    if (index == _currentIndex && mounted) {
      setState(() {
        final controller = _videoControllers[index];
        if (controller != null && controller.value.isInitialized && !controller.value.hasError) {
          _isPlaying[index] = true;
          controller.setLooping(true);
          controller.play();
        }
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return CupertinoPageScaffold(
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        onPageChanged: _onPageChanged,
        itemCount: DummyData.videos.length,
        itemBuilder: (context, index) {
          return _buildVideoPost(context, DummyData.videos[index], index);
        },
      ),
    );
  }

  Widget _buildVideoPost(BuildContext context, VideoPost post, int index) {
    final controller = _videoControllers[index];
    final isPlaying = _isPlaying[index] ?? false;
    final isLiked = _isLiked[index] ?? false;

    return GestureDetector(
      onTap: () => _togglePlayPause(index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video Player
          if (controller != null && controller.value.isInitialized && !controller.value.hasError)
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio > 0 
                    ? controller.value.aspectRatio 
                    : 9 / 16, // Default aspect ratio for vertical videos
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                ),
              ),
            )
          else if (controller != null && (controller.value.hasError || !controller.value.isInitialized))
            Container(
              color: CupertinoColors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      color: CupertinoColors.systemRed,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Video failed to load',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CupertinoButton.filled(
                      onPressed: () {
                        // Retry loading by recreating controller
                        _retryVideoLoad(index);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              color: CupertinoColors.black,
              child: const Center(
                child: CupertinoActivityIndicator(
                  color: CupertinoColors.white,
                  radius: 20,
                ),
              ),
            ),
          
          // Play/Pause Overlay
          if (!isPlaying)
            Container(
              color: CupertinoColors.black.withOpacity(0.3),
              child: const Center(
                child: Icon(
                  CupertinoIcons.play_arrow_solid,
                  color: CupertinoColors.white,
                  size: 80,
                ),
              ),
            ),
          
          // Video Overlay UI
          _buildVideoOverlay(context, post, index, isLiked),
        ],
      ),
    );
  }

  Widget _buildVideoOverlay(BuildContext context, VideoPost post, int index, bool isLiked) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: CupertinoColors.white,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.network(
                                post.userAvatarUrl,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: CupertinoColors.systemBlue,
                                    child: Center(
                                      child: Text(
                                        post.username.substring(1, 3).toUpperCase(),
                                        style: const TextStyle(
                                          color: CupertinoColors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.username,
                                  style: const TextStyle(
                                    color: CupertinoColors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    shadows: [
                                      Shadow(blurRadius: 8, color: CupertinoColors.black),
                                    ],
                                  ),
                                ),
                                if (post.location.isNotEmpty)
                                  Text(
                                    post.location,
                                    style: TextStyle(
                                      color: CupertinoColors.white.withOpacity(0.9),
                                      fontSize: 13,
                                      shadows: const [
                                        Shadow(blurRadius: 6, color: CupertinoColors.black),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        post.caption,
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 15,
                          shadows: [
                            Shadow(blurRadius: 8, color: CupertinoColors.black),
                          ],
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: post.tags.map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: CupertinoColors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: CupertinoColors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '#$tag',
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              shadows: [
                                Shadow(blurRadius: 6, color: CupertinoColors.black),
                              ],
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      icon: isLiked ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                      label: post.likes,
                      color: isLiked ? CupertinoColors.systemRed : CupertinoColors.white,
                      onTap: () => _toggleLike(index),
                    ),
                    const SizedBox(height: 24),
                    _buildActionButton(
                      icon: CupertinoIcons.chat_bubble_2_fill,
                      label: post.comments,
                      onTap: () {
                        showCupertinoDialog(
                          context: context,
                          builder: (context) => CupertinoAlertDialog(
                            title: const Text('Comments'),
                            content: Text('${post.comments} comments on this reel'),
                            actions: [
                              CupertinoDialogAction(
                                child: const Text('OK'),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildActionButton(
                      icon: CupertinoIcons.paperplane_fill,
                      label: post.shares,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        showCupertinoDialog(
                          context: context,
                          builder: (context) => CupertinoAlertDialog(
                            title: const Text('Share Reel'),
                            content: const Text('Share this reel with your friends!'),
                            actions: [
                              CupertinoDialogAction(
                                child: const Text('OK'),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildActionButton(
                      icon: CupertinoIcons.bookmark,
                      label: 'Save',
                      onTap: () {
                        HapticFeedback.mediumImpact();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CupertinoColors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color ?? CupertinoColors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(blurRadius: 6, color: CupertinoColors.black),
              ],
            ),
          ),
        ],
      ),
    );
  }
}