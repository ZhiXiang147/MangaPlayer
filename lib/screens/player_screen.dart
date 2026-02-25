import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/image_player.dart';

class PlayerScreen extends StatefulWidget {
  final ImagePlayer player;

  const PlayerScreen({super.key, required this.player});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late ImagePlayer _player;
  DateTime? _lastTapTime;
  Timer? _hideControlsTimer;
  bool _controlsVisible = true;
  Offset? _dragStart;

  @override
  void initState() {
    super.initState();
    _player = widget.player;
    _player.play();
    _startHideControlsTimer();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _player.isPlaying) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _showControls() {
    setState(() => _controlsVisible = true);
    _startHideControlsTimer();
  }

  @override
  void dispose() {
    _player.dispose();
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  void _onDoubleTap() {
    setState(() {
      if (_player.isPlaying) {
        _player.pause();
      } else {
        _player.resume();
      }
      _showControls();
    });
  }

  void _onLongPressEnd() {
    Navigator.pop(context);
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (details.primaryVelocity == null) return;

    if (details.primaryVelocity! > 0) {
      _player.previous();
    } else {
      _player.next();
    }
    _showControls();
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (details.primaryVelocity == null) return;

    if (details.primaryVelocity! > 0) {
      _player.decreaseSpeed();
      _showSnackBar('Speed decreased: ${_player.playInterval}s');
    } else {
      _player.increaseSpeed();
      _showSnackBar('Speed increased: ${_player.playInterval}s');
    }
    _showControls();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildImage(),
          if (_controlsVisible) _buildControls(),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return GestureDetector(
      onTap: () {
        final now = DateTime.now();
        if (_lastTapTime != null &&
            now.difference(_lastTapTime!) < const Duration(milliseconds: 300)) {
          _onDoubleTap();
          _lastTapTime = null;
        } else {
          _lastTapTime = now;
          _showControls();
        }
      },
      onLongPressEnd: (_) => _onLongPressEnd(),
      onHorizontalDragEnd: _onHorizontalDragEnd,
      onVerticalDragEnd: _onVerticalDragEnd,
      child: Container(
        color: Colors.black,
        child: _player.currentImage != null
            ? Image.file(
                File(_player.currentImage!.path),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.white, size: 48),
                        SizedBox(height: 16),
                        Text(
                          'Error loading image',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                },
              )
            : const Center(
                child: Text(
                  'No image',
                  style: TextStyle(color: Colors.white),
                ),
              ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment(0, 0.3),
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildPlaybackInfo(),
            const SizedBox(height: 8),
            _buildSpeedControl(),
            const SizedBox(height: 8),
            _buildPauseButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaybackInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_player.currentNumber} / ${_player.totalImages}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(width: 8),
          Icon(
            _player.isPlaying ? Icons.play_arrow : Icons.pause,
            color: Colors.white,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedControl() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.speed,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '${_player.playInterval}s',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPauseButton() {
    return IconButton(
      icon: Icon(_player.isPlaying ? Icons.pause : Icons.play_arrow),
      color: Colors.white,
      onPressed: () {
        if (_player.isPlaying) {
          _player.pause();
        } else {
          _player.resume();
        }
        setState(() {});
        _showControls();
      },
    );
  }
}
