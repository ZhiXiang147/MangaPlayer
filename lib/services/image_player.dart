import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/manga_image.dart';

enum PlayerState {
  stopped,
  playing,
  paused,
}

class ImagePlayer extends ChangeNotifier {
  final List<MangaImage> images;
  int currentIndex;
  PlayerState state;
  double playInterval;
  Timer? _timer;
  bool _loop;

  ImagePlayer({
    required this.images,
    this.currentIndex = 0,
  }) : playInterval = 2.0, _loop = true;

  MangaImage? get currentImage {
    if (images.isEmpty) return null;
    if (currentIndex < 0 || currentIndex >= images.length) return null;
    return images[currentIndex];
  }

  int get totalImages => images.length;
  int get currentNumber => currentIndex + 1;

  bool get isPlaying => state == PlayerState.playing;
  bool get isPaused => state == PlayerState.paused;
  bool get isStopped => state == PlayerState.stopped;

  void play() {
    if (images.isEmpty) return;
    
    _stopTimer();
    state = PlayerState.playing;
    _startTimer();
    notifyListeners();
  }

  void pause() {
    if (state != PlayerState.playing) return;
    
    _stopTimer();
    state = PlayerState.paused;
    notifyListeners();
  }

  void resume() {
    if (state != PlayerState.paused) return;
    
    state = PlayerState.playing;
    _startTimer();
    notifyListeners();
  }

  void stop() {
    _stopTimer();
    state = PlayerState.stopped;
    notifyListeners();
  }

  void next() {
    if (images.isEmpty) return;
    
    if (currentIndex < images.length - 1) {
      currentIndex++;
    } else if (_loop) {
      currentIndex = 0;
    }
    notifyListeners();
  }

  void previous() {
    if (images.isEmpty) return;
    
    if (currentIndex > 0) {
      currentIndex--;
    } else if (_loop) {
      currentIndex = images.length - 1;
    }
    notifyListeners();
  }

  void jumpTo(int index) {
    if (index < 0 || index >= images.length) return;
    
    currentIndex = index;
    notifyListeners();
  }

  void setPlayInterval(double interval) {
    playInterval = interval.clamp(0.5, 10.0);
    
    if (isPlaying) {
      _stopTimer();
      _startTimer();
    }
    notifyListeners();
  }

  void increaseSpeed() {
    final newInterval = playInterval - 0.5;
    if (newInterval >= 0.5) {
      setPlayInterval(newInterval);
    }
  }

  void decreaseSpeed() {
    final newInterval = playInterval + 0.5;
    if (newInterval <= 10.0) {
      setPlayInterval(newInterval);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(
      Duration(milliseconds: (playInterval * 1000).toInt()),
      (_) => next(),
    );
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  static List<File> preloadNextImages(List<MangaImage> images, int currentIndex, int count) {
    List<File> files = [];
    for (int i = 1; i <= count; i++) {
      final nextIndex = currentIndex + i;
      if (nextIndex < images.length) {
        files.add(File(images[nextIndex].path));
      }
    }
    return files;
  }
}
