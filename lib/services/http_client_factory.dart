import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

const Duration kFetchTimeout = Duration(seconds: 5);

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
    final response = await http.get(Uri.parse(url)).timeout(kFetchTimeout);
    if (response.statusCode != 200) {
      throw GoldPriceFetchException(url, reason: 'http_${response.statusCode}');
    }
    return response.body;
  }
}

class ProxyHttpClient implements GoldHttpClient {
  @override
  Future<String> fetchHtml(String url) async {
    try {
      return await _fetchViaAllOrigins(url);
    } catch (primaryError) {
      try {
        return await _fetchViaCorsProxy(url);
      } catch (_) {
        throw primaryError;
      }
    }
  }

  Future<String> _fetchViaAllOrigins(String url) async {
    final proxyUrl =
        'https://api.allorigins.win/get?url=${Uri.encodeComponent(url)}';
    final response = await http.get(Uri.parse(proxyUrl)).timeout(kFetchTimeout);
    if (response.statusCode != 200) {
      throw GoldPriceFetchException(url, reason: 'proxy_${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final contents = json['contents'] as String?;
    if (contents == null || contents.isEmpty) {
      throw GoldPriceFetchException(url, reason: 'proxy_empty');
    }
    return contents;
  }

  Future<String> _fetchViaCorsProxy(String url) async {
    final proxyUrl = 'https://corsproxy.io/?${Uri.encodeComponent(url)}';
    final response = await http.get(Uri.parse(proxyUrl)).timeout(kFetchTimeout);
    if (response.statusCode != 200) {
      throw GoldPriceFetchException(
        url,
        reason: 'proxy_${response.statusCode}',
      );
    }
    if (response.body.isEmpty) {
      throw GoldPriceFetchException(url, reason: 'proxy_empty');
    }
    return response.body;
  }
}

GoldHttpClient createGoldHttpClient() =>
    kIsWeb ? ProxyHttpClient() : NativeHttpClient();
