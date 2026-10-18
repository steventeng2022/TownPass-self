// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:math' as math;

import '../companion/facility.dart';
import '../companion/facility_repository.dart';
import '../youbike/bike_repository.dart';
import '../youbike/bike_station.dart';

enum FacilityKind {
  toilet('公廁'),
  youbike('YouBike');

  const FacilityKind(this.label);
  final String label;
}

class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);
  final double latitude, longitude;

  static GeoPoint? parse(Object? latitude, Object? longitude) {
    final lat = double.tryParse('$latitude');
    final lon = double.tryParse('$longitude');
    if (lat == null ||
        lon == null ||
        !lat.isFinite ||
        !lon.isFinite ||
        lat.abs() > 90 ||
        lon.abs() > 180) {
      return null;
    }
    return GeoPoint(lat, lon);
  }

  double distanceTo(GeoPoint other) {
    double radians(double degrees) => degrees * math.pi / 180;
    final dLat = radians(other.latitude - latitude);
    final dLon = radians(other.longitude - longitude);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(radians(latitude)) *
            math.cos(radians(other.latitude)) *
            math.pow(math.sin(dLon / 2), 2);
    return 6371000 * 2 * math.asin(math.sqrt(a.clamp(0, 1)));
  }
}

// Adapters keep the existing source models, IDs and favourite stores intact.
class FacilityPlace {
  const FacilityPlace.toilet(Facility facility)
    : toilet = facility,
      bike = null;
  const FacilityPlace.youbike(BikeStation station)
    : bike = station,
      toilet = null;
  final Facility? toilet;
  final BikeStation? bike;
  FacilityKind get kind =>
      toilet != null ? FacilityKind.toilet : FacilityKind.youbike;
  String get sourceId => toilet?.id ?? bike!.id;
  String get id => '${kind.name}:$sourceId';
  String get name => toilet?.name ?? bike!.name;
  String get district => toilet?.district ?? bike!.district;
  String get address => toilet?.address ?? bike!.address;
  GeoPoint? get point => toilet != null
      ? GeoPoint.parse(toilet!.value('緯度'), toilet!.value('經度'))
      : GeoPoint.parse(bike!.latitude, bike!.longitude);
  String get sourceUrl => toilet != null ? sourcePage : bikeSourcePage;
  String get summary => toilet != null
      ? '無障礙 ${toilet!.accessibleSeats ?? '未知'} 座・親子 ${toilet!.familySeats ?? '未知'} 座'
      : '可借 ${bike!.rent ?? '未知'}・可還 ${bike!.returnSlots ?? '未知'}・${bike!.active ? '啟用' : '停用或未知'}';

  Uri get walkingDirections => Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': point == null
        ? '臺北市 $district $address $name'
        : '${point!.latitude},${point!.longitude}',
    'travelmode': 'walking',
  });
}

class FacilityMatch {
  const FacilityMatch(this.place, this.distanceMeters);
  final FacilityPlace place;
  final double? distanceMeters;
}

List<FacilityMatch> findFacilities(
  Iterable<FacilityPlace> places, {
  String query = '',
  String district = '',
  FacilityKind? kind,
  bool accessible = false,
  bool family = false,
  bool savedOnly = false,
  Set<String> saved = const {},
  GeoPoint? origin,
  double? radiusMeters,
}) {
  final words = query.trim().toLowerCase().split(RegExp(r'\s+'));
  final matches = <FacilityMatch>[];
  for (final place in places) {
    final text =
        '${place.name} ${place.address} ${place.district} ${place.kind.label}'
            .toLowerCase();
    if ((kind != null && place.kind != kind) ||
        (district.isNotEmpty && place.district != district) ||
        !words.every(text.contains) ||
        (accessible && (place.toilet?.accessibleSeats ?? 0) <= 0) ||
        (family && (place.toilet?.familySeats ?? 0) <= 0) ||
        (savedOnly && !saved.contains(place.id))) {
      continue;
    }
    final point = place.point;
    final distance = origin != null && point != null
        ? origin.distanceTo(point)
        : null;
    // A radius cannot silently become an unbounded search without a location.
    if (radiusMeters != null && (distance == null || distance > radiusMeters)) {
      continue;
    }
    matches.add(FacilityMatch(place, distance));
  }
  matches.sort((a, b) {
    if (origin != null) {
      final distance = (a.distanceMeters ?? double.infinity).compareTo(
        b.distanceMeters ?? double.infinity,
      );
      if (distance != 0) return distance;
    }
    final name = a.place.name.compareTo(b.place.name);
    return name != 0 ? name : a.place.id.compareTo(b.place.id);
  });
  return matches;
}
