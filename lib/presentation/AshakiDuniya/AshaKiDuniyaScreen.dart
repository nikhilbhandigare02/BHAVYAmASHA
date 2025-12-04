import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';
import 'package:video_player/video_player.dart';

class AshaKiDuniyaScreen extends StatelessWidget {
  const AshaKiDuniyaScreen({super.key});

  List<Map<String, String>> _getVideos(BuildContext context) {
    return [
      {
        'title': AppLocalizations.of(context)!.completeTutorial,
        'url': 'https://appupdate.medixcel.in/20220908120000/login.mp4',
      },
      {
        'title': AppLocalizations.of(context)!.ashwinPortalFilm,
        'url':
            'https://appupdate.medixcel.in/20220908120000/Ashwin_Portal_Film_Final.mp4',
      },
      {
        'title': AppLocalizations.of(context)!.pneumoniaAwareness,
        'url':
            'https://appupdate.medixcel.in/20220908120000/Curtain_Raiser_High_Res.mp4',
      },
      {
        'title': AppLocalizations.of(context)!.healthMinisterMessage,
        'url':
            'https://appupdate.medixcel.in/20220908120000/Message_from_the_Honorable_Health_Minister_Bihar.mp4',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final videos = _getVideos(context);

    return Scaffold(
      appBar: AppHeader(
        screenTitle: AppLocalizations.of(context)!.videoTutorialList,
        showBack: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: videos.length,
        itemBuilder: (context, index) {
          return VideoCard(
            title: videos[index]['title']!,
            url: videos[index]['url']!,
          );
        },
      ),
    );
  }
}

class VideoCard extends StatefulWidget {
  final String title;
  final String url;

  const VideoCard({super.key, required this.title, required this.url});

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      // Set preferred orientation to landscape for better video viewing
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      // Initialize video controller
      _videoPlayerController = VideoPlayerController.network(
        widget.url,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      // Add listener to handle video initialization
      _videoPlayerController.addListener(() {
        if (_videoPlayerController.value.hasError) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      });

      // Wait for video to be initialized
      await _videoPlayerController.initialize();

      // Configure chewie controller with custom theme
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: false,
        looping: false,
        allowMuting: true,
        allowFullScreen: true,
        showControls: true,
        autoInitialize: true,
        customControls: const CupertinoControls(
          backgroundColor: Color.fromRGBO(0, 0, 0, 0.7),
          iconColor: Colors.white,
        ),
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFF1E88E5),
          handleColor: const Color(0xFF1E88E5),
          bufferedColor: Colors.white54,
          backgroundColor: Colors.grey.shade700,
        ),
        placeholder: Container(
          color: Colors.white,
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E88E5)),
            ),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 50),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.errorLoadingVideo,
                  style: GoogleFonts.roboto(fontSize: 16, color: Colors.red),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _hasError = false;
                    });
                    _initializeVideo();
                  },
                  child: Text(AppLocalizations.of(context)!.retry),
                ),
              ],
            ),
          );
        },
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController.pause();
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: GoogleFonts.roboto(
                fontSize: 15.sp,
                color: const Color(0xFF1E88E5),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Container(
                color: Colors.white,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _buildVideoPlayer(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return Container(
        color: Colors.white,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E88E5)),
          ),
        ),
      );
    }

    if (_hasError) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam_off_rounded,
                size: 50,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              Text(
                l10n?.failedToLoadVideo ?? 'Failed to load video',
                style: GoogleFonts.roboto(fontSize: 14.sp, color: Colors.red),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 18),
                label:  Text(l10n?.tryAgain ?? 'Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _hasError = false;
                  });
                  _initializeVideo();
                },
              ),
            ],
          ),
        ),
      );
    }

    return Chewie(controller: _chewieController!);
  }
}
