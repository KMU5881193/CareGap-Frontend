import 'dart:typed_data';

class ProfileData {
  const ProfileData({
    required this.name,
    this.phone = '',
    this.birthday = '',
    this.agency = '',
    this.relation = '',
  });
  final String name, phone, birthday, agency, relation;
}

class StaffAvailability {
  const StaffAvailability({
    required this.weekdays,
    required this.hours,
    required this.blockedDates,
  });
  final Set<int> weekdays, hours;
  final Set<String> blockedDates;
  static String dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
}

class MediaInput {
  const MediaInput({
    required this.name,
    required this.bytes,
    required this.kind,
  });
  final String name, kind;
  final Uint8List bytes;
}

class RecordImportResult {
  const RecordImportResult(this.text, this.file);
  final String text;
  final MediaInput file;
}

class ConversionResult {
  const ConversionResult(this.text, {this.speakers = const ['담당자', '대상자']});
  final String text;
  final List<String> speakers;
}

class HandoverRequest {
  const HandoverRequest(this.recordId, this.receiver, this.requestedAt);
  final String recordId, receiver;
  final DateTime requestedAt;
}
