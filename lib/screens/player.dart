import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../model/channel.dart';
import 'package:wakelock/wakelock.dart'; // Add this import

class Player extends StatefulWidget {
  final Channel channel;

  Player({required this.channel});

  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  late VideoPlayerController videoPlayerController;
  late ChewieController chewieController;
  bool _isLoading = true;
  bool _channelNotFound = false;

  @override
  void initState() {
    super.initState();
    videoPlayerController =
        VideoPlayerController.networkUrl(Uri.parse(widget.channel.streamUrl))
          ..initialize().then((_) {
            setState(() {
              _isLoading = false;
            });
          }).catchError((error) {
            setState(() {
              _isLoading = false;
              _channelNotFound = true;
            });
          });

    chewieController = ChewieController(
      videoPlayerController: videoPlayerController,
      autoInitialize: true,
      isLive: true,
      autoPlay: true,
      aspectRatio: 3 / 2,
      showOptions: false,
      customControls: const MaterialDesktopControls(
        showPlayButton: false,
      ),
    );

    // Enable wake lock when video starts playing
    videoPlayerController.addListener(() {
      if (videoPlayerController.value.isPlaying) {
        Wakelock.enable();
      }
    });

    // Disable wake lock when video stops
    videoPlayerController.addListener(() {
      if (!videoPlayerController.value.isPlaying) {
        Wakelock.disable();
      }
    });
  }

  @override
  void dispose() {
    videoPlayerController.dispose();
    chewieController.dispose();
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
