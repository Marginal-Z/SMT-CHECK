import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smt_check/services/ai_service.dart';

void main() {
  test('base URLs normalized without duplicating chat endpoint', () {
    expect(
      const AiConfig(
        baseUrl: 'https://example.com/v1/',
        model: 'm',
        apiKey: 'k',
      ).endpoint.path,
      '/v1/chat/completions',
    );
    expect(
      const AiConfig(
        baseUrl: 'https://example.com/chat/completions',
        model: 'm',
        apiKey: 'k',
      ).endpoint.path,
      '/chat/completions',
    );
    expect(
      () => const AiConfig(
        baseUrl: 'http://example.com',
        model: 'm',
        apiKey: 'k',
      ).endpoint,
      throwsFormatException,
    );
    expect(
      () => const AiConfig(
        baseUrl: 'https://user:pass@example.com',
        model: 'm',
        apiKey: 'k',
      ).endpoint,
      throwsFormatException,
    );
    expect(
      () => const AiConfig(
        baseUrl: 'https://example.com?key=k',
        model: 'm',
        apiKey: 'k',
      ).endpoint,
      throwsFormatException,
    );
    expect(
      const AiConfig(
        baseUrl: 'http://localhost:11434/v1',
        model: 'm',
      ).endpoint.host,
      'localhost',
    );
  });
  test('compatible request and UTF8 reply', () async {
    final service = AiService(
      client: MockClient((req) async {
        expect(req.headers['Authorization'], 'Bearer test-secret');
        final data = jsonDecode(req.body);
        expect(data['model'], 'model-name');
        expect(data['stream'], false);
        expect(data['messages'][0]['content'], contains('不可信数据'));
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': '连接成功'},
                },
              ],
            }),
          ),
          200,
        );
      }),
    );
    expect(
      await service.complete(
        const AiConfig(
          baseUrl: 'https://example.com',
          model: 'model-name',
          apiKey: 'test-secret',
        ),
      ),
      '连接成功',
    );
    service.close();
  });
  test('redacts echoed key in HTTP error', () async {
    final service = AiService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {'message': 'bad secret-abc'},
          }),
          401,
        ),
      ),
    );
    expect(
      () => service.complete(
        const AiConfig(
          baseUrl: 'https://example.com',
          model: 'm',
          apiKey: ' secret-abc ',
        ),
      ),
      throwsA(
        predicate(
          (e) =>
              e.toString().contains('401') &&
              !e.toString().contains('secret-abc'),
        ),
      ),
    );
  });
  test('malformed and empty response produce clear errors', () async {
    for (final body in ['not json', '{"choices":[]}']) {
      final service = AiService(
        client: MockClient((_) async => http.Response(body, 200)),
      );
      expect(
        () => service.complete(
          const AiConfig(baseUrl: 'http://localhost', model: 'm'),
        ),
        throwsFormatException,
      );
    }
  });
}
