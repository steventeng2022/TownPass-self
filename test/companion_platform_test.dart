// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android 宣告前景粗略與精確位置，不要求背景定位', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(manifest, contains('android.permission.ACCESS_COARSE_LOCATION'));
    expect(manifest, contains('android.permission.ACCESS_FINE_LOCATION'));
    expect(
      manifest,
      isNot(contains('android.permission.ACCESS_BACKGROUND_LOCATION')),
    );
  });
}
