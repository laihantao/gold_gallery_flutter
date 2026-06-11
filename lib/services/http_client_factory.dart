import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

const Duration kFetchTimeout = Duration(seconds: 20);

/// Browser-like headers. Some shop sites (e.g. WordPress/Cloudflare-protected
/// chiangheng.com) stall or never respond to bare `Dart/x.x` requests, which
/// surfaces in-app as a fetch "timeout". Presenting a normal browser
/// User-Agent and Accept headers lets these requests complete promptly.
const Map<String, String> _browserHeaders = {
  'User-Agent':
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
  'Accept':
      'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
  'Accept-Language': 'en-US,en;q=0.9',
};

class GoldPriceFetchException implements Exception {
  final String shopName;
  final String reason;

  GoldPriceFetchException(this.shopName, {required this.reason});

  @override
  String toString() => 'GoldPriceFetchException($shopName, $reason)';
}

abstract class GoldHttpClient {
  Future<String> fetchHtml(String url);
}

class NativeHttpClient implements GoldHttpClient {
  @override
  Future<String> fetchHtml(String url) async {
    final response = await http
        .get(Uri.parse(url), headers: _browserHeaders)
        .timeout(kFetchTimeout);
    if (response.statusCode != 200) {
      throw GoldPriceFetchException(url, reason: 'http_${response.statusCode}');
    }
    return response.body;
  }
}

/// A CORS proxy: builds the proxied request URL and extracts the HTML from the
/// proxy's response body.
class _Proxy {
  final String Function(String url) buildUrl;
  final String Function(String body) extract;

  const _Proxy(this.buildUrl, this.extract);
}

class ProxyHttpClient implements GoldHttpClient {
  /// Ordered fallback chain. Browsers can't reach cross-origin sites directly,
  /// so on web we relay through public CORS proxies. We try several because any
  /// one of them can be rate-limited, return 413 for large pages, or drop its
  /// CORS headers at any time — when that happens we move on to the next.
  ///
  /// Ordering rationale:
  ///  1. codetabs — reliable CORS headers, raw body.
  ///  2. allorigins /get (JSON-wrapped) — handles large pages better than /raw
  ///     because the JSON envelope uses chunked encoding; promoted from last.
  ///  3. allorigins /raw — fast but sometimes returns CORS-less error pages
  ///     when the upstream site blocks the proxy IP.
  ///  4. corsproxy.io — enforces a ~1 MB response limit (gives 413 for heavy
  ///     pages like chiangheng.com); kept as fallback for smaller sites.
  ///  5. thingproxy — additional fallback with different infrastructure.
  static final List<_Proxy> _proxies = [
    _Proxy(
      (url) =>
          'https://api.codetabs.com/v1/proxy/?quest=${Uri.encodeComponent(url)}',
      (body) => body,
    ),
    _Proxy(
      (url) =>
          'https://api.allorigins.win/get?url=${Uri.encodeComponent(url)}',
      (body) {
        final decoded = jsonDecode(body) as Map<String, dynamic>;
        return (decoded['contents'] as String?) ?? '';
      },
    ),
    _Proxy(
      (url) =>
          'https://api.allorigins.win/raw?url=${Uri.encodeComponent(url)}',
      (body) => body,
    ),
    _Proxy(
      (url) => 'https://corsproxy.io/?url=${Uri.encodeComponent(url)}',
      (body) => body,
    ),
    _Proxy(
      (url) =>
          'https://thingproxy.freeboard.io/fetch/${Uri.encodeComponent(url)}',
      (body) => body,
    ),
  ];

  @override
  Future<String> fetchHtml(String url) async {
    Object? lastError;

    for (final proxy in _proxies) {
      try {
        // No custom request headers here: this path runs in the browser, where
        // headers like User-Agent are forbidden. The proxy fetches the target
        // server-side with its own browser-like UA, which is what matters.
        final response =
            await http.get(Uri.parse(proxy.buildUrl(url))).timeout(kFetchTimeout);

        if (response.statusCode != 200) {
          lastError = GoldPriceFetchException(
            url,
            reason: 'proxy_${response.statusCode}',
          );
          continue;
        }

        final contents = proxy.extract(response.body);
        if (contents.isEmpty) {
          lastError = GoldPriceFetchException(url, reason: 'proxy_empty');
          continue;
        }
        return contents;
      } catch (error) {
        lastError = error;
        // Try the next proxy in the chain.
      }
    }

    if (lastError is GoldPriceFetchException) throw lastError;
    throw GoldPriceFetchException(url, reason: 'proxy_unreachable');
  }
}

GoldHttpClient createGoldHttpClient() =>
    kIsWeb ? ProxyHttpClient() : NativeHttpClient();
