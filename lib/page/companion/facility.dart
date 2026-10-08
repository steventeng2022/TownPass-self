// SPDX-License-Identifier: AGPL-3.0-or-later
class Facility {
  Facility(this.fields);
  final Map<String, String> fields;
  String value(String key) => fields[key]?.trim() ?? '';
  String get name => value('公廁名稱');
  String get district => value('行政區');
  String get address => value('公廁地址');
  String get id => '$district|$name|$address';
  int? seats(String key) {
    final n = int.tryParse(value(key));
    return n != null && n >= 0 ? n : null;
  }

  int? get accessibleSeats => seats('無障礙廁座數');
  int? get familySeats => seats('親子廁座數');
  bool matches({
    String query = '',
    String district = '',
    bool accessible = false,
    bool family = false,
    bool care = false,
  }) =>
      (district.isEmpty || this.district == district) &&
      '$name $address ${this.district}'.contains(query.trim()) &&
      (!accessible || (accessibleSeats ?? 0) > 0) &&
      (!family || (familySeats ?? 0) > 0) &&
      (!care || value('照護床位置').isNotEmpty);

  // RFC 4180: quoted commas, escaped quotes and embedded line breaks.
  static List<Facility> parseCsv(String text) {
    final rows = <List<String>>[];
    var row = <String>[];
    var field = StringBuffer();
    var quoted = false;
    text = text.replaceFirst('\uFEFF', '');
    for (var i = 0; i < text.length; i++) {
      final c = text[i];
      if (c == '"') {
        if (quoted && i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = !quoted;
        }
      } else if (!quoted && (c == ',' || c == '\n' || c == '\r')) {
        row.add(field.toString());
        field = StringBuffer();
        if (c != ',') {
          if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
          if (row.any((s) => s.isNotEmpty)) rows.add(row);
          row = <String>[];
        }
      } else {
        field.write(c);
      }
    }
    if (quoted) throw const FormatException('CSV 引號未閉合');
    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }
    if (rows.isEmpty ||
        ![
          '行政區',
          '公廁名稱',
          '公廁地址',
          '無障礙廁座數',
          '親子廁座數',
        ].every(rows.first.contains)) {
      throw const FormatException('資料欄位不符');
    }
    final headers = rows.first.map((s) => s.trim()).toList();
    return rows
        .skip(1)
        .map((r) {
          if (r.length != headers.length) {
            throw const FormatException('資料列欄位不符');
          }
          return Facility(Map.fromIterables(headers, r));
        })
        .where((f) => f.name.isNotEmpty && f.address.isNotEmpty)
        .toList();
  }
}
