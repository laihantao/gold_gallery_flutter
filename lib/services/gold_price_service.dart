import 'dart:async';

import 'package:html/dom.dart' as dom;
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
        // Each price ("999 Gold/Gram - RM680", "916 Gold/Gram - RM630") sits in
        // its own block element. Reading `element.text` concatenates them with
        // no separator, so the 999 value glues onto the next "916" label and is
        // parsed as "680916". Insert breaks at element boundaries to keep each
        // price on its own line before extracting.
        final text = _textWithLineBreaks(element);
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

class TomeiPriceSource implements GoldPriceSource {
  static const _url =
      'https://price-api.tomei.com.my:62443/v1.0/price/gold-jewellery-and-silver-coin-prices/live-quotes-table';

  final GoldHttpClient _client;

  TomeiPriceSource(this._client);

  @override
  String get shopName => 'Tomei';

  @override
  String get logoAsset => 'assets/images/brands/logo_tomei.jpg';

  @override
  Future<GoldPrice> fetch() async {
    try {
      final html = await _client.fetchHtml(_url);
      final document = html_parser.parse(html);
      final cells = document.querySelectorAll('td');

      double? price916;
      double? price999;

      for (var i = 0; i < cells.length - 1; i++) {
        final label = cells[i].text.trim();
        if (label == '999' && price999 == null) {
          price999 = double.tryParse(
              cells[i + 1].text.trim().replaceAll(',', ''));
        } else if (label == '916' && price916 == null) {
          price916 = double.tryParse(
              cells[i + 1].text.trim().replaceAll(',', ''));
        }
        if (price916 != null && price999 != null) break;
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

class GoldPriceService {
  static final GoldHttpClient _sharedClient = createGoldHttpClient();

  static List<GoldPriceSource> get sources => [
        PohKongPriceSource(_sharedClient),
        ChiangHengPriceSource(_sharedClient),
        TomeiPriceSource(_sharedClient),
      ];

  List<Future<GoldPrice>> fetchAll() =>
      sources.map((source) => source.fetch()).toList();
}

/// Concatenates an element's text while inserting a newline at every element
/// boundary, so sibling blocks (e.g. separate price lines) don't merge into a
/// single run of characters.
String _textWithLineBreaks(dom.Node node) {
  final buffer = StringBuffer();
  for (final child in node.nodes) {
    if (child is dom.Text) {
      buffer.write(child.text);
    } else if (child is dom.Element) {
      buffer.write(_textWithLineBreaks(child));
      buffer.write('\n');
    }
  }
  return buffer.toString();
}

double? _extractPriceAfter(String text, String pattern) {
  final index = text.indexOf(pattern);
  if (index < 0) return null;

  // Only look at the current line. Even if upstream text wasn't separated,
  // this prevents a price from swallowing digits of a following label.
  final remainder = text
      .substring(index + pattern.length)
      .split('\n')
      .first
      .trim();
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
