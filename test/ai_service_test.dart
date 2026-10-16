import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
        expect(data['stream'], true);
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
  const config = AiConfig(
    baseUrl: 'http://localhost/v1',
    model: 'deepseek-test',
  );
  String event(Map<String, dynamic> body) => 'data: ${jsonEncode(body)}\n\n';
  Map<String, dynamic> delta(dynamic content, {String? finish}) => {
    'choices': [
      {
        'delta': {'content': content},
        'finish_reason': finish,
      },
    ],
  };
  test('SSE handles keepalives, reasoning, UTF8 chunk boundaries and completion', () async {
    final wire =
        ': keep-alive\n\n${event({
          'choices': [
            {
              'delta': {'reasoning_content': 'hidden reasoning'},
            },
          ],
        })}${event(delta('原始'))}${event(delta('核对结果', finish: 'stop'))}data: [DONE]\n\n';
    final service = AiService(
      client: MockClient.streaming((request, _) async {
        final bytes = utf8.encode(wire);
        return http.StreamedResponse(
          Stream.fromIterable([
            for (final byte in bytes) [byte],
          ]),
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      }),
    );
    addTearDown(service.close);
    expect(await service.complete(config), '原始核对结果');
  });
  test('explicitly unsupported streaming falls back once to JSON', () async {
    final modes = <bool>[];
    final service = AiService(
      client: MockClient((request) async {
        final streaming = jsonDecode(request.body)['stream'] as bool;
        modes.add(streaming);
        if (streaming) {
          return http.Response(
            jsonEncode({
              'error': {'message': 'stream is not supported'},
            }),
            400,
          );
        }
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': [
                    {'type': 'text', 'text': 'FINAL'},
                  ],
                },
              },
            ],
          }),
          200,
        );
      }),
    );
    addTearDown(service.close);
    expect(await service.complete(config), 'FINAL');
    expect(modes, [true, false]);
  });
  test('SSE is accepted even when the proxy omits its content type', () async {
    final service = AiService(
      client: MockClient(
        (_) async => http.Response(
          '${event(delta('OK', finish: 'stop'))}data: [DONE]\n\n',
          200,
        ),
      ),
    );
    addTearDown(service.close);
    expect(await service.complete(config), 'OK');
  });
  test('truncated JSON, truncated streams and reasoning-only replies never succeed', () async {
    for (final response in [
      http.Response(
        jsonEncode({
          'choices': [
            {
              'finish_reason': 'length',
              'message': {'content': 'PARTIAL'},
            },
          ],
        }),
        200,
      ),
      http.Response(
        event(delta('PARTIAL')),
        200,
        headers: {'content-type': 'text/event-stream'},
      ),
      http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {'content': null, 'reasoning_content': 'THINKING'},
            },
          ],
        }),
        200,
      ),
    ]) {
      final service = AiService(client: MockClient((_) async => response));
      await expectLater(service.complete(config), throwsA(isA<Exception>()));
      service.close();
    }
  });
  test(
    'context errors are distinguishable for lossless batch splitting',
    () async {
      for (final code in [400, 413]) {
        final service = AiService(
          client: MockClient(
            (_) async => http.Response(
              jsonEncode({
                'error': {
                  'code': 'context_length_exceeded',
                  'message': 'input too long',
                },
              }),
              code,
            ),
          ),
        );
        await expectLater(
          service.complete(config),
          throwsA(
            isA<AiRequestException>().having(
              (e) => e.canSplitBatch,
              'canSplitBatch',
              true,
            ),
          ),
        );
        service.close();
      }
    },
  );
  test(
    'timeout is actionable and default permits slow reasoning responses',
    () async {
      final pending = Completer<http.Response>();
      final service = AiService(
        client: MockClient((_) => pending.future),
        requestTimeout: const Duration(milliseconds: 20),
      );
      await expectLater(
        service.complete(config),
        throwsA(
          isA<AiRequestException>().having(
            (e) => e.message,
            'message',
            contains('重试未完成批次'),
          ),
        ),
      );
      service.close();
      final defaults = AiService();
      expect(defaults.requestTimeout, const Duration(minutes: 5));
      defaults.close();
    },
  );
  test(
    'native HTTP transport receives streaming responses from a local server',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final served = Completer<void>();
      server.listen((request) async {
        try {
          expect(request.uri.path, '/v1/chat/completions');
          final body = jsonDecode(await utf8.decoder.bind(request).join());
          expect(body['stream'], true);
          request.response.headers.contentType = ContentType(
            'text',
            'event-stream',
            charset: 'utf-8',
          );
          request.response.write(': waiting\n\n');
          await request.response.flush();
          request.response.write(
            '${event(delta('本机协议验证', finish: 'stop'))}data: [DONE]\n\n',
          );
          await request.response.close();
          served.complete();
        } catch (e, stack) {
          served.completeError(e, stack);
        }
      });
      final service = AiService();
      addTearDown(service.close);
      expect(
        await service.complete(
          AiConfig(
            baseUrl: 'http://127.0.0.1:${server.port}/v1',
            model: 'test',
          ),
        ),
        '本机协议验证',
      );
      await served.future;
    },
  );
}
