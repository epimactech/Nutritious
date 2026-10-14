import 'dart:convert';

import 'package:http/http.dart' as http;
import '../models/producer.dart';

/// Configure these paths to match your Django REST API.
/// The dashboard never invents production values: if analytics endpoints are
/// not configured or return no records, the relevant chart shows an empty state.
class DashboardApiConfig {
  final String baseUrl;
  final String producersPath;
  final String? summaryPath;
  final String? productionTrendPath;
  final String? categoryBreakdownPath;
  final String? regionBreakdownPath;
  final String? authToken;

  const DashboardApiConfig({
    required this.baseUrl,
    required this.producersPath,
    this.summaryPath,
    this.productionTrendPath,
    this.categoryBreakdownPath,
    this.regionBreakdownPath,
    this.authToken,
  });
}

class DashboardSummary {
  final int totalProducers;
  final int verifiedProducers;
  final int activeProducers;
  final int categories;
  final double? totalProduction;
  final String? productionUnit;

  const DashboardSummary({
    required this.totalProducers,
    required this.verifiedProducers,
    required this.activeProducers,
    required this.categories,
    this.totalProduction,
    this.productionUnit,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '');
    }

    int toInt(dynamic v) => (toDouble(v) ?? 0).round();

    return DashboardSummary(
      totalProducers: toInt(json['total_producers'] ?? json['total'] ?? json['producer_count']),
      verifiedProducers: toInt(json['verified_producers'] ?? json['verified_count']),
      activeProducers: toInt(json['active_producers'] ?? json['active_count']),
      categories: toInt(json['categories'] ?? json['category_count']),
      totalProduction: toDouble(json['total_production'] ?? json['production_total']),
      productionUnit: (json['production_unit'] ?? json['unit'])?.toString(),
    );
  }
}

class DashboardPoint {
  final String label;
  final double value;
  final String? unit;

  const DashboardPoint({required this.label, required this.value, this.unit});

  factory DashboardPoint.fromJson(Map<String, dynamic> json, {required String labelKey, required String valueKey}) {
    final raw = json[valueKey];
    final value = raw is num ? raw.toDouble() : double.tryParse(raw?.toString() ?? '') ?? 0;
    return DashboardPoint(
      label: (json[labelKey] ?? '').toString(),
      value: value,
      unit: json['unit']?.toString(),
    );
  }
}

class DashboardData {
  final List<Producer> producers;
  final DashboardSummary summary;
  final List<DashboardPoint> productionTrend;
  final List<DashboardPoint> categoryBreakdown;
  final List<DashboardPoint> regionBreakdown;

  const DashboardData({
    required this.producers,
    required this.summary,
    required this.productionTrend,
    required this.categoryBreakdown,
    required this.regionBreakdown,
  });
}

class DashboardApiService {
  final DashboardApiConfig config;
  final http.Client _client;
  final bool _ownsClient;

  DashboardApiService({required this.config, http.Client? client})
      : _client = client ?? http.Client(),
        _ownsClient = client == null;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        if (config.authToken != null && config.authToken!.isNotEmpty)
          'Authorization': 'Bearer ${config.authToken}',
      };

  Uri _uri(String path) {
    final base = config.baseUrl.endsWith('/')
        ? config.baseUrl.substring(0, config.baseUrl.length - 1)
        : config.baseUrl;
    final endpoint = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$endpoint');
  }

  Future<http.Response> _get(String path) async {
    final response = await _client
        .get(_uri(path), headers: _headers)
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException(
        'GET ${_uri(path)} failed with HTTP ${response.statusCode}: ${response.body}',
        _uri(path),
      );
    }
    return response;
  }

  dynamic _decode(http.Response response) => jsonDecode(response.body);

  Future<DashboardData> fetchDashboard() async {
    final results = await Future.wait<dynamic>([
      _getList(config.producersPath),
      _getOptionalObject(config.summaryPath),
      _getPoints(
        config.productionTrendPath,
        labelKeys: const ['month', 'period', 'date', 'label', 'year'],
        valueKeys: const ['quantity', 'production', 'total', 'value'],
      ),
      _getPoints(
        config.categoryBreakdownPath,
        labelKeys: const ['category', 'name', 'label'],
        valueKeys: const ['quantity', 'production', 'count', 'value'],
      ),
      _getPoints(
        config.regionBreakdownPath,
        labelKeys: const ['region', 'name', 'label'],
        valueKeys: const ['quantity', 'production', 'count', 'value'],
      ),
    ]);

    final producers = results[0] as List<Producer>;
    final apiSummary = results[1] as Map<String, dynamic>?;
    final trend = results[2] as List<DashboardPoint>;
    var categories = results[3] as List<DashboardPoint>;
    var regions = results[4] as List<DashboardPoint>;

    // Fallback charts show producer counts, not production tonnage.
    final categoryCounts = <String, int>{};
    final regionCounts = <String, int>{};
    for (final producer in producers) {
      final category = producer.category.trim().isEmpty
          ? 'Unspecified'
          : producer.category.trim();
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;

      final regionHighlight = producer.highlights
          .where((h) => h.toLowerCase().startsWith('region:'))
          .firstOrNull;
      if (regionHighlight != null) {
        final region = regionHighlight
            .substring(regionHighlight.indexOf(':') + 1)
            .trim();
        if (region.isNotEmpty) {
          regionCounts[region] = (regionCounts[region] ?? 0) + 1;
        }
      }
    }

    if (categories.isEmpty) {
      categories = categoryCounts.entries
          .map((e) => DashboardPoint(
                label: e.key,
                value: e.value.toDouble(),
                unit: 'producers',
              ))
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    }
    if (regions.isEmpty) {
      regions = regionCounts.entries
          .map((e) => DashboardPoint(
                label: e.key,
                value: e.value.toDouble(),
                unit: 'producers',
              ))
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    }

    final verified = producers.where((p) => p.verified).length;
    final active = producers.where((p) => p.openNow).length;
    final summary = apiSummary != null
        ? DashboardSummary.fromJson(apiSummary).copyWithFallback(
            totalProducers: producers.length,
            verifiedProducers: verified,
            activeProducers: active,
            categories: categoryCounts.length,
          )
        : DashboardSummary(
            totalProducers: producers.length,
            verifiedProducers: verified,
            activeProducers: active,
            categories: categoryCounts.length,
          );

    return DashboardData(
      producers: producers,
      summary: summary,
      productionTrend: trend,
      categoryBreakdown: categories,
      regionBreakdown: regions,
    );
  }

  Future<List<Producer>> _getList(String path) async {
    final body = _decode(await _get(path));
    dynamic rows = body;
    if (body is Map) {
      rows = body['results'] ??
          body['data'] ??
          body['producers'] ??
          body['items'] ??
          [];
      if (rows is Map) rows = rows['results'] ?? rows['data'] ?? [];
    }
    if (rows is! List) {
      throw const FormatException(
        'Producer API response must be a list or a paginated object.',
      );
    }
    return rows
        .whereType<Map>()
        .map((row) => Producer.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<Map<String, dynamic>?> _getOptionalObject(String? path) async {
    if (path == null || path.trim().isEmpty) return null;
    final body = _decode(await _get(path));
    if (body is Map) {
      final nested = body['data'] ?? body['summary'] ?? body;
      if (nested is Map) return Map<String, dynamic>.from(nested);
    }
    return null;
  }

  Future<List<DashboardPoint>> _getPoints(
    String? path, {
    required List<String> labelKeys,
    required List<String> valueKeys,
  }) async {
    if (path == null || path.trim().isEmpty) return [];
    final body = _decode(await _get(path));
    dynamic rows = body;
    if (body is Map) {
      rows = body['results'] ??
          body['data'] ??
          body['items'] ??
          body['series'] ??
          [];
    }
    if (rows is! List) return [];

    return rows.whereType<Map>().map((row) {
      final json = Map<String, dynamic>.from(row);
      final labelKey = labelKeys.firstWhere(
        (key) => json.containsKey(key),
        orElse: () => labelKeys.first,
      );
      final valueKey = valueKeys.firstWhere(
        (key) => json.containsKey(key),
        orElse: () => valueKeys.first,
      );
      return DashboardPoint.fromJson(
        json,
        labelKey: labelKey,
        valueKey: valueKey,
      );
    }).where((point) => point.label.isNotEmpty).toList();
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}

extension on DashboardSummary {
  DashboardSummary copyWithFallback({
    required int totalProducers,
    required int verifiedProducers,
    required int activeProducers,
    required int categories,
  }) {
    return DashboardSummary(
      totalProducers: this.totalProducers == 0 ? totalProducers : this.totalProducers,
      verifiedProducers: this.verifiedProducers == 0 ? verifiedProducers : this.verifiedProducers,
      activeProducers: this.activeProducers == 0 ? activeProducers : this.activeProducers,
      categories: this.categories == 0 ? categories : this.categories,
      totalProduction: totalProduction,
      productionUnit: productionUnit,
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
