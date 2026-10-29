import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:caregap_app/core/api/api_client.dart';
import 'package:caregap_app/core/data/live_care_repository.dart';
import 'package:caregap_app/core/models/frontend_models.dart';
import 'package:caregap_app/core/models/user_role.dart';

void main() {
  test('patient login preserves the actual server role', () async {
    final api = ApiClient(
      'https://example.test',
      transport: MockClient(
        (req) async => http.Response(
          jsonEncode({
            'data': {
              'access_token': 'token',
              'expires_in': 3600,
              'actor': {'user_id': 'patient-id', 'role': 'patient'},
            },
          }),
          200,
        ),
      ),
    );
    final repo = LiveCareRepository(api);
    expect(
      (await repo.login('synthetic', 'synthetic-password')).role,
      UserRole.beneficiary,
    );
    api.close();
  });
  test(
    'Vision sends image bytes directly with idempotency and Bearer headers',
    () async {
      final bytes = Uint8List.fromList([137, 80, 78, 71]);
      final api = ApiClient(
        'https://example.test',
        transport: MockClient((req) async {
          expect(req.url.path, '/api/vision/analyses');
          expect(req.headers['Authorization'], 'Bearer token');
          expect(req.headers['Idempotency-Key'], 'stable-key');
          final body = jsonDecode(req.body) as Map;
          expect(body['mimeType'], 'image/png');
          expect(base64Decode(body['base64']), bytes);
          expect(body.containsKey('text'), false);
          return http.Response(
            jsonEncode({
              'data': {
                'provenance': {'ocr_used': false},
                  'result': {'care_note': 'synthetic'},
              },
            }),
            201,
          );
        }),
      )..token = 'token';
      final repo = LiveCareRepository(api);
      expect(
        (await repo.analyzeImage(
          'person',
          MediaInput(name: 'synthetic.png', bytes: bytes, kind: 'image'),
          'stable-key',
        ))['provenance']['ocr_used'],
        false,
      );
      api.close();
    },
  );
}
