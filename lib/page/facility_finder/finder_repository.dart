// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:shared_preferences/shared_preferences.dart';

import '../companion/facility_repository.dart';
import '../youbike/bike_repository.dart';
import 'place.dart';

class FinderRepository {
  FinderRepository({required this.toilets, required this.bikes});
  final FacilityRepository toilets;
  final BikeRepository bikes;
  final Set<FacilityKind> loaded = {};
  final Map<FacilityKind, String> errors = {};
  Future<void> _saveQueue = Future<void>.value();

  static Future<FinderRepository> create() async {
    final preferences = await SharedPreferences.getInstance();
    return FinderRepository(
      toilets: FacilityRepository(preferences),
      bikes: BikeRepository(preferences),
    );
  }

  Future<void> load() => Future.wait([
    _load(FacilityKind.toilet, toilets.load),
    _load(FacilityKind.youbike, bikes.load),
  ]);

  Future<void> _load(FacilityKind kind, Future<void> Function() load) async {
    try {
      await load();
      loaded.add(kind);
      errors.remove(kind);
    } catch (_) {
      errors[kind] = '${kind.label}資料載入失敗，請重試';
    }
  }

  Future<void> refresh() async {
    await Future.wait([toilets.refresh(), bikes.refresh()]);
    if (toilets.warning == null) {
      loaded.add(FacilityKind.toilet);
      errors.remove(FacilityKind.toilet);
    }
    if (bikes.warning == null) {
      loaded.add(FacilityKind.youbike);
      errors.remove(FacilityKind.youbike);
    }
  }

  List<FacilityPlace> get places {
    final unique = <String, FacilityPlace>{};
    final rows = [
      if (loaded.contains(FacilityKind.toilet))
        ...toilets.facilities.map(FacilityPlace.toilet),
      if (loaded.contains(FacilityKind.youbike))
        ...bikes.stations.map(FacilityPlace.youbike),
    ];
    // Source snapshots can repeat an existing favourite identity. Keep the first
    // record, so result counts, details and favourite actions refer to one place.
    for (final place in rows) {
      unique.putIfAbsent(place.id, () => place);
    }
    return unique.values.toList();
  }

  Set<String> get saved => {
    ...toilets.saved.map((id) => 'toilet:$id'),
    ...bikes.saved.map((id) => 'youbike:$id'),
  };

  Future<void> toggleSaved(FacilityPlace place) {
    // Each source writes its whole saved set. Serialize rapid taps so one
    // pending write cannot discard a different place selected meanwhile.
    final result = _saveQueue.then(
      (_) => place.kind == FacilityKind.toilet
          ? toilets.toggleSaved(place.sourceId)
          : bikes.toggleSaved(place.sourceId),
    );
    _saveQueue = result.catchError((Object _) {});
    return result;
  }
}
