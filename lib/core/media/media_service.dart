import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:file_selector/file_selector.dart';
import 'package:image_picker/image_picker.dart' as images;
import 'package:record/record.dart';

import '../errors/app_exception.dart';
import '../models/frontend_models.dart';

class MediaSelectionService {
  static final instance = MediaSelectionService();
  final picker = images.ImagePicker();
  MediaInput? _recovered;
  Future<MediaInput> readFile(XFile file, String kind) async {
    final size = await file.length();
    if (size <= 0 || size > 20 * 1024 * 1024) {
      throw const AppException('체험 파일은 20MB 이하로 선택해 주세요.');
    }
    return MediaInput(
      name: file.name,
      bytes: await file.readAsBytes(),
      kind: kind,
    );
  }

  Future<MediaInput?> selectAudio() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: '음성 파일',
          extensions: ['wav', 'm4a', 'aac', 'mp3'],
          mimeTypes: ['audio/*'],
          uniformTypeIdentifiers: ['public.audio'],
        ),
      ],
    );
    return file == null ? null : readFile(file, 'audio');
  }

  Future<MediaInput?> selectImage({bool camera = false}) async {
    final file = await picker.pickImage(
      source: camera ? images.ImageSource.camera : images.ImageSource.gallery,
      maxWidth: 2048,
      imageQuality: 90,
      requestFullMetadata: false,
    );
    return file == null ? null : readFile(file, 'image');
  }

  Future<void> recoverLostData() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final response = await picker.retrieveLostData();
      final file = response.files?.firstOrNull;
      if (file != null) _recovered = await readFile(file, 'image');
    } catch (_) {
      /* 다시 선택할 수 있다. 자동 전송하지 않는다. */
    }
  }

  MediaInput? takeRecovered() {
    final file = _recovered;
    _recovered = null;
    return file;
  }
}

class AudioCapture extends ChangeNotifier {
  AudioRecorder? _recorder;
  AudioRecorder get recorder => _recorder ??= AudioRecorder();
  final _chunks = <Uint8List>[];
  StreamSubscription<Uint8List>? _subscription;
  Timer? _timer;
  bool recording = false;
  int seconds = 0;
  String? error;
  MediaInput? result;
  bool _disposed = false;
  void update() {
    if (!_disposed) notifyListeners();
  }

  Future<void> start() async {
    if (recording) return;
    if (!await recorder.hasPermission()) {
      throw const AppException('마이크 권한이 필요합니다. 기기 설정에서 마이크 사용을 허용해 주세요.');
    }
    result = null;
    error = null;
    seconds = 0;
    _chunks.clear();
    final stream = await recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );
    recording = true;
    _subscription = stream.listen(
      _chunks.add,
      onError: (Object e) {
        error = '녹음 중 오류가 발생했어요. 다시 시도해 주세요.';
        stop();
      },
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      seconds++;
      update();
      if (seconds >= 120) stop();
    });
    update();
  }

  Future<void> stop() async {
    if (!recording) return;
    recording = false;
    _timer?.cancel();
    try {
      await recorder.stop();
      await _subscription?.cancel();
      final pcm = BytesBuilder(copy: false);
      for (final part in _chunks) {
        pcm.add(part);
      }
      final bytes = pcm.takeBytes();
      if (bytes.isNotEmpty && error == null) {
        result = MediaInput(
          name: '상담_녹음.wav',
          kind: 'audio',
          bytes: makeWav(bytes),
        );
      }
    } catch (_) {
      error = '녹음을 마무리하지 못했어요. 다시 시도해 주세요.';
    }
    update();
  }

  static Uint8List makeWav(Uint8List pcm) {
    final out = Uint8List(44 + pcm.length), d = ByteData(44);
    void label(int at, String value) {
      for (var i = 0; i < value.length; i++) {
        d.setUint8(at + i, value.codeUnitAt(i));
      }
    }

    label(0, 'RIFF');
    d.setUint32(4, 36 + pcm.length, Endian.little);
    label(8, 'WAVE');
    label(12, 'fmt ');
    d.setUint32(16, 16, Endian.little);
    d.setUint16(20, 1, Endian.little);
    d.setUint16(22, 1, Endian.little);
    d.setUint32(24, 16000, Endian.little);
    d.setUint32(28, 32000, Endian.little);
    d.setUint16(32, 2, Endian.little);
    d.setUint16(34, 16, Endian.little);
    label(36, 'data');
    d.setUint32(40, pcm.length, Endian.little);
    out.setRange(0, 44, d.buffer.asUint8List());
    out.setRange(44, out.length, pcm);
    return out;
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _subscription?.cancel();
    _recorder?.dispose();
    super.dispose();
  }
}
