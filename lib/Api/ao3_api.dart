import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../Models/ao3_work.dart';
import '../Utils/ao3_config.dart';
import '../Utils/ao3_parser.dart';
import 'demo/ao3_demo.dart';
import 'demo/demo_mode.dart';

/// Why an AO3 request could not produce a work. The reader maps these to
/// actionable states instead of a generic failure.
enum Ao3Failure {
  /// Proxy missing or host unreachable.
  network,
  timeout,

  /// AO3 served its block page ("Shields are up!").
  blocked,

  /// The work does not exist (or was deleted).
  notFound,

  /// AO3 redirected to the sign-in page: the work is archive-locked.
  loginRequired,

  /// 200, but the payload is not a work export.
  notAWork,

  /// The feature is switched off in settings.
  disabled,
}

class Ao3Exception implements Exception {
  const Ao3Exception(this.failure, [this.detail = '']);

  final Ao3Failure failure;
  final String detail;

  bool get retryable =>
      failure == Ao3Failure.network || failure == Ao3Failure.timeout;

  @override
  String toString() => 'Ao3Exception(' +
      failure.name +
      (detail.isEmpty ? '' : ': ' + detail) +
      ')';
}

class Ao3FetchResult {
  const Ao3FetchResult({
    required this.statusCode,
    required this.body,
    this.finalUrl = '',
  });

  final int statusCode;
  final String body;

  /// URL after redirects; AO3 sends archive-locked works to the login page.
  final String finalUrl;
}

/// Injected by tests so no case touches the network.
typedef Ao3Fetcher = Future<Ao3FetchResult> Function(Uri url);

abstract final class Ao3Api {
  /// AO3 blocks clients that pretend to be a browser: a Chrome user-agent from
  /// a non-browser TLS stack is answered with 403 "Shields are up!", while an
  /// honest, identifiable agent is served normally. Keep this truthful — it is
  /// also how AO3 can contact us about traffic.
  static const String userAgent =
      'Loftify/2.6.3 (+https://github.com/Yar1991-Translation/Loftify)';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration requestTimeout = Duration(seconds: 45);
  static const Duration retryDelay = Duration(milliseconds: 600);
  static const int maxAttempts = 3;

  /// The whole work (every chapter) in a single request — AO3's own export.
  static Uri exportUrl(int workId) => Uri.parse(
      'https://archiveofourown.org/downloads/' + workId.toString() + '/Work.html');

  static Future<Ao3Work> fetchWork(
    int workId, {
    Ao3Fetcher? fetcher,
    Ao3Config? config,
    int attempts = maxAttempts,
  }) async {
    if (DemoMode.enabled) {
      return Ao3Demo.sample(workId);
    }
    final settings = config ?? Ao3Config.load();
    if (!settings.enabled) {
      throw const Ao3Exception(Ao3Failure.disabled);
    }
    final fetch = fetcher ?? defaultFetcher(settings);
    Ao3Exception? lastFailure;
    for (var attempt = 1; attempt <= attempts; attempt++) {
      try {
        final result = await fetch(exportUrl(workId));
        _throwForFailure(result);
        final work = Ao3Parser.parse(result.body, workId: workId);
        if (work == null) {
          throw const Ao3Exception(
              Ao3Failure.notAWork, 'response is not a work export');
        }
        return work;
      } on Ao3Exception catch (error) {
        if (!error.retryable || attempt == attempts) rethrow;
        lastFailure = error;
        await Future<void>.delayed(retryDelay * attempt);
      }
    }
    throw lastFailure ?? const Ao3Exception(Ao3Failure.network);
  }

  /// Maps a transport result onto a failure, or returns for a usable 200.
  static void _throwForFailure(Ao3FetchResult result) {
    final finalUrl = result.finalUrl.toLowerCase();
    if (finalUrl.contains('users/login') ||
        finalUrl.contains('restricted=true')) {
      throw const Ao3Exception(
          Ao3Failure.loginRequired, 'work requires signing in');
    }
    if (result.statusCode == 200) {
      if (result.body.contains('Shields are up!')) {
        throw const Ao3Exception(Ao3Failure.blocked, 'block page returned');
      }
      return;
    }
    if (result.statusCode == 403) {
      throw const Ao3Exception(Ao3Failure.blocked, 'HTTP 403');
    }
    if (result.statusCode == 404) {
      throw const Ao3Exception(Ao3Failure.notFound, 'HTTP 404');
    }
    if (result.statusCode >= 500) {
      throw Ao3Exception(
          Ao3Failure.network, 'HTTP ' + result.statusCode.toString());
    }
    throw Ao3Exception(
        Ao3Failure.network, 'HTTP ' + result.statusCode.toString());
  }

  /// Real transport: one request per work, so a short-lived client is enough.
  ///
  /// Dart's `HttpClient` ignores the OS proxy settings, which is why [config]
  /// carries one explicitly.
  static Ao3Fetcher defaultFetcher(Ao3Config config) {
    return (Uri url) async {
      final client = HttpClient()..connectionTimeout = connectTimeout;
      client.userAgent = userAgent;
      final proxy = Ao3Config.findProxyValue(config.proxy);
      if (proxy != null) {
        client.findProxy = (host) => proxy;
      }
      try {
        final request =
            await client.getUrl(url).timeout(const Duration(seconds: 20));
        request.headers.set(HttpHeaders.acceptHeader,
            'text/html,application/xhtml+xml;q=0.9,*/*;q=0.8');
        request.headers.set(HttpHeaders.acceptLanguageHeader,
            'en-US,en;q=0.9,zh-CN;q=0.8');
        final response = await request.close().timeout(requestTimeout);
        final body = await response.transform(utf8.decoder).join();
        final finalUrl = response.redirects.isNotEmpty
            ? response.redirects.last.location.toString()
            : url.toString();
        return Ao3FetchResult(
          statusCode: response.statusCode,
          body: body,
          finalUrl: finalUrl,
        );
      } on TimeoutException catch (error) {
        throw Ao3Exception(Ao3Failure.timeout, error.toString());
      } on SocketException catch (error) {
        throw Ao3Exception(Ao3Failure.network, error.message);
      } on HandshakeException catch (error) {
        throw Ao3Exception(Ao3Failure.network, error.message);
      } on HttpException catch (error) {
        throw Ao3Exception(Ao3Failure.network, error.message);
      } finally {
        client.close(force: true);
      }
    };
  }
}
