// SPDX-License-Identifier: AGPL-3.0-or-later
// 隔離網頁展示入口：不啟動上游原生通知或定位服務。
import 'package:flutter/material.dart';

import 'page/companion/companion_page.dart';
import 'page/youbike/youbike_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.ensureSemantics();
  runApp(
    MaterialApp(
      title: '台北市民日常',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'NotoSansTC',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff00695c)),
      ),
      home: const DailyServicesDemo(),
    ),
  );
}

class DailyServicesDemo extends StatelessWidget {
  const DailyServicesDemo({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('台北市民日常')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('賽前準備原型・選擇市民常用服務'),
        Card(
          child: ListTile(
            leading: const Icon(Icons.accessible_forward),
            title: const Text('台北安心行'),
            subtitle: const Text('公共廁所與親子、無障礙需求'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const CompanionPage()),
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.pedal_bike),
            title: const Text('台北 YouBike 找車位'),
            subtitle: const Text('查可借車輛、可還空位與收藏'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const YouBikePage()),
            ),
          ),
        ),
      ],
    ),
  );
}
