// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:town_pass/page/companion/companion_page.dart';
import 'package:town_pass/page/companion/facility_repository.dart';

const fixture =
    '行政區,公廁名稱,公廁地址,無障礙廁座數,親子廁座數\n士林區,僅供測試甲,測試路1號,1,0\n士林區,僅供測試乙,測試路2號,0,1\n';
Future<FacilityRepository> openTools(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final repo = FacilityRepository(
    await SharedPreferences.getInstance(),
    loadSnapshot: () async => fixture,
  );
  await tester.pumpWidget(MaterialApp(home: CompanionPage(repository: repo)));
  await tester.pumpAndSettle();
  expect(find.text('安心生活工具'), findsOneWidget);
  await tester.scrollUntilVisible(
    find.text('安心生活工具'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.text('安心生活工具'));
  await tester.pumpAndSettle();
  return repo;
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text),
    200,
    scrollable: find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('個人備註與未查證紀錄重新開啟仍在本機，短句可放大', (tester) async {
    SharedPreferences.setMockInitialValues({
      'companion.card': '僅供測試離線備註',
      'companion.reports': <String>['僅供測試紀錄・未查證・僅此裝置'],
    });
    final repo = FacilityRepository(
      await SharedPreferences.getInstance(),
      loadSnapshot: () async => fixture,
      fetch: () async => throw Exception('offline'),
    );
    await tester.pumpWidget(MaterialApp(home: CompanionPage(repository: repo)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('安心生活工具'));
    await tester.pumpAndSettle();
    await tapText(tester, '我的安心卡');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '僅供測試離線備註',
    );
    await tapText(tester, '請問最近的廁所在哪裡？');
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('關閉'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('設施有變'),
      -250,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tapText(tester, '設施有變');
    expect(find.text('僅供測試紀錄・未查證・僅此裝置'), findsOneWidget);
  });
  testWidgets('工具頁顯示來源且320px兩倍文字各功能不溢出', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = await openTools(tester);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: CompanionPage(repository: repo),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('安心生活工具'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('安心生活工具'));
    await tester.pumpAndSettle();
    expect(find.textContaining('政府資料開放授權條款第1版'), findsOneWidget);
    for (final section in ['雨天台北', '一鍵休息', '台北小探險', '設施有變', '我的安心卡']) {
      await tester.scrollUntilVisible(
        find.text(section),
        -300,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.ensureVisible(find.text(section));
      await tester.tap(find.text(section));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('安心出門的本次停靠顯示可移除', (tester) async {
    await openTools(tester);
    await tapText(tester, '僅供測試甲');
    await tapText(tester, '加入本次停靠');
    expect(find.text('本次停靠：僅供測試甲'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('移除本次停靠'));
    await tester.tap(find.byTooltip('移除本次停靠'));
    await tester.pumpAndSettle();
    expect(find.text('本次停靠：僅供測試甲'), findsNothing);
  });
  testWidgets('我的安心卡離線短句、收藏停靠與自願個人備註可清除', (tester) async {
    final repo = await openTools(tester);
    await repo.toggleSaved(repo.facilities.first.id);
    await tapText(tester, '我的安心卡');
    expect(find.text('請問最近的廁所在哪裡？'), findsOneWidget);
    expect(find.text('僅供測試甲'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '僅供測試的自願備註');
    tester.testTextInput.hide();
    await tapText(tester, '儲存在此裝置');
    expect(repo.preferences.getString('companion.card'), '僅供測試的自願備註');
    await tapText(tester, '清除個人備註');
    expect(repo.preferences.getString('companion.card'), '');
  });
  testWidgets('設施有變寫本機未查證紀錄，不變更官方設施且可刪除', (tester) async {
    final repo = await openTools(tester);
    await tapText(tester, '設施有變');
    await tapText(tester, '僅供測試甲');
    await tapText(tester, '記下暫停使用');
    expect(find.textContaining('未查證・僅此裝置'), findsWidgets);
    expect(repo.preferences.getStringList('companion.reports'), isNotEmpty);
    expect(repo.facilities.first.accessibleSeats, 1);
    await tapText(tester, '刪除此紀錄');
    expect(repo.preferences.getStringList('companion.reports'), isEmpty);
  });
  testWidgets('小探險以自訂30分鐘意向選真實資料目的地，不估算路程', (tester) async {
    await openTools(tester);
    await tapText(tester, '台北小探險');
    expect(find.textContaining('30分鐘是自訂預算'), findsOneWidget);
    await tapText(tester, '僅供測試甲');
    expect(find.textContaining('目的地：僅供測試甲'), findsOneWidget);
    await tapText(tester, '加入本次停靠');
    expect(find.textContaining('本次停靠：僅供測試甲'), findsOneWidget);
  });
  testWidgets('一鍵休息廁所有來源，座椅飲水室內不假造匹配', (tester) async {
    await openTools(tester);
    await tapText(tester, '一鍵休息');
    await tapText(tester, '座椅');
    expect(find.textContaining('座椅：資料未提供'), findsOneWidget);
    expect(find.text('僅供測試甲'), findsNothing);
    await tapText(tester, '飲水');
    expect(find.textContaining('飲水：資料未提供'), findsOneWidget);
    await tapText(tester, '室內');
    expect(find.textContaining('室內：資料未提供'), findsOneWidget);
    await tapText(tester, '廁所');
    expect(find.text('僅供測試甲'), findsOneWidget);
  });
  testWidgets('雨天台北不從地點名稱推論室內遮蔽', (tester) async {
    await openTools(tester);
    await tapText(tester, '雨天台北');
    expect(find.textContaining('室內與遮蔽資料未提供'), findsOneWidget);
    expect(find.text('僅供測試甲'), findsNothing);
    expect(find.text('查看臺北旅遊網官方景點'), findsOneWidget);
  });
  testWidgets('安心出門預設只使用登載座數，選目的地後可收藏', (tester) async {
    final repo = await openTools(tester);
    await tapText(tester, '推嬰兒車');
    expect(find.text('僅供測試乙'), findsOneWidget);
    expect(find.text('僅供測試甲'), findsNothing);
    await tapText(tester, '僅供測試乙');
    expect(find.textContaining('目的地：僅供測試乙'), findsOneWidget);
    await tapText(tester, '收藏為安心停靠點');
    expect(repo.saved, contains(repo.facilities.last.id));
    expect(find.textContaining('不保證無障礙路線'), findsOneWidget);
  });
}
