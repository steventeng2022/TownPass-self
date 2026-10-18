// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:town_pass/daily_services_demo.dart';
import 'package:town_pass/page/facility_finder/finder_page.dart';
import 'package:town_pass/page/facility_finder/place.dart';

import 'finder_fixtures.dart';

Future<void> reveal(WidgetTester tester, Finder finder) => tester
    .scrollUntilVisible(finder, 250, scrollable: find.byType(Scrollable).first);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('預設不定位或下載；搜尋、需求篩選、重設與收藏', (tester) async {
    var located = 0, downloaded = 0;
    final repo = await makeFinder(
      fetchBikes: () async {
        downloaded++;
        return finderBikes;
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: FinderPage(
          repository: repo,
          locate: () async {
            located++;
            return const GeoPoint(25.03, 121.54);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(located, 0);
    expect(downloaded, 0);
    await tester.enterText(find.byType(TextField), '不存在');
    await reveal(tester, find.text('沒有符合的設施，請調整關鍵字、需求或距離範圍。'));
    await tester.tap(find.text('清除篩選'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('無障礙廁所'),
      -250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('無障礙廁所'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('甲測試公廁'));
    expect(find.text('乙測試公廁'), findsNothing);
    expect(find.text('丙測試站'), findsNothing);
    await tester.tap(find.byTooltip('收藏設施').first);
    await tester.pumpAndSettle();
    expect(repo.saved.length, 1);
    await tester.tap(find.text('甲測試公廁'));
    await tester.pumpAndSettle();
    expect(find.text('設施詳細資料'), findsOneWidget);
    expect(find.text('取消收藏'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('主動定位後才依距離排序，可限制範圍及清除位置', (tester) async {
    var located = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: FinderPage(
          repository: await makeFinder(),
          locate: () async {
            located++;
            return const GeoPoint(25.0301, 121.54);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(located, 0);
    await reveal(tester, find.text('尋找附近設施'));
    await tester.tap(find.text('尋找附近設施'));
    await tester.pumpAndSettle();
    expect(located, 1);
    await reveal(tester, find.text('500 公尺內'));
    await tester.tap(find.text('500 公尺內'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('符合 2 處設施'));
    final shown = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .where(
          (tile) =>
              tile.title is Text &&
              ['丙測試站', '甲測試公廁'].contains((tile.title as Text).data),
        );
    expect((shown.first.title as Text).data, '丙測試站');
    await tester.scrollUntilVisible(
      find.text('清除位置'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('清除位置'));
    await tester.pumpAndSettle();
    expect(find.text('500 公尺內'), findsNothing);
    await reveal(tester, find.text('符合 3 處設施'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('定位拒絕不阻擋手動搜尋，來源失敗可重試', (tester) async {
    var fail = true;
    final repo = await makeFinder(
      loadToilets: () async {
        if (fail) throw StateError('不可讀');
        return finderCsv;
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: FinderPage(
          repository: repo,
          locate: () async => throw StateError('未取得定位權限；仍可手動搜尋。'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await reveal(tester, find.text('尋找附近設施'));
    await tester.tap(find.text('尋找附近設施'));
    await tester.pumpAndSettle();
    expect(find.text('未取得定位權限；仍可手動搜尋。'), findsOneWidget);
    await reveal(tester, find.text('公廁資料載入失敗，請重試'));
    fail = false;
    await tester.tap(find.text('重試載入資料'));
    await tester.pumpAndSettle();
    expect(repo.places.length, 3);
    expect(repo.errors, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('缺少座標以地址開啟地圖，失敗提供可恢復提示', (tester) async {
    Uri? launched;
    await tester.pumpWidget(
      MaterialApp(
        home: FinderPage(
          repository: await makeFinder(),
          openUrl: (uri) async {
            launched = uri;
            return false;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await reveal(tester, find.text('乙測試公廁'));
    await tester.tap(find.text('乙測試公廁'));
    await tester.pumpAndSettle();
    expect(find.textContaining('缺少有效座標'), findsOneWidget);
    await reveal(tester, find.text('開啟 Google 地圖步行路線'));
    await tester.tap(find.text('開啟 Google 地圖步行路線'));
    await tester.pumpAndSettle();
    expect(launched!.queryParameters['destination'], contains('松仁路2號'));
    expect(launched!.queryParameters['travelmode'], 'walking');
    expect(find.text('無法開啟外部頁面；可複製地址後自行搜尋。'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('窄螢幕兩倍字體可搜尋、開啟詳細及返回', (tester) async {
    tester.view.reset();
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: FinderPage(repository: await makeFinder()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '甲測試');
    await reveal(tester, find.text('甲測試公廁'));
    await tester.tap(find.text('甲測試公廁'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('開啟 Google 地圖步行路線'));
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('設施快找'), findsOneWidget);
  });

  testWidgets('離開頁面後完成定位不會更新已銷毀狀態', (tester) async {
    final location = Completer<GeoPoint>();
    await tester.pumpWidget(
      MaterialApp(
        home: FinderPage(
          repository: await makeFinder(),
          locate: () => location.future,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await reveal(tester, find.text('尋找附近設施'));
    await tester.tap(find.text('尋找附近設施'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    location.complete(const GeoPoint(25.03, 121.54));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('展示首頁可進入快找並載入真實內建快照', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DailyServicesDemo()));
    // Large asset decoding needs real event-loop time, while pumpAndSettle only
    // advances the fake animation clock. Exercise the default production path.
    await tester.runAsync(() async {
      await tester.tap(find.text('設施快找'));
      await tester.pump();
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (find.text('找一處，讓出門更方便').evaluate().isEmpty &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();
    expect(find.text('找一處，讓出門更方便'), findsOneWidget);
    expect(find.byType(FinderPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
