// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'facility.dart';
import 'facility_repository.dart';

class ComfortTools extends StatefulWidget {
  const ComfortTools({
    super.key,
    required this.repository,
    required this.openDetails,
  });
  final FacilityRepository repository;
  final void Function(Facility) openDetails;
  @override
  State<ComfortTools> createState() => _ComfortToolsState();
}

class _ComfortToolsState extends State<ComfortTools> {
  final note = TextEditingController();
  Future<void> storeNote(String value) async {
    try {
      if (!await widget.repository.preferences.setString(
        'companion.card',
        value,
      )) {
        throw Exception('save');
      }
      if (mounted) {
        setState(() {
          note.text = value;
          message = '個人備註已儲存在此裝置';
        });
      }
    } catch (_) {
      if (mounted) setState(() => message = '個人備註儲存失敗，請重試');
    }
  }

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  late List<String> reports;
  @override
  void initState() {
    super.initState();
    note.text = widget.repository.preferences.getString('companion.card') ?? '';
    reports =
        widget.repository.preferences.getStringList('companion.reports') ?? [];
  }

  Future<void> storeReports(List<String> next) async {
    try {
      if (!await widget.repository.preferences.setStringList(
        'companion.reports',
        next,
      )) {
        throw Exception('save');
      }
      if (mounted) {
        setState(() {
          reports = next;
          message = '本機紀錄已儲存；未分享、未查證';
        });
      }
    } catch (_) {
      if (mounted) setState(() => message = '紀錄儲存失敗，請重試');
    }
  }

  String rest = '廁所';
  String section = '安心出門';
  Future<void> official() async {
    try {
      if (await launchUrl(
        Uri.parse('https://www.travel.taipei/zh-tw/attraction'),
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => message = '無法開啟官方網站；需網路，可長按網址複製');
  }

  Widget officialLink() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('外部官方網站需網路；請自行核對開放時間與設施。'),
      const SelectableText('https://www.travel.taipei/zh-tw/attraction'),
      OutlinedButton(onPressed: official, child: const Text('查看臺北旅遊網官方景點')),
    ],
  );
  String preset = '經常找廁所', query = '';
  Facility? destination;
  final stops = <String>{};
  String? message;
  List<Facility> get candidates => widget.repository.facilities
      .where(
        (f) => f.matches(
          query: query,
          family: preset == '推嬰兒車',
          accessible: preset == '陪長輩',
        ),
      )
      .take(20)
      .toList();
  Future<void> saveDestination() async {
    try {
      final f = destination!;
      if (!widget.repository.saved.contains(f.id)) {
        await widget.repository.toggleSaved(f.id);
      }
      if (mounted) setState(() => message = '已收藏，可在我的安心卡離線查看');
    } catch (_) {
      if (mounted) setState(() => message = '收藏儲存失敗，請重試');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('安心生活工具')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '資料提供：臺北市政府環境保護局・臺北市公廁點位資訊\n政府資料開放授權條款第1版。來源基準2026-08-24；非即時，開放與可用狀態未知。',
        ),
        const SelectableText(sourcePage),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['安心出門', '雨天台北', '一鍵休息', '台北小探險', '設施有變', '我的安心卡']
              .map(
                (s) => OutlinedButton(
                  onPressed: () => setState(() {
                    section = s;
                    message = null;
                  }),
                  child: Text(s),
                ),
              )
              .toList(),
        ),
        if (section == '安心出門') ...[
          const Text('本次停靠只保留到工具頁關閉，需離線保留請收藏。不是路線或路程排序。'),
          ...widget.repository.facilities
              .where((f) => stops.contains(f.id))
              .map(
                (f) => ListTile(
                  title: Text('本次停靠：${f.name}'),
                  subtitle: Text(f.address),
                  trailing: IconButton(
                    tooltip: '移除本次停靠',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => stops.remove(f.id)),
                  ),
                ),
              ),
        ],
        if (section == '我的安心卡') ...[
          const Text('離線可顯示的繁體中文求助短句；點選放大給對方看。不需要提供姓名或健康資料。'),
          ...[
            '請問最近的廁所在哪裡？',
            '我需要坐下休息，請問哪裡可以坐？',
            '請問哪裡有飲用水？',
            '請問有不必走樓梯的入口嗎？',
          ].map(
            (phrase) => OutlinedButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  scrollable: true,
                  content: SelectableText(
                    phrase,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('關閉'),
                    ),
                  ],
                ),
              ),
              child: Text(phrase),
            ),
          ),
          const Text('我的安心停靠點（收藏，不保證可用）'),
          if (widget.repository.saved.isEmpty)
            const Text('尚未收藏停靠點；可在安心出門選擇後收藏。'),
          ...widget.repository.facilities
              .where((f) => widget.repository.saved.contains(f.id))
              .map(
                (f) => ListTile(
                  title: Text(f.name),
                  subtitle: Text(f.address),
                  onTap: () => widget.openDetails(f),
                ),
              ),
          const Text('個人備註完全自願，只在此裝置儲存，未加密、無雲端同步；請勿填入敏感健康或聯絡資料。可隨時清除，清除不影響收藏。'),
          TextField(
            controller: note,
            maxLength: 300,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: '自願個人備註'),
          ),
          FilledButton(
            onPressed: () => storeNote(note.text),
            child: const Text('儲存在此裝置'),
          ),
          TextButton(
            onPressed: () => storeNote(''),
            child: const Text('清除個人備註'),
          ),
        ],
        if (section == '雨天台北') ...[
          const Text('室內與遮蔽資料未提供；不從公廁名稱或類別猜測室內場所。此階段沒有可驗證的雨天匹配結果。'),
          officialLink(),
        ],
        if (section == '一鍵休息') ...[
          Wrap(
            spacing: 8,
            children: ['廁所', '座椅', '飲水', '室內']
                .map(
                  (n) => ChoiceChip(
                    label: Text(n),
                    selected: rest == n,
                    onSelected: (_) => setState(() => rest = n),
                  ),
                )
                .toList(),
          ),
          if (rest != '廁所') ...[
            Text('$rest：資料未提供；沒有可驗證匹配。未知不等於沒有，請向管理單位確認。'),
            officialLink(),
          ],
        ],
        if (section == '台北小探險') ...[
          const Text(
            '30分鐘是自訂預算，不是路程估算或可達保證。第一階段只從公廁資料選目的地／停靠點；不表示該地點適合遊覽或輕鬆通行。',
          ),
          officialLink(),
          ...widget.repository.facilities
              .where((f) => stops.contains(f.id))
              .map(
                (f) => ListTile(
                  title: Text('本次停靠：${f.name}'),
                  subtitle: Text(f.address),
                  trailing: IconButton(
                    tooltip: '移除本次停靠',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => stops.remove(f.id)),
                  ),
                ),
              ),
        ],
        if (section == '設施有變') ...[
          const Text('未查證・僅此裝置。這是個人觀察紀錄，不是社群分享；沒有上傳、審核或通知管理單位，不會改寫官方資料或排序。'),
          ...reports.map(
            (r) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r),
                TextButton(
                  onPressed: () => storeReports([...reports]..remove(r)),
                  child: const Text('刪除此紀錄'),
                ),
              ],
            ),
          ),
        ],
        if (section == '安心出門' ||
            section == '設施有變' ||
            section == '台北小探險' ||
            (section == '一鍵休息' && rest == '廁所')) ...[
          const Text(
            '需求預設',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Text('推嬰兒車僅篩選親子廁座有登載；陪長輩僅篩選無障礙廁座有登載。經常找廁所使用全部公廁資料。這不是通行能力判定。'),
          Wrap(
            spacing: 8,
            children: ['推嬰兒車', '陪長輩', '經常找廁所']
                .map(
                  (p) => ChoiceChip(
                    label: Text(p),
                    selected: preset == p,
                    onSelected: (_) => setState(() {
                      preset = p;
                      destination = null;
                    }),
                  ),
                )
                .toList(),
          ),
          TextField(
            decoration: const InputDecoration(labelText: '搜尋目的地或停靠點（公廁資料）'),
            onChanged: (v) => setState(() => query = v),
          ),
          const Text('每次最多顯示20筆來源地點，請輸入名稱、地址或行政區縮小範圍；不是距離或推薦排名。'),
          if (candidates.isEmpty) const Text('沒有符合登載條件的地點；未知資料未列入。'),
          ...candidates.map(
            (f) => ListTile(
              title: Text(f.name),
              subtitle: Text('${f.district}・${f.address}'),
              onTap: () => setState(() => destination = f),
            ),
          ),
          if (destination != null) ...[
            Text('目的地：${destination!.name}\n${destination!.address}'),
            const Text('開放時間、現場可用狀態、座椅、飲水、室內與遮蔽：資料不足。不保證無障礙路線；出發前請確認入口與沿途狀況。'),
            if (section == '設施有變')
              FilledButton(
                onPressed: () => storeReports([
                  ...reports,
                  '${destination!.name}\n${destination!.address}\n暫停使用・未查證・僅此裝置\n本機記錄時間：${DateTime.now().toIso8601String()}（不是官方更新時間）',
                ]),
                child: const Text('記下暫停使用'),
              ),
            FilledButton(
              onPressed: () => setState(() => stops.add(destination!.id)),
              child: const Text('加入本次停靠'),
            ),
            FilledButton(
              onPressed: saveDestination,
              child: const Text('收藏為安心停靠點'),
            ),
            OutlinedButton(
              onPressed: () => widget.openDetails(destination!),
              child: const Text('查看目的地資料'),
            ),
          ],
        ],
        if (message != null) Semantics(liveRegion: true, child: Text(message!)),
      ],
    ),
  );
}
