// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import 'bike_repository.dart';
import 'bike_station.dart';

class YouBikePage extends StatefulWidget {
  const YouBikePage({super.key, this.repository});
  final BikeRepository? repository;
  @override
  State<YouBikePage> createState() => _YouBikePageState();
}

class _YouBikePageState extends State<YouBikePage> {
  BikeRepository? repo;
  String query = '', district = '';
  bool needBike = false, needSlot = false, savedOnly = false, busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final r =
          widget.repository ??
          BikeRepository(await SharedPreferences.getInstance());
      await r.load();
      if (mounted) {
        setState(() {
          repo = r;
          error = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => error = '無法載入場站快照，請重試');
    }
  }

  Future<void> refresh() async {
    setState(() => busy = true);
    await repo!.refresh();
    if (mounted) setState(() => busy = false);
  }

  Future<void> save(BikeStation s) async {
    try {
      await repo!.toggleSaved(s.id);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('收藏儲存失敗')));
      }
    }
  }

  void details(BikeStation s) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('YouBike 場站詳細資料')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(s.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text('${s.district}・${s.address}'),
              const SizedBox(height: 12),
              Text(
                '可借車輛：${s.rent ?? '未知'}\n可還空位：${s.returnSlots ?? '未知'}\n總車柱：${s.capacity ?? '未知'}\n站點狀態：${s.active ? '啟用' : '停用或未知'}\n站點來源更新：${s.updated.isEmpty ? '未知' : s.updated}',
              ),
              const SizedBox(height: 12),
              const Text('車輛與空位隨時變動；資料更新時間不代表現場可借還。出發前請再次確認。'),
              FilledButton.icon(
                icon: const Icon(Icons.bookmark_outline),
                label: const Text('切換收藏'),
                onPressed: () async {
                  await save(s);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('複製地址'),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: s.address));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('地址已複製')));
                  }
                },
              ),
              const Divider(),
              const Text('資料提供：臺北市政府交通局・YouBike2.0臺北市公共自行車即時資訊\n資料授權：公開'),
              const SelectableText(bikeSourcePage),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = repo;
    final shown = r == null
        ? <BikeStation>[]
        : filterBikeStations(
            r.stations,
            query: query,
            district: district,
            needBike: needBike,
            needSlot: needSlot,
            savedOnly: savedOnly,
            saved: r.saved,
          );
    return Scaffold(
      appBar: AppBar(title: const Text('台北 YouBike 找車位')),
      body: r == null
          ? Center(
              child: error == null
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(error!),
                        TextButton(onPressed: load, child: const Text('重試')),
                      ],
                    ),
            )
          : Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '賽前準備原型・臺北市 YouBike2.0 場站',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Text('不使用定位與路線規劃；數量為來源更新時的數值，不保證現場即時可用。'),
                              const SizedBox(height: 8),
                              Text(
                                '${r.origin}・${r.stations.length} 個場站\n最近成功下載：${r.checkedAt?.toLocal().toString().split('.').first ?? '尚未下載'}',
                              ),
                              if (r.warning != null)
                                Text(
                                  r.warning!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              TextButton.icon(
                                onPressed: busy ? null : refresh,
                                icon: const Icon(Icons.refresh),
                                label: Text(busy ? '正在更新…' : '更新公開資料'),
                              ),
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: '搜尋場站、地址或行政區',
                                  prefixIcon: Icon(Icons.search),
                                ),
                                onChanged: (v) => setState(() => query = v),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                initialValue: district,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: '行政區',
                                ),
                                items:
                                    [
                                          '',
                                          ...({
                                            ...r.stations.map(
                                              (s) => s.district,
                                            ),
                                          }.toList()..sort()),
                                        ]
                                        .map(
                                          (d) => DropdownMenuItem(
                                            value: d,
                                            child: Text(
                                              d.isEmpty ? '全部行政區' : d,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (v) =>
                                    setState(() => district = v ?? ''),
                              ),
                              Wrap(
                                spacing: 8,
                                children: [
                                  FilterChip(
                                    label: const Text('只看有車'),
                                    selected: needBike,
                                    onSelected: (v) =>
                                        setState(() => needBike = v),
                                  ),
                                  FilterChip(
                                    label: const Text('只看有空位'),
                                    selected: needSlot,
                                    onSelected: (v) =>
                                        setState(() => needSlot = v),
                                  ),
                                  FilterChip(
                                    label: const Text('只看收藏'),
                                    selected: savedOnly,
                                    onSelected: (v) =>
                                        setState(() => savedOnly = v),
                                  ),
                                ],
                              ),
                              Text('符合條件：${shown.length} 個場站'),
                            ],
                          ),
                        ),
                      ),
                      if (shown.isEmpty)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('沒有符合條件的場站；可以放寬篩選。'),
                          ),
                        ),
                      SliverList.builder(
                        itemCount: shown.length,
                        itemBuilder: (context, index) {
                          final s = shown[index];
                          return ListTile(
                            title: Text(s.name),
                            subtitle: Text(
                              '${s.district}・可借 ${s.rent ?? '未知'}・可還 ${s.returnSlots ?? '未知'}${s.active ? '' : '・停用或未知'}',
                            ),
                            trailing: Icon(
                              r.saved.contains(s.id)
                                  ? Icons.bookmark
                                  : Icons.chevron_right,
                            ),
                            onTap: () => details(s),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
