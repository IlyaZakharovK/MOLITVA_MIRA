import 'dart:async';
import 'dart:io';
import 'package:android_path_provider/android_path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vsem_mirom/presentation/widgets/app_message_bar.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String url;
  final VoidCallback onClose;
  final String name;
  final String date;

  const AudioPlayerWidget({
    super.key,
    required this.url,
    required this.onClose,
    required this.name,
    required this.date
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late final AudioPlayer _player;
  late final Uri _uri;

  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _volume = 1.0;
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;

  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _playerCompleteSub;
  StreamSubscription? _playerStateSub;

  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _uri = Uri.parse(widget.url);
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      await _player.setSourceUrl(widget.url);

      _durationSub = _player.onDurationChanged.listen((d) {
        if (mounted) setState(() => _duration = d);
      });

      _positionSub = _player.onPositionChanged.listen((p) {
        if (mounted) setState(() => _position = p);
      });

      _playerCompleteSub = _player.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
          });
        }
      });

      _playerStateSub = _player.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _playerState = state;
            _isPlaying = state == PlayerState.playing;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
      }
      debugPrint('AudioPlayer error: $e');
    }
  }

  Future<void> _playPause() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.resume();
    }
  }

  Future<void> _seek(Duration value) async {
    await _player.seek(value);
  }

  Future<void> _setSpeed(double speed) async {
    if (!_hasError) {
      await _player.setPlaybackRate(speed);
      setState(() => _playbackSpeed = speed);
    }
  }

  Future<void> _downloadAudio() async {
    String? baseDownloadsPath;
    widget.onClose();
    try {
      baseDownloadsPath = await AndroidPathProvider.downloadsPath;
      debugPrint('[AUDIO_DL] baseDownloadsPath = $baseDownloadsPath');
    } catch (e) {
      debugPrint('[AUDIO_DL] Error getting downloads path: $e');
    }

    if (baseDownloadsPath == null || baseDownloadsPath.isEmpty) {
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        if (mounted) {
          showAppMessageBar(
            context,
            'Не удалось получить папку для сохранения',
            brand: Colors.redAccent
          );
        }
        return;
      }

      baseDownloadsPath = directory.path;
    }

    final saveDir = '${baseDownloadsPath}/MolitvaMira';
    final saveDirectory = Directory(saveDir);

    if (!await saveDirectory.exists()) {
      await saveDirectory.create(recursive: true);
      debugPrint('[AUDIO_DL] created dir: $saveDir');
    }

    final uri = Uri.parse(widget.url);
    String fileName = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : 'audio_${DateTime.now().millisecondsSinceEpoch}.webm';

    if (!fileName.contains('.')) {
      fileName += '.webm';
    }

    try {
      final taskId = await FlutterDownloader.enqueue(
        url: widget.url,
        savedDir: saveDir,
        fileName: fileName,
        showNotification: true,
        openFileFromNotification: false,
      );

      debugPrint('[AUDIO_DL] taskId: $taskId');
      debugPrint('[AUDIO_DL] savedDir: $saveDir');

      if (taskId == null || taskId.isEmpty) {
        throw Exception('Не удалось создать задачу загрузки');
      }

      if (mounted) {
        showAppMessageBar(
            context,
            'Загрузка начата: MolitvaMira/$fileName',
            brand: Colors.greenAccent
        );
      }
    } catch (e) {
      debugPrint('[AUDIO_DL] Download error: $e');
      if (mounted) {
        showAppMessageBar(
            context,
            "Ошибка загрузки: $e",
            brand: Colors.greenAccent
        );
      }
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _playerCompleteSub?.cancel();
    _playerStateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Заголовок только с кнопкой закрытия (меню теперь внизу)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Аудиозапись трансляции',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onClose,
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_hasError) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Приносим извинения, но запись трансляции не сохранилась по техническим причинам.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: widget.onClose,
                    child: const Text('Закрыть'),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Прогресс бар
            Column(
              children: [
                Slider(
                  min: 0,
                  max: _duration.inSeconds.toDouble(),
                  value: _position.inSeconds
                      .clamp(0, _duration.inSeconds)
                      .toDouble(),
                  onChanged: (value) {
                    _seek(Duration(seconds: value.toInt()));
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(_position)),
                      Text(_formatDuration(_duration)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Нижняя панель: play/pause, громкость, меню (три точки)
            Row(
              children: [
                // Play / Pause
                IconButton(
                  iconSize: 50,
                  icon: Icon(
                    _isPlaying ? Icons.pause_circle : Icons.play_circle,
                    color: Colors.blue,
                  ),
                  onPressed: _playPause,
                ),
                const SizedBox(width: 10),

                // Регулятор громкости
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.volume_down, size: 20),
                      Expanded(
                        child: Slider(
                          value: _volume,
                          min: 0,
                          max: 1,
                          onChanged: (value) {
                            setState(() => _volume = value);
                            _player.setVolume(value);
                          },
                        ),
                      ),
                      const Icon(Icons.volume_up, size: 20),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Меню (три точки)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    if (value == 'speed') {
                      final speed = await showDialog<double?>(
                        context: context,
                        builder: (ctx) => SimpleDialog(
                          title: const Text('Скорость воспроизведения'),
                          children: [0.5, 1.0, 1.5, 2.0].map((s) {
                            return SimpleDialogOption(
                              onPressed: () => Navigator.of(ctx).pop(s),
                              child: Text('${s}x'),
                            );
                          }).toList(),
                        ),
                      );
                      if (speed != null) {
                        await _setSpeed(speed);
                      }
                    } else if (value == 'download') {
                      await _downloadAudio();
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'speed',
                      child: Text('Скорость воспроизведения'),
                    ),
                    const PopupMenuItem(
                      value: 'download',
                      child: Text('Скачать аудио'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Отображение текущей скорости
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Скорость: ${_playbackSpeed}x',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ),
          ],
        ],
      ),
    );
  }
}