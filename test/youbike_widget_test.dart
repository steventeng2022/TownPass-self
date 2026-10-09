// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:town_pass/page/youbike/bike_repository.dart';
import 'package:town_pass/page/youbike/youbike_page.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('可搜尋場站並檢視來源；大字體可捲動', (tester) async {
    final repo = BikeRepository(
      await SharedPreferences.getInstance(),
      loadSnapshot: () async => '[{"sno":"1","sna":"YouBike2.0_僅供測試站","sarea":"大安區","ar":"測試路1號","available_rent_bikes":2,"available_return_bikes":1,"act":"1"}]',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: YouBikePage(repository: repo),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('台北 YouBike 找車位'), findsOneWidget);
    expect(find.text('只看有車'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '僅供測試');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('僅供測試站'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('僅供測試站'));
    await tester.pumpAndSettle();
    expect(find.textContaining('臺北市政府交通局'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
