// SPDX-License-Identifier: AGPL-3.0-or-later
// Isolated live demo: avoids unrelated upstream native-service initialization.
import 'package:flutter/material.dart';

import 'page/companion/companion_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.ensureSemantics();
  runApp(
    MaterialApp(
      title: '台北安心行',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'NotoSansTC',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff00695c)),
      ),
      home: const CompanionPage(),
    ),
  );
}
