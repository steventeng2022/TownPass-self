// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:town_pass/page/companion/facility.dart';

void main() {
  test('來源座標須成對、有限且在範圍內；不推測地址位置', () {
    final valid = Facility({'緯度': '25.0', '經度': '121.5'});
    expect(valid.coordinates?.latitude, 25);
    expect(valid.coordinates?.longitude, 121.5);
    for (final fields in <Map<String, String>>[
      {},
      {'緯度': '25'},
      {'緯度': 'NaN', '經度': '121'},
      {'緯度': '91', '經度': '121'},
      {'緯度': '25', '經度': '181'},
      {'緯度': '25', '經度': 'Infinity'},
    ]) {
      expect(Facility(fields).coordinates, isNull);
    }
  });
}
