import 'dart:typed_data';

import '../errors/app_exception.dart';
import '../models/frontend_models.dart';

void validateUpload(String source, MediaInput file) {
  final b = file.bytes;
  if (b.isEmpty || b.length > 10 * 1024 * 1024) {
    throw const AppException('파일은 10MB 이하로 선택해 주세요.');
  }
  if (source == 'ocr') {
    final png =
        b.length >= 8 &&
        b[0] == 137 &&
        b[1] == 80 &&
        b[2] == 78 &&
        b[3] == 71 &&
        b[4] == 13 &&
        b[5] == 10 &&
        b[6] == 26 &&
        b[7] == 10;
    final jpg = b.length >= 3 && b[0] == 255 && b[1] == 216 && b[2] == 255;
    if (!png && !jpg) throw const AppException('OCR은 PNG/JPEG 사진만 지원합니다.');
    return;
  }
  String tag(int offset) => String.fromCharCodes(b.sublist(offset, offset + 4));
  if (b.length < 44 || tag(0) != 'RIFF' || tag(8) != 'WAVE') {
    throw const AppException(
      'STT에는 16kHz·모노·PCM16 WAV가 필요합니다. 앱 녹음을 이용하거나 파일을 변환해 주세요.',
    );
  }
  final data = ByteData.sublistView(b);
  bool format = false, audio = false;
  for (int at = 12; at + 8 <= b.length;) {
    final size = data.getUint32(at + 4, Endian.little), start = at + 8;
    if (start + size > b.length) throw const AppException('손상된 WAV 파일입니다.');
    if (tag(at) == 'fmt ') {
      if (size < 16 ||
          data.getUint16(start, Endian.little) != 1 ||
          data.getUint16(start + 2, Endian.little) != 1 ||
          data.getUint32(start + 4, Endian.little) != 16000 ||
          data.getUint16(start + 14, Endian.little) != 16) {
        throw const AppException('16kHz·모노·PCM16 WAV만 전송할 수 있습니다.');
      }
      format = true;
    }
    if (tag(at) == 'data') audio = size > 0;
    at = start + size + (size % 2);
  }
  if (!format || !audio) throw const AppException('유효한 음성 데이터가 없는 WAV입니다.');
}
