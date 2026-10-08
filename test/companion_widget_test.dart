// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:town_pass/page/companion/companion_page.dart';
import 'package:town_pass/page/companion/facility_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const fixture =
      '行政區,公廁名稱,公廁地址,無障礙廁座數,親子廁座數,照護床位置\n士林區,僅供測試甲,測試路1號,1,0,\n信義區,僅供測試乙,測試路2號,,1,測試位置\n';
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('離線使用真實快照策略，不偽造更新時間；收藏可重新載入', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = FacilityRepository(
      prefs,
      loadSnapshot: () async => fixture,
      fetch: () async => throw Exception('離線'),
    );
    await repo.load();
    expect(repo.facilities.length, 2);
    expect(repo.origin, '內建公開資料快照');
    await repo.refresh();
    expect(repo.offline, isTrue);
    expect(repo.updatedAt, DateTime.utc(2026, 8, 24));
    await repo.toggleSaved(repo.facilities.first.id);
    final next = FacilityRepository(prefs, loadSnapshot: () async => fixture);
    await next.load();
    expect(next.saved, contains(repo.facilities.first.id));
  });
  test('有效更新快取、錯誤回應保留資料，快取可重載', () async {
    final prefs = await SharedPreferences.getInstance();
    var response = fixture;
    final repo = FacilityRepository(
      prefs,
      loadSnapshot: () async => fixture,
      fetch: () async => response,
    );
    await repo.load();
    await repo.refresh();
    expect(repo.offline, isFalse);
    expect(repo.checkedAt, isNotNull);
    response = '<html>伺服器錯誤</html>';
    await repo.refresh();
    expect(repo.facilities.length, 2);
    expect(repo.offline, isTrue);
    final next = FacilityRepository(
      prefs,
      loadSnapshot: () async => throw Exception('不可讀快照'),
    );
    await next.load();
    expect(next.origin, '本機快取');
    expect(next.facilities.length, 2);
  });
  test('損毀快取改用快照，缺失快照明確失敗', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('companion.csv', 'broken');
    final repo = FacilityRepository(prefs, loadSnapshot: () async => fixture);
    await repo.load();
    expect(repo.warning, contains('損毀'));
    final failed = FacilityRepository(
      prefs,
      loadSnapshot: () async => throw Exception('不存在'),
    );
    expect(failed.load(), throwsException);
  });
  testWidgets('搜尋、需求篩選、詳細與收藏；兩倍字體無溢出', (tester) async {
    final repo = FacilityRepository(
      await SharedPreferences.getInstance(),
      loadSnapshot: () async => fixture,
      fetch: () async => throw Exception('離線'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: CompanionPage(repository: repo),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('台北安心行'), findsOneWidget);
    await tester.tap(find.text('無障礙廁所'));
    await tester.pumpAndSettle();
    expect(find.text('僅供測試乙'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('僅供測試甲'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('僅供測試甲'));
    await tester.pumpAndSettle();
    expect(find.textContaining('臺北市政府環境保護局'), findsOneWidget);
    expect(find.textContaining('開放時間：未知'), findsOneWidget);
    await tester.tap(find.text('收藏地點'));
    await tester.pumpAndSettle();
    expect(repo.saved.length, 1);
    expect(tester.takeException(), isNull);
  });
}
