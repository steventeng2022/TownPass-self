// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'facility.dart';
import 'facility_repository.dart';

class CompanionPage extends StatefulWidget {
  const CompanionPage({super.key, this.repository});
  final FacilityRepository? repository;
  @override
  State<CompanionPage> createState() => _CompanionPageState();
}

class _CompanionPageState extends State<CompanionPage> {
  FacilityRepository? repo;
  String query = '', district = '';
  bool accessible = false,
      family = false,
      care = false,
      savedOnly = false,
      busy = false;
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
          FacilityRepository(await SharedPreferences.getInstance());
      await r.load();
      if (mounted) {
        setState(() {
          repo = r;
          error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          error = '無法載入公開資料，請重試';
        });
      }
    }
  }

  Future<void> refresh() async {
    setState(() {
      busy = true;
    });
    await repo!.refresh();
    if (mounted) {
      setState(() {
        busy = false;
      });
    }
  }

  Future<void> save(Facility f) async {
    try {
      await repo!.toggleSaved(f.id);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('收藏儲存失敗，請重試')));
      }
    }
  }

  Future<void> openSource(BuildContext context) async {
    try {
      if (await launchUrl(
        Uri.parse(sourcePage),
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } catch (_) {}
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('無法開啟來源，可長按網址複製')));
    }
  }

  void details(Facility f) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => StatefulBuilder(
          builder: (context, update) => Scaffold(
            appBar: AppBar(title: const Text('地點詳細資料')),
            body: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(f.name, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text('${f.district}・${f.value('公廁類別')}\n${f.address}'),
                const SizedBox(height: 12),
                Text(
                  '無障礙廁座數：${f.accessibleSeats ?? '未知'}\n親子廁座數：${f.familySeats ?? '未知'}\n照護床位置：${known(f.value('照護床位置'))}\n污物盆位置：${known(f.value('污物盆位置'))}\n其他設施：${known(f.value('其他設施'))}\n管理單位：${known(f.value('管理單位'))}\n開放時間：未知\n即時可用狀態：未知',
                ),
                const SizedBox(height: 16),
                const Text('座數僅為來源登載資訊，不保證現場可用、無階差入口或沿途無障礙。出發前請向管理單位確認。'),
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: Icon(
                    repo!.saved.contains(f.id)
                        ? Icons.bookmark
                        : Icons.bookmark_outline,
                  ),
                  label: Text(repo!.saved.contains(f.id) ? '取消收藏' : '收藏地點'),
                  onPressed: () async {
                    await save(f);
                    if (context.mounted) update(() {});
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.copy),
                  label: const Text('複製地址'),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: f.address));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('地址已複製')));
                    }
                  },
                ),
                const Divider(),
                const Text(
                  '資料提供：臺北市政府環境保護局\n資料集：臺北市公廁點位資訊\n政府資料開放授權條款第1版\n內建來源更新：2026-08-24；下載不代表來源更新。',
                ),
                SelectableText(sourcePage),
                TextButton(
                  onPressed: () => openSource(context),
                  child: const Text('查看官方資料來源'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String known(String v) => v.isEmpty ? '未知' : v;
  @override
  Widget build(BuildContext context) {
    final r = repo;
    return Scaffold(
      appBar: AppBar(title: const Text('台北安心行')),
      body: r == null
          ? Center(
              child: error == null
                  ? const CircularProgressIndicator(semanticsLabel: '正在載入公開資料')
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
                                '賽前準備原型・公共廁所需求查詢',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Text('公開資料非即時；未知不等於沒有，設施不等於可通行路線。'),
                              const SizedBox(height: 8),
                              Text(
                                '${r.origin}・${r.facilities.length} 個地點\n來源更新基準：2026-08-24${r.stale ? '・超過30日，請確認' : ''}\n最近成功下載：${r.checkedAt?.toLocal().toString().split('.').first ?? '尚未下載'}',
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
                                  labelText: '搜尋名稱、地址或行政區',
                                  prefixIcon: Icon(Icons.search),
                                ),
                                onChanged: (v) => setState(() {
                                  query = v;
                                }),
                              ),
                              const SizedBox(height: 8),
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
                                            ...r.facilities.map(
                                              (f) => f.district,
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
                                onChanged: (v) => setState(() {
                                  district = v ?? '';
                                }),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  FilterChip(
                                    label: const Text('無障礙廁所'),
                                    selected: accessible,
                                    onSelected: (v) => setState(() {
                                      accessible = v;
                                    }),
                                  ),
                                  FilterChip(
                                    label: const Text('親子廁所'),
                                    selected: family,
                                    onSelected: (v) => setState(() {
                                      family = v;
                                    }),
                                  ),
                                  FilterChip(
                                    label: const Text('照護床有登載'),
                                    selected: care,
                                    onSelected: (v) => setState(() {
                                      care = v;
                                    }),
                                  ),
                                  FilterChip(
                                    label: const Text('只看收藏'),
                                    selected: savedOnly,
                                    onSelected: (v) => setState(() {
                                      savedOnly = v;
                                    }),
                                  ),
                                ],
                              ),
                              const Text('多項需求採同時符合；缺漏或未知不列入需求篩選。'),
                            ],
                          ),
                        ),
                      ),
                      ...results(r),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> results(FacilityRepository r) {
    final matches = r.facilities
        .where(
          (f) =>
              f.matches(
                query: query,
                district: district,
                accessible: accessible,
                family: family,
                care: care,
              ) &&
              (!savedOnly || r.saved.contains(f.id)),
        )
        .toList();
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('符合 ${matches.length} 個地點'),
        ),
      ),
      if (matches.isEmpty)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('沒有符合的地點，請調整條件；未知設施未納入篩選。'),
          ),
        ),
      SliverList.builder(
        itemCount: matches.length,
        itemBuilder: (context, i) {
          final f = matches[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              title: Text(f.name),
              subtitle: Text(
                '${f.district}・${f.address}\n無障礙：${f.accessibleSeats ?? '未知'}座・親子：${f.familySeats ?? '未知'}座',
              ),
              isThreeLine: false,
              onTap: () => details(f),
              trailing: IconButton(
                tooltip: r.saved.contains(f.id) ? '取消收藏' : '收藏地點',
                onPressed: () => save(f),
                icon: Icon(
                  r.saved.contains(f.id)
                      ? Icons.bookmark
                      : Icons.bookmark_outline,
                ),
              ),
            ),
          );
        },
      ),
    ];
  }
}
