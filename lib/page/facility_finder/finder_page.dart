// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'finder_location.dart';
import 'finder_repository.dart';
import 'place.dart';

class FinderPage extends StatefulWidget {
  const FinderPage({super.key, this.repository, this.locate, this.openUrl});
  final FinderRepository? repository;
  final Future<GeoPoint> Function()? locate;
  final Future<bool> Function(Uri)? openUrl;

  @override
  State<FinderPage> createState() => _FinderPageState();
}

class _FinderPageState extends State<FinderPage> {
  final search = TextEditingController();
  FinderRepository? repository;
  FacilityKind? kind;
  String district = '';
  bool accessible = false, family = false, savedOnly = false;
  bool loading = true, refreshing = false, locating = false;
  GeoPoint? origin;
  double? radius;
  String? error, locationError;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final next =
          repository ?? widget.repository ?? await FinderRepository.create();
      await next.load();
      if (mounted) setState(() => repository = next);
    } catch (_) {
      if (mounted) setState(() => error = '無法載入設施資料，請重試。');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> refresh() async {
    setState(() => refreshing = true);
    try {
      await repository!.refresh();
    } finally {
      if (mounted) setState(() => refreshing = false);
    }
  }

  Future<void> locate() async {
    setState(() {
      locating = true;
      locationError = null;
    });
    try {
      final point = await (widget.locate ?? locateForFinder)().timeout(
        const Duration(seconds: 25),
      );
      if (mounted) setState(() => origin = point);
    } on StateError catch (e) {
      if (mounted) setState(() => locationError = e.message.toString());
    } on TimeoutException {
      if (mounted) setState(() => locationError = '定位逾時，請重試；仍可手動搜尋。');
    } catch (_) {
      if (mounted) {
        setState(
          () => locationError = '無法定位；請確認權限與 HTTPS／localhost 環境，或使用手動搜尋。',
        );
      }
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  Future<void> save(FacilityPlace place) async {
    try {
      await repository!.toggleSaved(place);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('收藏儲存失敗，請重試。')));
      }
    }
  }

  Future<void> open(BuildContext context, Uri uri) async {
    try {
      final success =
          await (widget.openUrl?.call(uri) ??
              launchUrl(uri, mode: LaunchMode.externalApplication));
      if (success) return;
    } catch (_) {}
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('無法開啟外部頁面；可複製地址後自行搜尋。')));
    }
  }

  void reset() => setState(() {
    search.clear();
    kind = null;
    district = '';
    accessible = family = savedOnly = false;
    radius = null;
  });

  @override
  Widget build(BuildContext context) {
    final repo = repository;
    final matches = repo == null
        ? <FacilityMatch>[]
        : findFacilities(
            repo.places,
            query: search.text,
            district: district,
            kind: kind,
            accessible: accessible,
            family: family,
            savedOnly: savedOnly,
            saved: repo.saved,
            origin: origin,
            radiusMeters: radius,
          );
    final districts = <String>{
      if (district.isNotEmpty) district,
      ...?repo?.places
          .map((place) => place.district)
          .where((value) => value.isNotEmpty),
    }.toList()..sort();
    return Scaffold(
      appBar: AppBar(title: const Text('設施快找')),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(semanticsLabel: '正在載入設施'),
            )
          : repo == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error ?? '無法載入設施資料'),
                  TextButton(onPressed: load, child: const Text('重試')),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '找一處，讓出門更方便',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const Text('公廁・無障礙與親子廁所・YouBike\n公開資料非即時；設施登載不代表現場可用。'),
                        const SizedBox(height: 16),
                        TextField(
                          controller: search,
                          decoration: const InputDecoration(
                            labelText: '搜尋設施名稱、地址或行政區',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('全部設施'),
                              selected: kind == null,
                              onSelected: (_) => setState(() => kind = null),
                            ),
                            for (final value in FacilityKind.values)
                              ChoiceChip(
                                label: Text(value.label),
                                selected: kind == value,
                                onSelected: (_) => setState(() => kind = value),
                              ),
                          ],
                        ),
                        DropdownButtonFormField<String>(
                          key: ValueKey(district),
                          initialValue: district,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: '行政區'),
                          items: ['', ...districts]
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value.isEmpty ? '全部行政區' : value),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => district = value ?? ''),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilterChip(
                              label: const Text('無障礙廁所'),
                              selected: accessible,
                              onSelected: (value) =>
                                  setState(() => accessible = value),
                            ),
                            FilterChip(
                              label: const Text('親子廁所'),
                              selected: family,
                              onSelected: (value) =>
                                  setState(() => family = value),
                            ),
                            FilterChip(
                              label: const Text('只看收藏'),
                              selected: savedOnly,
                              onSelected: (value) =>
                                  setState(() => savedOnly = value),
                            ),
                          ],
                        ),
                        const Text('需求採交集；廁所需求只會列出符合登載的公廁。'),
                        const Divider(height: 24),
                        const Text('定位只在按下按鈕後取得一次，僅於本頁計算直線距離，不儲存位置。'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: locating ? null : locate,
                              icon: const Icon(Icons.near_me_outlined),
                              label: Text(
                                locating
                                    ? '正在定位…'
                                    : origin == null
                                    ? '尋找附近設施'
                                    : '重新取得位置',
                              ),
                            ),
                            if (origin != null)
                              TextButton(
                                onPressed: locating
                                    ? null
                                    : () => setState(() {
                                        origin = null;
                                        radius = null;
                                        locationError = null;
                                      }),
                                child: const Text('清除位置'),
                              ),
                          ],
                        ),
                        if (locationError != null)
                          Text(
                            locationError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        if (origin != null) ...[
                          const Text('依本次取得位置的直線距離排序，非步行距離；移動後請重新定位。'),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final meters in <double?>[
                                null,
                                500,
                                1000,
                                3000,
                              ])
                                ChoiceChip(
                                  label: Text(
                                    meters == null
                                        ? '不限距離'
                                        : '${meters.toInt()} 公尺內',
                                  ),
                                  selected: radius == meters,
                                  onSelected: (_) =>
                                      setState(() => radius = meters),
                                ),
                            ],
                          ),
                          const Text('未提供有效座標的設施排在最後，設定距離範圍時不列入。'),
                        ],
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: const Text('資料來源與更新狀態'),
                          children: [
                            ListTile(
                              title: const Text('公廁｜臺北市政府環境保護局'),
                              subtitle: Text(
                                '${repo.toilets.origin}・${repo.toilets.facilities.length} 處\n來源更新基準：2026-08-24\n${repo.toilets.warning ?? ''}',
                              ),
                            ),
                            ListTile(
                              title: const Text('YouBike｜臺北市政府交通局'),
                              subtitle: Text(
                                '${repo.bikes.origin}・${repo.bikes.stations.length} 站\n各站來源時間請見詳細資料；數量不保證即時。\n${repo.bikes.warning ?? ''}',
                              ),
                            ),
                            TextButton.icon(
                              onPressed: refreshing ? null : refresh,
                              icon: const Icon(Icons.refresh),
                              label: Text(refreshing ? '正在更新…' : '手動更新兩項資料'),
                            ),
                          ],
                        ),
                        for (final message in repo.errors.values)
                          Text(
                            message,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        if (repo.errors.isNotEmpty)
                          TextButton(
                            onPressed: refreshing ? null : load,
                            child: const Text('重試載入資料'),
                          ),
                        Wrap(
                          spacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '符合 ${matches.length} 處設施',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            TextButton(
                              onPressed: reset,
                              child: const Text('清除篩選'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (matches.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('沒有符合的設施，請調整關鍵字、需求或距離範圍。'),
                    ),
                  ),
                SliverList.builder(
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final match = matches[index];
                    final place = match.place;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: Icon(
                          place.kind == FacilityKind.toilet
                              ? Icons.wc
                              : Icons.pedal_bike,
                        ),
                        title: Text(place.name),
                        subtitle: Text(
                          '${place.kind.label}・${place.district}\n${place.address}\n${place.summary}'
                          '${origin == null ? '' : '\n${distanceLabel(match.distanceMeters)}'}',
                        ),
                        trailing: IconButton(
                          tooltip: repo.saved.contains(place.id)
                              ? '取消收藏'
                              : '收藏設施',
                          icon: Icon(
                            repo.saved.contains(place.id)
                                ? Icons.bookmark
                                : Icons.bookmark_outline,
                          ),
                          onPressed: () => save(place),
                        ),
                        onTap: () => details(match),
                      ),
                    );
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
    );
  }

  String distanceLabel(double? meters) => meters == null
      ? '距離未知：來源缺少有效座標'
      : meters < 1000
      ? '直線距離約 ${meters.round()} 公尺'
      : '直線距離約 ${(meters / 1000).toStringAsFixed(1)} 公里';

  void details(FacilityMatch match) {
    final place = match.place;
    final toilet = place.toilet;
    final bike = place.bike;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => StatefulBuilder(
          builder: (context, update) => Scaffold(
            appBar: AppBar(title: const Text('設施詳細資料')),
            body: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  place.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  '${place.kind.label}・${place.district}\n${place.address}\n${place.summary}',
                ),
                if (origin != null) Text(distanceLabel(match.distanceMeters)),
                const SizedBox(height: 16),
                if (toilet != null)
                  Text(
                    '照護床位置：${toilet.value('照護床位置').isEmpty ? '未知' : toilet.value('照護床位置')}\n'
                    '管理單位：${toilet.value('管理單位').isEmpty ? '未知' : toilet.value('管理單位')}\n'
                    '開放時間與現場可用狀態：未知\n'
                    '資料提供：臺北市政府環境保護局\n政府資料開放授權條款第1版\n來源更新基準：2026-08-24',
                  ),
                if (bike != null)
                  Text(
                    '總車柱：${bike.capacity ?? '未知'}\n站點來源更新：${bike.updated.isEmpty ? '未知' : bike.updated}\n'
                    '資料提供：臺北市政府交通局\n資料授權：公開',
                  ),
                const SizedBox(height: 16),
                const Text('設施與車位資訊不保證現場可用。外部地圖提供一般步行路線，不保證陰涼、無階差或無障礙通行。'),
                if (place.point == null)
                  const Text('缺少有效座標，外部地圖將依地址與名稱判讀目的地，請確認位置。'),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => open(context, place.walkingDirections),
                  icon: const Icon(Icons.directions_walk),
                  label: const Text('開啟 Google 地圖步行路線'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await save(place);
                    if (context.mounted) update(() {});
                  },
                  icon: Icon(
                    repository!.saved.contains(place.id)
                        ? Icons.bookmark
                        : Icons.bookmark_outline,
                  ),
                  label: Text(
                    repository!.saved.contains(place.id) ? '取消收藏' : '收藏設施',
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: place.address));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('地址已複製')));
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('複製地址'),
                ),
                const Divider(),
                SelectableText(place.sourceUrl),
                TextButton(
                  onPressed: () => open(context, Uri.parse(place.sourceUrl)),
                  child: const Text('查看官方資料來源'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
