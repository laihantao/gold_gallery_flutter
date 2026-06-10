import 'dart:async';

import 'package:html/parser.dart' as html_parser;

import '../models/gold_price.dart';
import 'http_client_factory.dart';

export 'http_client_factory.dart' show GoldPriceFetchException, kFetchTimeout;

abstract class GoldPriceSource {
  String get shopName;

  String get logoAsset;

  Future<GoldPrice> fetch();
}

class PohKongPriceSource implements GoldPriceSource {
  static const _url = 'https://www.pohkong.com.my/';
  static const _priceSelector = 'div.rte';
  static const _pricePattern916 = '916 Gold/Gram - RM';
  static const _pricePattern999 = '999 Gold/Gram - RM';

  final GoldHttpClient _client;

  PohKongPriceSource(this._client);

  @override
  String get shopName => 'Poh Kong';

  @override
  String get logoAsset => 'assets/images/brands/logo_pohkong.png';

  @override
  Future<GoldPrice> fetch() async {
    try {
      final html = await _client.fetchHtml(_url);
      final document = html_parser.parse(html);
      final rteElements = document.querySelectorAll(_priceSelector);

      double? price916;
      double? price999;

      for (final element in rteElements) {
        final text = element.text;
        price916 ??= _extractPriceAfter(text, _pricePattern916);
        price999 ??= _extractPriceAfter(text, _pricePattern999);
      }

      if (price916 == null || price999 == null) {
        throw GoldPriceFetchException(shopName, reason: 'parse');
      }

      return GoldPrice(
        shopName: shopName,
        price916: price916,
        price999: price999,
        fetchedAt: DateTime.now(),
        logoAsset: logoAsset,
      );
    } on GoldPriceFetchException catch (error) {
      if (error.shopName == shopName) rethrow;
      throw GoldPriceFetchException(shopName, reason: error.reason);
    } on TimeoutException {
      throw GoldPriceFetchException(shopName, reason: 'timeout');
    }
  }
}

class ChiangHengPriceSource implements GoldPriceSource {
  static const _url = 'https://chiangheng.com/';
  static const _headingSelector =
      'p.elementor-heading-title.elementor-size-small';
  static const _lastUpdatedPrefix = 'Last Updated :';

  final GoldHttpClient _client;

  ChiangHengPriceSource(this._client);

  @override
  String get shopName => 'Chiang Heng';

  @override
  String get logoAsset => 'assets/images/brands/logo_chiangheng.jpg';

  @override
  Future<GoldPrice> fetch() async {
    try {
      final html = await _client.fetchHtml(_url);
      final document = html_parser.parse(html);
      final headings = document.querySelectorAll(_headingSelector);

      double? price916;
      double? price999;
      String? websiteDate;

      for (final heading in headings) {
        final boldTags = heading.querySelectorAll('b');
        final rmPrices = <double>[];

        for (final bold in boldTags) {
          final price = _parseRmPrice(bold.text);
          if (price != null) {
            rmPrices.add(price);
          }
        }

        if (rmPrices.length >= 2) {
          price916 = rmPrices[0];
          price999 = rmPrices[1];
        }

        final text = heading.text;
        if (text.contains(_lastUpdatedPrefix)) {
          websiteDate = text
              .split(_lastUpdatedPrefix)
              .last
              .trim()
              .split('\n')
              .first
              .trim();
        }
      }

      if (price916 == null || price999 == null) {
        throw GoldPriceFetchException(shopName, reason: 'parse');
      }

      return GoldPrice(
        shopName: shopName,
        price916: price916,
        price999: price999,
        fetchedAt: DateTime.now(),
        websiteDate: websiteDate,
        logoAsset: logoAsset,
      );
    } on GoldPriceFetchException catch (error) {
      if (error.shopName == shopName) rethrow;
      throw GoldPriceFetchException(shopName, reason: error.reason);
    } on TimeoutException {
      throw GoldPriceFetchException(shopName, reason: 'timeout');
    }
  }
}

class GoldPriceService {
  static final GoldHttpClient _sharedClient = createGoldHttpClient();

  static List<GoldPriceSource> get sources => [
        PohKongPriceSource(_sharedClient),
        ChiangHengPriceSource(_sharedClient),
      ];

  List<Future<GoldPrice>> fetchAll() =>
      sources.map((source) => source.fetch()).toList();
}

double? _extractPriceAfter(String text, String pattern) {
  final index = text.indexOf(pattern);
  if (index < 0) return null;

  final remainder = text.substring(index + pattern.length).trim();
  final match = RegExp(r'[\d,]+(?:\.\d+)?').firstMatch(remainder);
  if (match == null) return null;

  return double.tryParse(match.group(0)!.replaceAll(',', ''));
}

double? _parseRmPrice(String text) {
  final normalized = text.replaceAll('\u00a0', ' ').trim();
  if (!normalized.toUpperCase().contains('RM')) return null;

  final match = RegExp(r'RM\s*([\d,]+(?:\.\d+)?)', caseSensitive: false)
      .firstMatch(normalized);
  if (match == null) return null;

  return double.tryParse(match.group(1)!.replaceAll(',', ''));
}
