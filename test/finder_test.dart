// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:town_pass/page/companion/facility.dart';
import 'package:town_pass/page/facility_finder/place.dart';
import 'package:town_pass/page/youbike/bike_station.dart';

import 'finder_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('跨來源關鍵字與行政區交集，類型及廁所需求排除未知值', () async {
    final repo = await makeFinder();
    await repo.load();
    expect(findFacilities(repo.places).length, 3);
    expect(findFacilities(repo.places, query: ' 大安區   和平路 ').length, 2);
    expect(
      findFacilities(repo.places, query: 'yOuBiKe').single.place.kind,
      FacilityKind.youbike,
    );
    expect(
      findFacilities(repo.places, district: '信義區').single.place.name,
      '乙測試公廁',
    );
    expect(findFacilities(repo.places, kind: FacilityKind.youbike).length, 1);
    expect(
      findFacilities(
        repo.places,
        accessible: true,
        family: true,
      ).single.place.name,
      '甲測試公廁',
    );
    expect(
      findFacilities(repo.places, kind: FacilityKind.youbike, accessible: true),
      isEmpty,
    );
    expect(findFacilities(repo.places, query: '不存在'), isEmpty);
  });

  test('有效座標採緯經順序；無效、非有限值與超界不產生距離', () {
    for (final value in ['', 'bad', 'NaN', 'Infinity', '-Infinity', '91']) {
      expect(GeoPoint.parse(value, 121.54), isNull);
    }
    expect(GeoPoint.parse(25.03, 181), isNull);
    final bike = FacilityPlace.youbike(parseBikeStations(finderBikes).single);
    expect(bike.point!.latitude, 25.0301);
    expect(bike.point!.longitude, 121.54);
    expect(GeoPoint.parse(0, 0), isNotNull);
    const origin = GeoPoint(25.03, 121.54);
    expect(origin.distanceTo(origin), 0);
    expect(origin.distanceTo(bike.point!), closeTo(11.12, 0.1));
    expect(
      origin.distanceTo(bike.point!),
      closeTo(bike.point!.distanceTo(origin), 0.001),
    );
    expect(
      const GeoPoint(0, 0).distanceTo(const GeoPoint(0, 180)),
      closeTo(20015086.8, 1),
    );
  });

  test('附近由近至遠，未知座標置後；半徑不包含未知且必須有位置', () async {
    final repo = await makeFinder();
    await repo.load();
    const origin = GeoPoint(25.0301, 121.54);
    final matches = findFacilities(repo.places, origin: origin);
    expect(matches.map((match) => match.place.name), [
      '丙測試站',
      '甲測試公廁',
      '乙測試公廁',
    ]);
    expect(matches.last.distanceMeters, isNull);
    expect(
      findFacilities(
        repo.places,
        origin: origin,
        radiusMeters: 5,
      ).single.place.kind,
      FacilityKind.youbike,
    );
    expect(
      findFacilities(repo.places, origin: origin, radiusMeters: 500).length,
      2,
    );
    expect(findFacilities(repo.places, radiusMeters: 500), isEmpty);
  });

  test('步行連結正確編碼；缺座標改用臺北地址，連結不攜帶使用者位置', () async {
    final repo = await makeFinder();
    await repo.load();
    final bike = repo.places.last.walkingDirections;
    expect(bike.host, 'www.google.com');
    expect(bike.path, '/maps/dir/');
    expect(bike.queryParameters, {
      'api': '1',
      'destination': '25.0301,121.54',
      'travelmode': 'walking',
    });
    final missing = repo.places[1].walkingDirections;
    expect(
      missing.queryParameters['destination'],
      contains('臺北市 信義區 松仁路2號 乙測試公廁'),
    );
    final special = FacilityPlace.toilet(
      Facility({'行政區': '大安區', '公廁名稱': '測試 A&B', '公廁地址': '和平路 #1'}),
    ).walkingDirections;
    expect(special.queryParameters['destination'], contains('和平路 #1 測試 A&B'));
    expect(special.queryParameters.containsKey('origin'), isFalse);
  });

  test('兩個既有快照可合併，保留來源 ID 與座標', () async {
    final repo = await makeFinder(
      loadToilets: () =>
          rootBundle.loadString('assets/open_data/taipei_toilets.csv'),
      loadBikes: () =>
          rootBundle.loadString('assets/open_data/taipei_youbike.json'),
    );
    await repo.load();
    expect(repo.toilets.facilities, isNotEmpty);
    expect(repo.bikes.stations.length, 1815);
    final places = repo.places;
    expect(places.map((place) => place.id).toSet().length, places.length);
    expect(
      places.where((place) => place.point != null).length,
      greaterThan(3000),
    );
    expect(
      findFacilities(
        places,
        origin: const GeoPoint(25.03, 121.54),
        radiusMeters: 500,
      ),
      isNotEmpty,
    );
  });

  test('相同來源重複資料只顯示一次，保留第一筆與既有收藏 ID', () async {
    final repo = await makeFinder(
      loadBikes: () async =>
          '[{"sno":"same","sna":"第一筆"},{"sno":"same","sna":"重複筆"}]',
    );
    await repo.load();
    expect(
      repo.places
          .where((place) => place.kind == FacilityKind.youbike)
          .single
          .name,
      '第一筆',
    );
    await repo.toggleSaved(repo.places.last);
    expect(repo.bikes.saved, {'same'});
  });

  test('一個資料來源失敗仍顯示另一個；重試恢復', () async {
    var fail = true;
    final repo = await makeFinder(
      loadToilets: () async {
        if (fail) throw StateError('快照不存在');
        return finderCsv;
      },
    );
    await repo.load();
    expect(repo.places.single.kind, FacilityKind.youbike);
    expect(repo.errors.keys, contains(FacilityKind.toilet));
    fail = false;
    await repo.load();
    expect(repo.places.length, 3);
    expect(repo.errors, isEmpty);
  });

  test('兩個來源都失敗會保留明確錯誤；手動更新可救回來源', () async {
    final repo = await makeFinder(
      loadToilets: () async => throw StateError('不可讀'),
      loadBikes: () async => throw StateError('不可讀'),
      fetchToilets: () async => finderCsv,
      fetchBikes: () async => finderBikes,
    );
    await repo.load();
    expect(repo.places, isEmpty);
    expect(repo.errors.length, 2);
    await repo.refresh();
    expect(repo.places.length, 3);
    expect(repo.errors, isEmpty);
  });

  test('離線更新不抹除來源；不會把下載時間當作來源日期', () async {
    final repo = await makeFinder();
    await repo.load();
    final ids = repo.places.map((place) => place.id).toList();
    await repo.refresh();
    expect(repo.places.map((place) => place.id), ids);
    expect(repo.toilets.warning, isNotNull);
    expect(repo.bikes.warning, isNotNull);
    expect(repo.toilets.updatedAt, DateTime.utc(2026, 8, 24));
    expect(repo.bikes.stations.single.updated, '2026-10-09 13:03:02');
  });

  test('收藏沿用既有儲存，可跨頁重載；不同來源 ID 不互相覆蓋', () async {
    final repo = await makeFinder();
    await repo.load();
    final toilet = repo.places.first;
    final bike = repo.places.last;
    await repo.toggleSaved(toilet);
    await repo.toggleSaved(bike);
    final next = await makeFinder();
    await next.load();
    expect(next.toilets.saved, {toilet.sourceId});
    expect(next.bikes.saved, {bike.sourceId});
    expect(
      findFacilities(next.places, savedOnly: true, saved: next.saved).length,
      2,
    );
    await next.toggleSaved(bike);
    expect(next.saved, {toilet.id});
    expect(repo.toilets.saved, contains(toilet.sourceId));
  });

  test('快速連續收藏同一來源的不同設施不互相覆蓋', () async {
    final repo = await makeFinder();
    await repo.load();
    await Future.wait(repo.places.map(repo.toggleSaved));
    expect(repo.saved.length, 3);
    final next = await makeFinder();
    await next.load();
    expect(next.saved, repo.saved);
    await Future.wait([
      next.toggleSaved(next.places.first),
      next.toggleSaved(next.places.first),
    ]);
    expect(next.saved.length, 3);
  });
}
