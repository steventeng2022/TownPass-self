// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:town_pass/page/facility_finder/finder_location.dart';

class FinderGeolocator extends GeolocatorPlatform {
  bool enabled = true;
  LocationPermission permission = LocationPermission.denied;
  LocationPermission decision = LocationPermission.whileInUse;
  int requests = 0, fixes = 0;
  LocationSettings? settings;
  @override
  Future<bool> isLocationServiceEnabled() async => enabled;
  @override
  Future<LocationPermission> checkPermission() async => permission;
  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    return decision;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    fixes++;
    settings = locationSettings;
    return Position(
      latitude: 25.03,
      longitude: 121.54,
      timestamp: DateTime.utc(2026, 10, 18),
      accuracy: 50,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

void main() {
  late GeolocatorPlatform original;
  late FinderGeolocator platform;
  setUp(() {
    original = GeolocatorPlatform.instance;
    platform = FinderGeolocator();
    GeolocatorPlatform.instance = platform;
  });
  tearDown(() => GeolocatorPlatform.instance = original);

  test('裝置定位停用時不要求權限或取得位置', () async {
    platform.enabled = false;
    await expectLater(locateForFinder(), throwsStateError);
    expect(platform.requests, 0);
    expect(platform.fixes, 0);
  });

  test('拒絕與永久拒絕不取得位置', () async {
    platform.decision = LocationPermission.denied;
    await expectLater(locateForFinder(), throwsStateError);
    expect(platform.requests, 1);
    expect(platform.fixes, 0);
    platform.permission = LocationPermission.deniedForever;
    await expectLater(locateForFinder(), throwsStateError);
    expect(platform.requests, 1);
    expect(platform.fixes, 0);
  });

  test('允許後只取得一次位置，設定精度與逾時，無串流追蹤', () async {
    final point = await locateForFinder();
    expect(platform.requests, 1);
    expect(platform.fixes, 1);
    expect(point.latitude, 25.03);
    expect(platform.settings!.accuracy, LocationAccuracy.medium);
    expect(platform.settings!.timeLimit, const Duration(seconds: 15));
  });

  test('已授權不再要求；無法查詢瀏覽器權限時仍可主動要求', () async {
    platform.permission = LocationPermission.whileInUse;
    await locateForFinder();
    expect(platform.requests, 0);
    platform.permission = LocationPermission.unableToDetermine;
    await locateForFinder();
    expect(platform.requests, 1);
    expect(platform.fixes, 2);
  });
}
