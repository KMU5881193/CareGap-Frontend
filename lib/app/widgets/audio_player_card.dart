import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import 'app_widgets.dart';

class AudioPlayerCard extends StatefulWidget {
  const AudioPlayerCard({super.key, required this.bytes, required this.name});
  final Uint8List bytes;
  final String name;
  @override
  State<AudioPlayerCard> createState() => _AudioPlayerCardState();
}

class _AudioPlayerCardState extends State<AudioPlayerCard> {
  final player = AudioPlayer();
  final subscriptions = <StreamSubscription<dynamic>>[];
  Duration position = Duration.zero, total = Duration.zero;
  bool playing = false, busy = false;
  double rate = 1;
  @override
  void initState() {
    super.initState();
    subscriptions.add(
      player.onPositionChanged.listen((v) {
        if (mounted) setState(() => position = v);
      }),
    );
    subscriptions.add(
      player.onDurationChanged.listen((v) {
        if (mounted) setState(() => total = v);
      }),
    );
    subscriptions.add(
      player.onPlayerStateChanged.listen((v) {
        if (mounted) setState(() => playing = v == PlayerState.playing);
      }),
    );
  }

  @override
  void didUpdateWidget(covariant AudioPlayerCard old) {
    super.didUpdateWidget(old);
    if (old.bytes != widget.bytes) {
      player.stop();
      position = Duration.zero;
      total = Duration.zero;
    }
  }

  @override
  void dispose() {
    for (final s in subscriptions) {
      s.cancel();
    }
    player.dispose();
    super.dispose();
  }

  String clock(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton.filled(
              tooltip: playing ? '일시정지' : '재생',
              onPressed: busy
                  ? null
                  : () async {
                      setState(() => busy = true);
                      await runCareTask(context, () async {
                        if (playing) {
                          await player.pause();
                        } else {
                          await player.play(
                            BytesSource(
                              widget.bytes,
                              mimeType:
                                  widget.name.toLowerCase().endsWith('.wav')
                                  ? 'audio/wav'
                                  : null,
                            ),
                          );
                          await player.setPlaybackRate(rate);
                        }
                      });
                      if (mounted) setState(() => busy = false);
                    },
              icon: Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.name,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            DropdownButton<double>(
              value: rate,
              items: [1.0, 1.25, 1.5]
                  .map((v) => DropdownMenuItem(value: v, child: Text('${v}x')))
                  .toList(),
              onChanged: (v) async {
                if (v == null) return;
                setState(() => rate = v);
                await runCareTask(context, () => player.setPlaybackRate(v));
              },
            ),
          ],
        ),
        Slider(
          value: position.inMilliseconds.toDouble().clamp(
            0,
            total.inMilliseconds.toDouble(),
          ),
          max: total.inMilliseconds > 0 ? total.inMilliseconds.toDouble() : 1,
          onChanged: total == Duration.zero
              ? null
              : (v) => player.seek(Duration(milliseconds: v.round())),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(clock(position)), Text(clock(total))],
        ),
      ],
    ),
  );
}
