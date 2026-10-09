// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'bike_station.dart';

const bikeSource =
    'https://tcgbusfs.blob.core.windows.net/dotapp/youbike/v2/youbike_immediate.json';
const bikeSourcePage =
    'https://data.taipei/dataset/detail?id=c6bc8aed-557d-41d5-bfb1-8da24f78f2fb';

class BikeRepository {
  BikeRepository(this.preferences, {this.fetch, this.loadSnapshot});
  final SharedPreferences preferences;
  final Future<String> Function()? fetch, loadSnapshot;
  List<BikeStation> stations = [];
  Set<String> saved = {};
  DateTime? checkedAt;
  String origin = '';
  String? warning;
  bool get offline => warning != null;
  Future<void> load() async {
    saved = preferences.getStringList('youbike.saved')?.toSet() ?? {};
    final cached = preferences.getString('youbike.cache');
    if (cached != null) {
      try {
        stations = parseBikeStations(cached);
        origin = '本機快取';
        return;
      } catch (_) {
        warning = '快取損毀，改用內建資料';
      }
    }
    final snapshot =
        await (loadSnapshot?.call() ??
            rootBundle.loadString('assets/open_data/taipei_youbike.json'));
    stations = parseBikeStations(snapshot);
    origin = '內建公開資料快照';
  }

  Future<void> refresh() async {
    try {
      final body = await (fetch?.call() ?? _download());
      final fresh = parseBikeStations(body);
      if (fresh.length < stations.length ~/ 2) {
        throw const FormatException('資料數量異常');
      }
      stations = fresh;
      await preferences.setString('youbike.cache', body);
      checkedAt = DateTime.now();
      origin = '最近下載資料';
      warning = null;
    } catch (_) {
      warning = '更新失敗，保留既有資料；車位數不保證即時。';
    }
  }

  Future<String> _download() async {
    final response = await http
        .get(Uri.parse(bikeSource))
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) throw const FormatException('更新失敗');
    return utf8.decode(response.bodyBytes);
  }

  Future<void> toggleSaved(String id) async {
    final next = {...saved};
    if (!next.add(id)) next.remove(id);
    if (!await preferences.setStringList('youbike.saved', next.toList())) {
      throw StateError('收藏無法儲存');
    }
    saved = next;
  }
}
