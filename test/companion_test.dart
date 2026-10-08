import 'package:flutter_test/flutter_test.dart';
import 'package:town_pass/page/companion/facility.dart';

void main() {
  test('需求採交集，行政區與搜尋一起適用', () {
    final f = Facility({
      '公廁名稱': '僅供測試',
      '公廁地址': '測試路',
      '行政區': '士林區',
      '無障礙廁座數': '1',
      '親子廁座數': '0',
      '照護床位置': '',
    });
    expect(f.matches(query: '測試', district: '士林區', accessible: true), isTrue);
    expect(f.matches(accessible: true, family: true), isFalse);
    expect(f.matches(care: true), isFalse);
    expect(f.matches(district: '信義區'), isFalse);
    expect(Facility({'無障礙廁座數': '-1'}).accessibleSeats, isNull);
    expect(Facility({'無障礙廁座數': '無資料'}).accessibleSeats, isNull);
  });
  test('拒絕HTML、截斷CSV與缺少欄位', () {
    expect(() => Facility.parseCsv('<html>錯誤</html>'), throwsFormatException);
    expect(
      () => Facility.parseCsv('行政區,公廁名稱,公廁地址,無障礙廁座數,親子廁座數\n士林區,"未閉合'),
      throwsFormatException,
    );
  });
  test('空白與無效座數保持未知；零不是無障礙設施', () {
    final rows = Facility.parseCsv(
      '行政區,公廁名稱,公廁地址,無障礙廁座數,親子廁座數\n士林區,"測試,地點",測試地址,,0\n',
    );
    expect(rows.single.name, '測試,地點');
    expect(rows.single.accessibleSeats, isNull);
    expect(rows.single.familySeats, 0);
    expect(rows.single.matches(accessible: true), isFalse);
  });
}
