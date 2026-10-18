// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:shared_preferences/shared_preferences.dart';
import 'package:town_pass/page/companion/facility_repository.dart';
import 'package:town_pass/page/facility_finder/finder_repository.dart';
import 'package:town_pass/page/youbike/bike_repository.dart';

const finderCsv =
    '行政區,公廁名稱,公廁地址,無障礙廁座數,親子廁座數,經度,緯度\n'
    '大安區,甲測試公廁,和平路1號,1,1,121.54,25.03\n'
    '信義區,乙測試公廁,松仁路2號,,1,,\n';
const finderBikes =
    '[{"sno":"bike-1","sna":"YouBike2.0_丙測試站",'
    '"sarea":"大安區","ar":"和平路3號","available_rent_bikes":2,'
    '"available_return_bikes":3,"act":"1","latitude":25.0301,"longitude":121.54,'
    '"mday":"2026-10-09 13:03:02"}]';

Future<FinderRepository> makeFinder({
  Future<String> Function()? loadToilets,
  Future<String> Function()? loadBikes,
  Future<String> Function()? fetchToilets,
  Future<String> Function()? fetchBikes,
}) async {
  final preferences = await SharedPreferences.getInstance();
  return FinderRepository(
    toilets: FacilityRepository(
      preferences,
      loadSnapshot: loadToilets ?? () async => finderCsv,
      fetch: fetchToilets ?? () async => throw StateError('離線'),
    ),
    bikes: BikeRepository(
      preferences,
      loadSnapshot: loadBikes ?? () async => finderBikes,
      fetch: fetchBikes ?? () async => throw StateError('離線'),
    ),
  );
}
