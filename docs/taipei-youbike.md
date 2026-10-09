# 台北 YouBike 找車位（獨立市民常用服務）

與「台北安心行」並列於 TownPass 首頁，不取代原有公廁功能。獨立路由 `/taipei-youbike`。提供站名／地址／行政區搜尋、行政區、只看有車／有空位交集篩選、本機收藏、詳細資料與複製地址。沒有定位與路線規劃。

## 資料來源及限制
- 臺北市政府交通局「YouBike2.0臺北市公共自行車即時資訊」：https://data.taipei/dataset/detail?id=c6bc8aed-557d-41d5-bfb1-8da24f78f2fb
- 官方 JSON：https://tcgbusfs.blob.core.windows.net/dotapp/youbike/v2/youbike_immediate.json
- 授權：官方頁標示「公開」，免費。資料集標示每分鐘更新，**但 App 只有手動更新**；站點數字為來源更新時數字，不能保證現場可借還。無效或缺漏數量顯示未知；停用狀態不當作有車有位。
- 內建原始快照：`assets/open_data/taipei_youbike.json`，實際抓取 1815 站，SHA-256 `724d7f3b1d484a4255bb93f936c14a04c12a59ea6b52182cdfa966b159c0e9a5`。離線仍可查詢上次資料，但不宣稱即時。更新失敗不抹除快照／快取；成功下載時間與來源場站更新時間分開顯示。
- 測試假資料僅在 `test/`，不打包。

## 展示與驗證
`flutter pub get` → `flutter pub run build_runner build` → `flutter test` → `flutter analyze lib/page/youbike lib/page/home/home_view.dart lib/util/tp_route.dart lib/daily_services_demo.dart test/youbike*`。

網頁雙服務展示：`flutter run -t lib/daily_services_demo.dart -d chrome`，或 `flutter build web -t lib/daily_services_demo.dart --no-web-resources-cdn`。此入口避開原有 native 服務；**正式 Android 入口仍是 `lib/main.dart`**。此網頁不等於整個原生 App。網頁官方來源可能限制 CORS；內建快照仍可用。

新增程式採 AGPL-3.0-or-later；合併上游 GPLv3 須沿用既有授權通知。實機啟動與即時資料更新需另行驗證，別以編譯成功取代實機驗收。
