import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../model/channel.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class Player extends StatefulWidget {
  final Channel channel;

  const Player({super.key, required this.channel});

  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  late VideoPlayerController videoPlayerController;
  late ChewieController chewieController;
  bool _isLoading = true;
  bool _channelNotFound = false;
  bool _disposed = false;
  bool _chewieCreated = false;
  late final VoidCallback _playbackListener;

  @override
  void initState() {
    super.initState();
    videoPlayerController =
        VideoPlayerController.networkUrl(Uri.parse(widget.channel.streamUrl));
    _playbackListener = () {
      if (videoPlayerController.value.isPlaying) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }
    };
    videoPlayerController.addListener(_playbackListener);
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      await videoPlayerController
          .initialize()
          .timeout(const Duration(seconds: 30));
      if (_disposed) return;
      chewieController = ChewieController(
        videoPlayerController: videoPlayerController,
        autoInitialize: false,
        isLive: true,
        autoPlay: false,
        aspectRatio: 3 / 2,
        showOptions: false,
        customControls: const MaterialDesktopControls(showPlayButton: false),
      );
      _chewieCreated = true;
      setState(() => _isLoading = false);
      await videoPlayerController.play();
    } catch (_) {
      if (_disposed) return;
      setState(() {
        _isLoading = false;
        _channelNotFound = true;
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    videoPlayerController.removeListener(_playbackListener);
    if (_chewieCreated) chewieController.dispose();
    videoPlayerController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.channel.name),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _channelNotFound
                ? const Text('Channel not available now',
                    style: TextStyle(fontSize: 24.0))
                : SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: Chewie(
                      controller: chewieController,
                    ),
                  ),
      ),
    );
  }
}
