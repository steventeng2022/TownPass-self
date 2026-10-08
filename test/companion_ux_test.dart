// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:town_pass/page/companion/companion_page.dart';
import 'package:town_pass/page/companion/facility_repository.dart';

const fixture =
    '行政區,公廁名稱,公廁地址,無障礙廁座數,親子廁座數\n士林區,僅供測試甲,測試路1號,1,0\n信義區,僅供測試乙,測試路2號,0,1\n';
Future<FacilityRepository> showPage(
  WidgetTester tester, {
  bool reduced = false,
  double scale = 1,
}) async {
  SharedPreferences.setMockInitialValues({});
  final repo = FacilityRepository(
    await SharedPreferences.getInstance(),
    loadSnapshot: () async => fixture,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          disableAnimations: reduced,
          textScaler: TextScaler.linear(scale),
        ),
        child: CompanionPage(repository: repo),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

Future<void> reveal(
  WidgetTester tester,
  Finder finder, {
  double delta = 180,
}) async {
  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('載入失敗重試立即呈現載入狀態且可恢復', (tester) async {
    SharedPreferences.setMockInitialValues({});
    var fail = true;
    final retry = Completer<String>();
    final repo = FacilityRepository(
      await SharedPreferences.getInstance(),
      loadSnapshot: () async {
        if (fail) throw Exception('僅供測試');
        return retry.future;
      },
    );
    await tester.pumpWidget(MaterialApp(home: CompanionPage(repository: repo)));
    await tester.pumpAndSettle();
    fail = false;
    await tester.tap(find.text('重試'));
    await tester.pump();
    expect(find.text('無法載入公開資料，請重試'), findsNothing);
    expect(find.text('正在載入公開資料…'), findsOneWidget);
    retry.complete(fixture);
    await tester.pumpAndSettle();
    expect(find.text('台北安心行'), findsOneWidget);
  });
  testWidgets('資料來源預設收合，可展開查看下載時間', (tester) async {
    await showPage(tester);
    expect(find.textContaining('最近成功下載：'), findsNothing);
    await tester.tap(find.text('資料來源與更新時間'));
    await tester.pumpAndSettle();
    expect(find.textContaining('最近成功下載：'), findsOneWidget);
  });
  testWidgets('結果具有穩定識別且減少動態停用詳細頁轉場', (tester) async {
    await showPage(tester, reduced: true);
    await reveal(tester, find.text('僅供測試甲'));
    expect(
      tester
          .widget<Card>(
            find.ancestor(of: find.text('僅供測試甲'), matching: find.byType(Card)),
          )
          .key,
      isNotNull,
    );
    await tester.tap(find.text('僅供測試甲'));
    await tester.pump();
    final route = ModalRoute.of(tester.element(find.text('地點詳細資料')))!;
    expect(route.transitionDuration, Duration.zero);
    await tester.pumpAndSettle();
  });
  testWidgets('無結果可一鍵清除全部條件，320px兩倍字體與減少動態仍可操作', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await showPage(tester, reduced: true, scale: 2);
    await reveal(tester, find.byType(TextField));
    await tester.enterText(find.byType(TextField), '不存在');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await reveal(tester, find.text('清除全部條件'));
    await tester.tap(find.text('清除全部條件'));
    await tester.pumpAndSettle();
    expect(find.text('符合 2 個地點'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('清除搜尋保留需求條件並收起鍵盤', (tester) async {
    await showPage(tester);
    await reveal(tester, find.byType(TextField));
    await tester.enterText(find.byType(TextField), '不存在');
    await tester.pumpAndSettle();
    expect(find.byTooltip('清除搜尋'), findsOneWidget);
    await tester.tap(find.byTooltip('清除搜尋'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(tester.testTextInput.isVisible, isFalse);
    await reveal(tester, find.text('符合 2 個地點'));
    expect(find.text('符合 2 個地點'), findsOneWidget);
  });
}
