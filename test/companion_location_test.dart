// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:town_pass/page/companion/location_service.dart';

void main() {
  for (final failure in [UnsupportedError('不支援'), Exception('定位失敗')]) {
    test('平台或定位錯誤轉為可顯示訊息 $failure', () async {
      final service = CompanionLocation(
        serviceEnabled: () async => throw failure,
        checkPermission: () async => LocationPermission.whileInUse,
        requestPermission: () async => LocationPermission.whileInUse,
        current: () async => (latitude: 25.0, longitude: 121.5),
      );
      await expectLater(service.read(), throwsA(isA<LocationFailure>()));
    });
  }
  test('單次定位檢查服務與權限；拒絕不讀取位置', () async {
    var reads = 0, requests = 0;
    var enabled = false;
    var permission = LocationPermission.denied;
    final service = CompanionLocation(
      serviceEnabled: () async => enabled,
      checkPermission: () async => permission,
      requestPermission: () async {
        requests++;
        return permission;
      },
      current: () async {
        reads++;
        return (latitude: 25.0, longitude: 121.5);
      },
    );
    await expectLater(
      service.read(),
      throwsA(
        isA<LocationFailure>().having(
          (e) => e.message,
          'message',
          contains('未開啟'),
        ),
      ),
    );
    enabled = true;
    await expectLater(
      service.read(),
      throwsA(
        isA<LocationFailure>().having(
          (e) => e.message,
          'message',
          contains('未允許'),
        ),
      ),
    );
    expect(requests, 1);
    permission = LocationPermission.deniedForever;
    await expectLater(
      service.read(),
      throwsA(
        isA<LocationFailure>().having(
          (e) => e.message,
          'message',
          contains('設定'),
        ),
      ),
    );
    expect(requests, 1);
    expect(reads, 0);
    permission = LocationPermission.whileInUse;
    expect(await service.read(), (latitude: 25.0, longitude: 121.5));
    expect(reads, 1);
  });
}
