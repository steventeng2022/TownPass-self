// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'facility.dart';

const sourcePage =
    'https://data.taipei/dataset/detail?id=ca205b54-a06f-4d84-894c-d6ab5079ce79';
const sourceDownload =
    'https://data.taipei/api/frontstage/tpeod/dataset/resource.download?rid=9e0e6ad4-b9f9-4810-8551-0cffd1b915b3';

class FacilityRepository {
  FacilityRepository(
    this.preferences, {
    Future<String> Function()? loadSnapshot,
    Future<String> Function()? fetch,
  }) : loadSnapshot =
           loadSnapshot ??
           (() => rootBundle.loadString('assets/open_data/taipei_toilets.csv')),
       fetch = fetch ?? download;
  final SharedPreferences preferences;
  final Future<String> Function() loadSnapshot;
  final Future<String> Function() fetch;
  List<Facility> facilities = [];
  Set<String> saved = {};
  DateTime updatedAt = DateTime.utc(2026, 8, 24);
  DateTime? checkedAt;
  bool offline = false;
  String origin = '內建公開資料快照';
  String? warning;
  bool get stale => DateTime.now().toUtc().difference(updatedAt).inDays > 30;
  static Future<String> download() async {
    final client = http.Client();
    try {
      final response = await client
          .get(Uri.parse(sourceDownload))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) throw Exception('資料來源回應異常');
      if (response.bodyBytes.length > 5000000) {
        throw const FormatException('資料過大');
      }
      return utf8.decode(response.bodyBytes);
    } finally {
      client.close();
    }
  }

  Future<void> load() async {
    saved = (preferences.getStringList('companion.saved') ?? []).toSet();
    final cached = preferences.getString('companion.csv');
    if (cached != null) {
      try {
        facilities = Facility.parseCsv(cached);
        if (facilities.isEmpty) throw const FormatException('空資料');
        checkedAt = DateTime.tryParse(
          preferences.getString('companion.checkedAt') ?? '',
        );
        origin = '本機快取';
        return;
      } catch (_) {
        warning = '本機快取損毀，改用內建公開資料快照';
      }
    }
    facilities = Facility.parseCsv(await loadSnapshot());
    if (facilities.isEmpty) throw const FormatException('公開資料快照為空');
  }

  Future<void> refresh() async {
    try {
      final csv = await fetch();
      final parsed = Facility.parseCsv(csv);
      if (parsed.isEmpty) throw const FormatException('空資料');
      final now = DateTime.now().toUtc();
      if (!await preferences.setString('companion.csv', csv)) {
        throw Exception('無法儲存快取');
      }
      await preferences.setString('companion.checkedAt', now.toIso8601String());
      facilities = parsed;
      checkedAt = now;
      origin = '公開來源下載（已快取）';
      offline = false;
      warning = null;
      // Retrieval time is NOT the provider's publication timestamp.
    } catch (_) {
      offline = true;
      warning = '更新失敗／可能離線，保留既有資料；可稍後重試';
    }
  }

  Future<void> toggleSaved(String id) async {
    final next = {...saved};
    if (!next.remove(id)) next.add(id);
    if (!await preferences.setStringList('companion.saved', next.toList())) {
      throw Exception('無法儲存收藏');
    }
    saved = next;
  }
}
