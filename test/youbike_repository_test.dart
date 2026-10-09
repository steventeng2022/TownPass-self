// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:town_pass/page/youbike/bike_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const snapshot =
      '[{"sno":"1","sna":"YouBike2.0_測試站","sarea":"大安區","ar":"測試路","available_rent_bikes":1,"available_return_bikes":2,"act":"1"}]';
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('離線快照與收藏持久化、失敗不抹除站點', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = BikeRepository(
      prefs,
      loadSnapshot: () async => snapshot,
      fetch: () async => throw Exception('離線'),
    );
    await repo.load();
    expect(repo.stations.length, 1);
    await repo.toggleSaved('1');
    await repo.refresh();
    expect(repo.stations.length, 1);
    expect(repo.offline, isTrue);
    final next = BikeRepository(prefs, loadSnapshot: () async => snapshot);
    await next.load();
    expect(next.saved, contains('1'));
  });
  test('更新成功才替換；損毀快取回退真實快照', () async {
    final prefs = await SharedPreferences.getInstance();
    var response = snapshot;
    final repo = BikeRepository(
      prefs,
      loadSnapshot: () async => snapshot,
      fetch: () async => response,
    );
    await repo.load();
    await repo.refresh();
    expect(repo.offline, isFalse);
    response = jsonEncode([
      {'sno': '2', 'sna': '新版站', 'sarea': '信義區'},
    ]);
    await repo.refresh();
    expect(repo.stations.first.id, '2');
    response = '<html>錯誤</html>';
    await repo.refresh();
    expect(repo.stations.first.id, '2');
    await prefs.setString('youbike.cache', 'broken');
    final fallback = BikeRepository(prefs, loadSnapshot: () async => snapshot);
    await fallback.load();
    expect(fallback.stations.first.id, '1');
  });
}
