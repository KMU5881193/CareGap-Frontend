import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../errors/app_exception.dart';

String requestKey() {
  final random = Random.secure();
  final b = List<int>.generate(16, (_) => random.nextInt(256));
  b[6] = (b[6] & 15) | 64;
  b[8] = (b[8] & 63) | 128;
  final h = b.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

typedef Json = Map<String, dynamic>;
String shortId(Object? value, [int length = 8]) {
  final text = value.toString();
  return text.substring(0, text.length < length ? text.length : length);
}

Json object(Object? value) {
  if (value is Map<String, dynamic>) return value;
  throw const AppException('서버 응답 형식이 계약과 다릅니다.', code: 'INVALID_RESPONSE');
}

List<Json> objects(Object? value) {
  if (value is! List) {
    throw const AppException('서버 목록 응답이 올바르지 않습니다.', code: 'INVALID_RESPONSE');
  }
  return value.map(object).toList();
}

String requiredId(Json data, String field) {
  final value = data[field];
  if (value is! String || value.isEmpty) {
    throw const AppException('서버에서 식별자를 받지 못했습니다.', code: 'INVALID_RESPONSE');
  }
  return value;
}

class ApiClient {
  ApiClient(String baseUrl, {http.Client? transport})
    : base = Uri.parse(baseUrl),
      transport = transport ?? http.Client() {
    if (base.scheme != 'https' ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        (base.path.isNotEmpty && base.path != '/') ||
        base.hasQuery ||
        base.hasFragment) {
      throw const AppException('HTTPS 백엔드 주소를 확인해 주세요.', code: 'CONFIG');
    }
  }
  final Uri base;
  final http.Client transport;
  String? token;
  DateTime? expiresAt;
  void Function()? onUnauthorized;
  void clearSession() {
    token = null;
    expiresAt = null;
  }

  Future<dynamic> request(
    String method,
    String path, {
    Json? body,
    String? key,
    bool auth = true,
  }) async {
    if (!path.startsWith('/api/') && path != '/health') {
      throw const AppException('지원하지 않는 API 경로입니다.');
    }
    if (auth &&
        (token == null || expiresAt?.isBefore(DateTime.now()) == true)) {
      _expire();
      throw const AppException('로그인이 만료됐어요. 다시 로그인해 주세요.', code: '401');
    }
    final sessionToken = token;
    try {
      final req = http.Request(method, base.resolve(path));
      req.followRedirects = false;
      req.headers['Accept'] = 'application/json';
      if (auth) req.headers['Authorization'] = 'Bearer $token';
      if (key != null) req.headers['Idempotency-Key'] = key;
      if (body != null) {
        req.headers['Content-Type'] = 'application/json';
        req.body = jsonEncode(body);
      }
      final streamed = await transport
          .send(req)
          .timeout(const Duration(seconds: 150));
      final response = await http.Response.fromStream(streamed)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 401 && auth && token == sessionToken) {
        _expire();
      }
      if (response.statusCode == 204) return null;
      dynamic payload;
      try {
        payload = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        throw AppException(
          '서버가 올바른 JSON을 반환하지 않았어요. 터널 주소와 서버 상태를 확인해 주세요.',
          code: '${response.statusCode}',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final code = payload is Map
            ? (payload['error'] is Map ? payload['error']['code'] : null)
            : null;
        throw AppException(
          '${_message(response.statusCode, code?.toString())} (${code ?? response.statusCode})',
          code: '${response.statusCode}',
        );
      }
      if (payload is! Map || !payload.containsKey('data')) {
        throw const AppException('서버 data 응답이 없습니다.', code: 'INVALID_RESPONSE');
      }
      return payload['data'];
    } on TimeoutException {
      throw const AppException(
        '서버 응답 시간이 길어지고 있어요. 처리 상태를 다시 확인해 주세요. 저장 요청은 완료됐을 수도 있습니다.',
        code: 'TIMEOUT',
      );
    } on http.ClientException {
      throw const AppException(
        '서버에 연결하지 못했어요. 네트워크와 최신 터널 주소를 확인해 주세요.',
        code: 'NETWORK',
      );
    }
  }

  void _expire() {
    clearSession();
    onUnauthorized?.call();
  }

  static String _message(int status, String? code) {
    if (code == 'IDENTIFIER_EXISTS') return '이미 등록된 아이디입니다';
    if (code == 'UNAUTHENTICATED') {
      return '아이디·비밀번호 또는 세션을 확인해 주세요. 서버 재시작 후에는 다시 가입해야 합니다';
    }
    if (status == 409) return '다른 변경과 충돌했어요. 최신 상태를 다시 조회한 뒤 확인해 주세요';
    if (status == 403) return '이 자료에 접근할 권한이 없어요';
    if (status == 429) return '요청이 많아요. 잠시 뒤 다시 시도해 주세요';
    if (status == 404) return '자료를 찾지 못했어요. 서버 재시작 여부를 확인해 주세요';
    if (status == 413) return '파일 크기가 서버 제한을 초과했어요';
    if (status == 400 || status == 422) return '입력 형식 또는 분석 근거를 확인해 주세요';
    return '서버에서 요청을 처리하지 못했어요';
  }

  void close() => transport.close();
}
