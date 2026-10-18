// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:geolocator/geolocator.dart';

import 'place.dart';

// Called only by an explicit user action; no stream, storage or background work.
Future<GeoPoint> locateForFinder() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw StateError('請先開啟裝置定位服務；仍可使用名稱與行政區搜尋。');
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.unableToDetermine) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.deniedForever) {
    throw StateError('定位權限已封鎖，請至裝置或瀏覽器設定調整；仍可手動搜尋。');
  }
  if (permission != LocationPermission.whileInUse &&
      permission != LocationPermission.always) {
    throw StateError('未取得定位權限；仍可使用名稱與行政區搜尋。');
  }
  final position = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.medium,
      timeLimit: Duration(seconds: 15),
    ),
  );
  final point = GeoPoint.parse(position.latitude, position.longitude);
  if (point == null) throw StateError('無法取得有效位置，請重試。');
  return point;
}
