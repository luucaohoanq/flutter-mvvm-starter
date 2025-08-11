import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvvm_starter/model/media.dart';
import 'package:flutter_mvvm_starter/view_model/media_view_model.dart';
import 'package:provider/provider.dart';

enum PlayerState { stopped, playing, paused, completed, disposed }
enum PlayingRouteState { speakers, earpiece }

class PlayerWidget extends StatefulWidget {
  final Function function;

  PlayerWidget({
    Key? key,
    required this.function,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PlayerWidgetState();
  }
}

class _PlayerWidgetState extends State<PlayerWidget> {
  String? _prevSongName;

  late AudioPlayer _audioPlayer;
  Duration? _duration;
  Duration? _position;

  PlayerState _playerState = PlayerState.stopped;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateSubscription;

  get _isPlaying => _playerState == PlayerState.playing;

  _PlayerWidgetState();

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateSubscription?.cancel();
    super.dispose();
  }

  void _playCurrentMedia(Media? media) {
    if (media != null && _prevSongName != media.trackName) {
      _prevSongName = media.trackName;
      _position = null;
      _stop();
      _play(media);
    }
  }

  @override
  Widget build(BuildContext context) {
    Media? media = Provider.of<MediaViewModel>(context).media;
    _playCurrentMedia(media);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => null,
              icon: Icon(
                Icons.fast_rewind,
                size: 25.0,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.secondary
                    : Color(0xFF787878),
              ),
            ),
            ClipOval(
                child: Container(
                  color: Theme.of(context).colorScheme.secondary.withAlpha(30),
                  width: 50.0,
                  height: 50.0,
                  child: IconButton(
                    onPressed: () {
                      if (_isPlaying) {
                        widget.function();
                        _pause();
                      } else {
                        if (media != null) {
                          widget.function();
                          _play(media);
                        }
                      }
                    },
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 30.0,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                )),
            IconButton(
              onPressed: () => null,
              icon: Icon(
                Icons.fast_forward,
                size: 25.0,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.secondary
                    : Color(0xFF787878),
              ),
            ),
          ],
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 12.0, right: 12.0),
              child: Stack(
                children: [
                  Slider(
                    onChanged: (v) {
                      final position = v * _duration!.inMilliseconds;
                      _audioPlayer.seek(Duration(milliseconds: position.round()));
                    },
                    value: (_position != null &&
                        _duration != null &&
                        _position!.inMilliseconds > 0 &&
                        _position!.inMilliseconds < _duration!.inMilliseconds)
                        ? _position!.inMilliseconds / _duration!.inMilliseconds
                        : 0.0,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _initAudioPlayer() {
    _audioPlayer = AudioPlayer();

    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((p) => setState(() {
      _position = p;
    }));

    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      _onComplete();
      setState(() {
        _position = _duration;
      });
    });

    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        switch (state) {
          case PlayerState.playing:
            _playerState = PlayerState.playing;
            break;
          case PlayerState.paused:
            _playerState = PlayerState.paused;
            break;
          case PlayerState.stopped:
            _playerState = PlayerState.stopped;
            break;
          case PlayerState.completed:
            _playerState = PlayerState.completed;
            break;
          default:
            _playerState = PlayerState.stopped;
            break;
        }
      });
    });
  }

  Future<void> _play(Media media) async {
    final playPosition = (_position != null &&
        _duration != null &&
        _position!.inMilliseconds > 0 &&
        _position!.inMilliseconds < _duration!.inMilliseconds)
        ? _position
        : null;

    if (media.previewUrl != null) {
      try {
        await _audioPlayer.play(UrlSource(media.previewUrl!), position: playPosition);
        setState(() => _playerState = PlayerState.playing);

        // Set playback rate
        await _audioPlayer.setPlaybackRate(1.0);
      } catch (e) {
        print("Error playing audio: $e");
      }
    }
  }

  Future<void> _pause() async {
    await _audioPlayer.pause();
    setState(() => _playerState = PlayerState.paused);
  }

  Future<void> _stop() async {
    await _audioPlayer.stop();
    setState(() {
      _playerState = PlayerState.stopped;
      _position = Duration.zero;
    });
  }

  void _onComplete() {
    setState(() => _playerState = PlayerState.stopped);
  }
}