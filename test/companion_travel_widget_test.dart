// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:town_pass/page/companion/companion_page.dart';
import 'package:town_pass/page/companion/facility_repository.dart';

const fixture =
    '行政區,公廁名稱,公廁地址,無障礙廁座數,親子廁座數,緯度,經度\n士林區,僅供測試遠,測試遠路,1,0,25.1,121.5\n士林區,僅供測試近,測試近路,1,1,25,121.5\n士林區,僅供測試未知,測試未知路,0,0,,\n';
void main() {
  for (final name in ['僅供測試近', '僅供測試未知']) {
    testWidgets('選定地點開啟外部地圖 $name', (tester) async {
      Uri? launched;
      final repo = FacilityRepository(
        await SharedPreferences.getInstance(),
        loadSnapshot: () async => fixture,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: CompanionPage(
            repository: repo,
            openMaps: (uri) async {
              launched = uri;
              return false;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(name),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text(name));
      await tester.pumpAndSettle();
      await tester.tap(find.text(name));
      await tester.pumpAndSettle();
      expect(find.textContaining('不保證路線無障礙'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('開啟外部地圖路線'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('開啟外部地圖路線'));
      await tester.pumpAndSettle();
      expect(launched?.host, 'www.google.com');
      expect(launched?.path, '/maps/dir/');
      expect(
        launched?.queryParameters['destination'],
        name == '僅供測試近' ? '25.0,121.5' : '臺北市 士林區 測試未知路 僅供測試未知',
      );
      expect(launched?.queryParameters.containsKey('origin'), isFalse);
      expect(find.text('無法開啟外部地圖，請複製地址後自行查詢'), findsOneWidget);
    });
  }
  for (final failure in [
    Exception('denied'),
    UnsupportedError('platform'),
    Exception('service disabled'),
  ]) {
    testWidgets('定位失敗保留結果 ${failure.toString()}', (tester) async {
      final repo = FacilityRepository(
        await SharedPreferences.getInstance(),
        loadSnapshot: () async => fixture,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: CompanionPage(
            repository: repo,
            locate: () async => throw failure,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('依目前位置排序'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('同意並取得位置'));
      await tester.pumpAndSettle();
      expect(find.textContaining('保留既有結果'), findsOneWidget);
      expect(repo.facilities.length, 3);
      expect(tester.takeException(), isNull);
    });
  }
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('明確同意才定位、距離排序、停止後恢復來源順序', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var requests = 0;
    final repo = FacilityRepository(
      await SharedPreferences.getInstance(),
      loadSnapshot: () async => fixture,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CompanionPage(
          repository: repo,
          locate: () async {
            requests++;
            return (latitude: 25.0, longitude: 121.5);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(requests, 0);
    await tester.tap(find.text('依目前位置排序'));
    await tester.pumpAndSettle();
    expect(requests, 0);
    expect(find.textContaining('不會背景追蹤'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(requests, 0);
    await tester.tap(find.text('依目前位置排序'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('同意並取得位置'));
    await tester.pumpAndSettle();
    expect(requests, 1);
    await tester.scrollUntilVisible(
      find.text('僅供測試近'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester.getTopLeft(find.text('僅供測試近')).dy,
      lessThan(tester.getTopLeft(find.text('僅供測試遠')).dy),
    );
    expect(find.textContaining('直線距離約 0 公尺'), findsOneWidget);
    expect(find.textContaining('直線距離約 11.1 公里'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('僅供測試未知')).dy,
      greaterThan(tester.getTopLeft(find.text('僅供測試遠')).dy),
    );
    expect(find.textContaining('缺少有效座標'), findsWidgets);
    await tester.tap(find.text('親子廁所'));
    await tester.pumpAndSettle();
    expect(find.text('僅供測試近'), findsOneWidget);
    expect(find.text('僅供測試遠'), findsNothing);
    await tester.tap(find.text('親子廁所'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('停止使用位置'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('停止使用位置'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('僅供測試遠'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester.getTopLeft(find.text('僅供測試遠')).dy,
      lessThan(tester.getTopLeft(find.text('僅供測試近')).dy),
    );
    expect(tester.takeException(), isNull);
  });
}
