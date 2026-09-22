import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';

import 'hive_util.dart';

/// Connection settings for an OpenAI-compatible chat-completions endpoint
/// (works with DeepSeek, GLM, Moonshot, OpenAI, Ollama and most relays).
class LlmConfig {
  const LlmConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
  });

  final String baseUrl;
  final String apiKey;
  final String model;

  bool get isConfigured =>
      baseUrl.trim().isNotEmpty && apiKey.trim().isNotEmpty && model.isNotEmpty;

  static LlmConfig load() {
    return LlmConfig(
      baseUrl: ChewieHiveUtil.getString(HiveUtil.llmBaseUrlKey) ?? "",
      apiKey: ChewieHiveUtil.getString(HiveUtil.llmApiKeyKey) ?? "",
      model: ChewieHiveUtil.getString(HiveUtil.llmModelKey) ?? "",
    );
  }

  static void save({
    required String baseUrl,
    required String apiKey,
    required String model,
  }) {
    ChewieHiveUtil.put(HiveUtil.llmBaseUrlKey, baseUrl.trim());
    ChewieHiveUtil.put(HiveUtil.llmApiKeyKey, apiKey.trim());
    ChewieHiveUtil.put(HiveUtil.llmModelKey, model.trim());
  }
}

class LlmException implements Exception {
  LlmException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Minimal OpenAI-compatible chat-completions client.
abstract class LlmUtil {
  static const Duration _timeout = Duration(seconds: 90);
  static final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 15);

  static Uri _endpoint(String baseUrl) {
    var base = baseUrl.trim();
    if (!base.startsWith('http')) base = 'https://$base';
    final uri = Uri.parse(base);
    final segments = [...uri.pathSegments];
    // Accept either the API root (https://api.deepseek.com) or a full
    // chat-completions path (https://host/v1/chat/completions).
    while (segments.isNotEmpty &&
        ['chat', 'completions', ''].contains(segments.last)) {
      segments.removeLast();
    }
    return uri.replace(pathSegments: [...segments, 'chat', 'completions']);
  }

  static Future<String> chat({
    required LlmConfig config,
    required String system,
    required String user,
    bool jsonMode = false,
  }) async {
    if (!config.isConfigured) {
      throw LlmException('LLM is not configured');
    }
    final body = {
      'model': config.model,
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user},
      ],
      'temperature': 0.2,
      if (jsonMode) 'response_format': {'type': 'json_object'},
    };
    try {
      final request = await _client
          .postUrl(_endpoint(config.baseUrl))
          .timeout(const Duration(seconds: 15));
      final payload = utf8.encode(jsonEncode(body));
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer ${config.apiKey.trim()}',
      );
      // Some gateways reject chunked uploads with a bare 400; always declare
      // the exact payload length instead.
      request.contentLength = payload.length;
      request.add(payload);
      final response = await request.close().timeout(_timeout);
      final text = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) {
        throw LlmException('HTTP ${response.statusCode}: ${_trim(text)}');
      }
      final decoded = jsonDecode(text);
      String? content;
      if (decoded is Map && decoded['choices'] is List) {
        final choices = decoded['choices'] as List;
        if (choices.isNotEmpty && choices.first is Map) {
          final message = (choices.first as Map)['message'];
          if (message is Map) {
            final value = message['content'];
            if (value is String) content = value;
          }
        }
      }
      if (content == null || content.isEmpty) {
        throw LlmException('Empty completion');
      }
      return content;
    } on LlmException {
      rethrow;
    } on TimeoutException {
      throw LlmException('LLM request timed out');
    } catch (error) {
      throw LlmException('LLM request failed: $error');
    }
  }

  /// Extracts the first JSON object embedded in a completion. Models like to
  /// wrap JSON in markdown fences or a lead-in sentence despite instructions.
  static Map<String, dynamic> extractJsonObject(String text) {
    final cleaned = text.replaceAll('```json', '```');
    final start = cleaned.indexOf('{');
    if (start < 0) {
      throw const FormatException('no JSON object in completion');
    }
    var depth = 0;
    var inString = false;
    var escaped = false;
    for (var i = start; i < cleaned.length; i++) {
      final char = cleaned[i];
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (char == r'\') {
          escaped = true;
        } else if (char == '"') {
          inString = false;
        }
        continue;
      }
      if (char == '"') {
        inString = true;
      } else if (char == '{') {
        depth++;
      } else if (char == '}') {
        depth--;
        if (depth == 0) {
          final decoded = jsonDecode(cleaned.substring(start, i + 1));
          if (decoded is Map<String, dynamic>) return decoded;
          return Map<String, dynamic>.from(decoded as Map);
        }
      }
    }
    throw const FormatException('unbalanced JSON object in completion');
  }

  static String _trim(String text) =>
      text.length > 200 ? '${text.substring(0, 200)}…' : text;
}
