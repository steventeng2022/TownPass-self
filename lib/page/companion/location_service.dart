// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import 'facility.dart';

class LocationFailure implements Exception {
  const LocationFailure(this.message);
  final String message;
}

class CompanionLocation {
  CompanionLocation({
    required this.serviceEnabled,
    required this.checkPermission,
    required this.requestPermission,
    required this.current,
  });
  final Future<bool> Function() serviceEnabled;
  final Future<LocationPermission> Function() checkPermission;
  final Future<LocationPermission> Function() requestPermission;
  final Future<Coordinates> Function() current;
  factory CompanionLocation.device() => CompanionLocation(
    serviceEnabled: Geolocator.isLocationServiceEnabled,
    checkPermission: Geolocator.checkPermission,
    requestPermission: Geolocator.requestPermission,
    current: () async {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return (latitude: p.latitude, longitude: p.longitude);
    },
  );
  Future<Coordinates> read() async {
    try {
      return await _read();
    } on LocationFailure {
      rethrow;
    } on UnsupportedError {
      throw const LocationFailure('此平台無法提供定位；網頁請使用 HTTPS 或 localhost');
    } on MissingPluginException {
      throw const LocationFailure('此平台無法提供定位');
    } on TimeoutException {
      throw const LocationFailure('定位逾時，請稍後重試');
    } catch (_) {
      throw const LocationFailure('無法取得位置，請檢查權限與定位服務後重試');
    }
  }

  Future<Coordinates> _read() async {
    if (!await serviceEnabled()) throw const LocationFailure('定位服務未開啟，請開啟後重試');
    var permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure('定位權限已封鎖，請至系統設定允許後重試');
    }
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw const LocationFailure('未允許定位，仍可查詢與收藏');
    }
    return current();
  }
}
