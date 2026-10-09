// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:town_pass/page/home/home_view.dart';
import 'package:town_pass/util/tp_route.dart';
import 'package:town_pass/service/subscription_service.dart';

void main() {
  testWidgets('首頁提供廁所與 YouBike 兩個獨立入口', (tester) async {
    Get.put<SubscriptionService>(SubscriptionService());
    await tester.pumpWidget(
      GetMaterialApp(getPages: TPRoute.page, home: const HomeView()),
    );
    expect(find.text('台北安心行'), findsOneWidget);
    expect(find.text('台北 YouBike 找車位'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
