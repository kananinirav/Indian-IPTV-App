import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class Player extends StatefulWidget {
  final String? url;
  const Player({super.key, required this.url});

  @override
  State<StatefulWidget> createState() => _Player();
}

class _Player extends State<Player> {
  late VideoPlayerController _controller;
  bool _isFullscreen = true;
  int _selectedControl = -1;
  bool _isError = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      _controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.url ?? ""))
            ..addListener(() {
              if (_controller.value.hasError) {
                setState(() {
                  _isError = true;
                });
              } else {
                setState(() {});
              }
            })
            ..setLooping(false);
      await _controller.initialize();
      if (!mounted) return;
      setState(() {});
      _controller.play();
      _startHideControlsTimer(); // Start the timer when the video starts playing
    } catch (e) {
      setState(() {
        _isError = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _hideControlsTimer
        ?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
      _resetHideControlsTimer(); // Reset the timer when toggling fullscreen
    });
  }

  void _selectControl(int index) {
    setState(() {
      _selectedControl = index;
      _resetHideControlsTimer(); // Reset the timer when a control is selected
    });
  }

  void _resetHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _showControls = true;
    _startHideControlsTimer();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer = Timer(const Duration(seconds: 10), () {
      setState(() {
        _showControls = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
          _resetHideControlsTimer(); // Reset the timer when the user taps the screen
        },
        child: Center(
          child: SingleChildScrollView(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                _isError
                    ? const Center(
                        child: Text(
                          'Channel not available now',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      )
                    : Container(
                        child: _controller.value.isInitialized
                            ? (_isFullscreen
                                ? AspectRatio(
                                    aspectRatio: _controller.value.aspectRatio,
                                    child: VideoPlayer(_controller),
                                  )
                                : Container(
                                    height: 400,
                                    width: double.infinity,
                                    child: AspectRatio(
                                      aspectRatio:
                                          _controller.value.aspectRatio,
                                      child: VideoPlayer(_controller),
                                    ),
                                  ))
                            : Container(),
                      ),
                if (!_isError && _showControls)
                  _ControlsOverlay(
                    controller: _controller,
                    isFullscreen: _isFullscreen,
                    toggleFullscreen: _toggleFullscreen,
                    selectedControl: _selectedControl,
                    selectControl: _selectControl,
                  ),
                if (!_isError && _showControls)
                  VideoProgressIndicator(_controller, allowScrubbing: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({
    super.key,
    required this.controller,
    required this.isFullscreen,
    required this.toggleFullscreen,
    required this.selectedControl,
    required this.selectControl,
  });

  final VideoPlayerController controller;
  final bool isFullscreen;
  final VoidCallback toggleFullscreen;
  final int selectedControl;
  final Function(int) selectControl;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Container(
          color: Colors.black26,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 50),
              reverseDuration: const Duration(milliseconds: 200),
              child: Row(
                children: [
                  MaterialButton(
                    onPressed: () {
                      controller.value.isPlaying
                          ? controller.pause()
                          : controller.play();
                      selectControl(1);
                    },
                    color: selectedControl == 1 ? Colors.white : Colors.white,
                    child: Icon(
                      controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.red,
                      size: 30.0,
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  MaterialButton(
                    onPressed: toggleFullscreen,
                    color: selectedControl == 3 ? Colors.white : Colors.white,
                    child: Icon(
                      isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                      color: Colors.red,
                      size: 30.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
