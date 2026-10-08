// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:town_pass/page/companion/facility.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('真實公開資料快照完整，12行政區1537列', () async {
    final rows = Facility.parseCsv(
      await rootBundle.loadString('assets/open_data/taipei_toilets.csv'),
    );
    expect(rows.length, 1537);
    expect(rows.map((f) => f.district).toSet().length, 12);
    expect(rows.first.name, '芝山文化生態綠園');
    expect(rows.first.accessibleSeats, 2);
  });
}
