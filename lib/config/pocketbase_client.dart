import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';

import 'pocketbase_config.dart';

PocketBase createPocketBaseClient() => PocketBase(
  PocketBaseConfig.baseUrl,
  httpClientFactory: () => _TimedClient(http.Client()),
);

/// Bound both connection and response waits, before the SDK updates AuthStore.
class _TimedClient extends http.BaseClient {
  _TimedClient(this._inner);
  final http.Client _inner;
  static const _timeout = Duration(seconds: 15);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner
        .send(request)
        .timeout(
          _timeout,
          onTimeout: () {
            _inner.close();
            throw http.ClientException('Connection timed out', request.url);
          },
        );
    return http.StreamedResponse(
      response.stream.timeout(
        _timeout,
        onTimeout: (sink) {
          sink.addError(
            http.ClientException('Response timed out', request.url),
          );
          sink.close();
          _inner.close();
        },
      ),
      response.statusCode,
      contentLength: response.contentLength,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() => _inner.close();
}
