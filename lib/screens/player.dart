import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../model/channel.dart';

class Player extends StatefulWidget {
  final String streamUrl;
  final String name;

  Player({required this.streamUrl, required this.name});

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
        VideoPlayerController.networkUrl(Uri.parse(widget.streamUrl))
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
        title: Text(widget.name),
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
