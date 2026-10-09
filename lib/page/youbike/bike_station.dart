// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:convert';

class BikeStation {
  const BikeStation({
    required this.id,
    required this.name,
    required this.district,
    required this.address,
    required this.rent,
    required this.returnSlots,
    required this.capacity,
    required this.active,
    required this.updated,
  });
  final String id, name, district, address, updated;
  final int? rent, returnSlots, capacity;
  final bool active;
  factory BikeStation.fromJson(Map<String, dynamic> row) {
    int? number(dynamic value) {
      final n = value is int ? value : int.tryParse('$value');
      return n != null && n >= 0 ? n : null;
    }

    final name = (row['sna'] ?? '')
        .toString()
        .replaceFirst(RegExp(r'^YouBike2\.0_'), '')
        .trim();
    return BikeStation(
      id: (row['sno'] ?? '').toString().trim(),
      name: name,
      district: (row['sarea'] ?? '').toString().trim(),
      address: (row['ar'] ?? '').toString().trim(),
      rent: number(row['available_rent_bikes']),
      returnSlots: number(row['available_return_bikes']),
      capacity: number(row['Quantity'] ?? row['quantity']),
      active: (row['act'] ?? '').toString() == '1',
      updated: (row['mday'] ?? row['infoTime'] ?? '').toString().trim(),
    );
  }
}

List<BikeStation> parseBikeStations(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is! List || decoded.isEmpty) {
      throw const FormatException('空白或非陣列資料');
    }
    final rows = decoded
        .map(
          (row) => BikeStation.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .where((station) => station.id.isNotEmpty && station.name.isNotEmpty)
        .toList();
    if (rows.isEmpty) throw const FormatException('沒有有效場站');
    return rows;
  } on FormatException {
    rethrow;
  } catch (_) {
    throw const FormatException('場站資料格式錯誤');
  }
}

List<BikeStation> filterBikeStations(
  List<BikeStation> rows, {
  String query = '',
  String district = '',
  bool needBike = false,
  bool needSlot = false,
  bool savedOnly = false,
  Set<String> saved = const {},
}) {
  final q = query.trim().toLowerCase();
  return rows
      .where(
        (s) =>
            (district.isEmpty || s.district == district) &&
            (q.isEmpty ||
                '${s.name} ${s.address} ${s.district}'.toLowerCase().contains(
                  q,
                )) &&
            (!needBike || s.active && (s.rent ?? 0) > 0) &&
            (!needSlot || s.active && (s.returnSlots ?? 0) > 0) &&
            (!savedOnly || saved.contains(s.id)),
      )
      .toList();
}
