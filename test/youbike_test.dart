// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:town_pass/page/youbike/bike_station.dart';

void main() {
  test('官方欄位數量、負值與停用狀態如實解析', () {
    final rows = parseBikeStations(
      jsonEncode([
        {
          'sno': '1',
          'sna': 'YouBike2.0_測試站',
          'sarea': '大安區',
          'ar': '測試路',
          'available_rent_bikes': 4,
          'available_return_bikes': 2,
          'Quantity': 8,
          'act': '1',
          'mday': '2026-10-09 12:59:03',
        },
        {
          'sno': '2',
          'sna': '異常站',
          'sarea': '中山區',
          'ar': '',
          'available_rent_bikes': -1,
          'available_return_bikes': null,
          'Quantity': 0,
          'act': '0',
        },
      ]),
    );
    expect(rows.length, 2);
    expect(rows.first.name, '測試站');
    expect(rows.first.rent, 4);
    expect(rows.last.rent, isNull);
    expect(rows.last.returnSlots, isNull);
    expect(rows.last.active, isFalse);
  });
  test('搜尋行政區與有車有位採交集，未知不當零', () {
    final rows = parseBikeStations(
      jsonEncode([
        {
          'sno': '1',
          'sna': '捷運站',
          'sarea': '大安區',
          'ar': '測試路',
          'available_rent_bikes': 2,
          'available_return_bikes': 1,
          'act': '1',
        },
        {
          'sno': '2',
          'sna': '捷運站二',
          'sarea': '大安區',
          'ar': '測試路',
          'available_rent_bikes': null,
          'available_return_bikes': 3,
          'act': '1',
        },
        {
          'sno': '3',
          'sna': '另一站',
          'sarea': '信義區',
          'ar': '測試路',
          'available_rent_bikes': 5,
          'available_return_bikes': 2,
          'act': '1',
        },
      ]),
    );
    expect(
      filterBikeStations(
        rows,
        query: '捷運',
        district: '大安區',
        needBike: true,
        needSlot: true,
      ).map((e) => e.id),
      ['1'],
    );
  });
  test('拒絕非 JSON 與空資料，避免把錯誤頁覆寫快取', () {
    expect(
      () => parseBikeStations('<html>error</html>'),
      throwsFormatException,
    );
    expect(() => parseBikeStations('[]'), throwsFormatException);
  });
}
