# 設施快找：第一階段可操作功能

依 2026/10/18 會議提出的「城市生活便利＋智慧路線推薦＋緊急安全救援」方向，這個 PR 先提供設施快找的完整操作流程。其餘資料與官方介接仍須由團隊確認。本文件不代表五人分工或全部開發範圍已定案。

## 啟動與操作

```sh
flutter pub get
dart run build_runner build
flutter run -t lib/daily_services_demo.dart -d chrome
```

展示首頁選擇「設施快找」。完整原生 App 的首頁亦提供獨立入口，路由 `/facility-finder`；原公廁與 YouBike 頁面保留。

1. 輸入名稱、地址、行政區或 YouBike 關鍵字；多個空白分隔的關鍵字須全部符合。
2. 選擇全部、公廁或 YouBike，搭配行政區及「無障礙廁所」「親子廁所」交集篩選。廁所需求排除未登載、未知、零座及 YouBike。
3. 收藏設施後開啟「只看收藏」。收藏沿用原公廁／YouBike 的本機儲存，兩個原有頁面重新開啟時也可讀取。
4. 按「尋找附近設施」才會要求定位並取得一次位置，依直線距離排序，可限制 500／1,000／3,000 公尺；移動後須手動重新定位。未定位仍可查詢，拒絕／封鎖／逾時會顯示可恢復提示。
5. 缺少有效座標的結果距離顯示未知、排在後面；選擇半徑時不列入。
6. 點進設施查看詳細、來源時間、官方來源及地址。點「開啟 Google 地圖步行路線」交給外部地圖；缺座標時採臺北市、行政區、地址與名稱判讀，須確認目的地。開啟失敗可複製地址自行搜尋。
7. 展開「資料來源與更新狀態」查看來源狀態，按「手動更新兩項資料」。更新失敗保留既有資料；單一來源載入失敗不阻擋另一來源，並可重試。

## 資料與限制

- 只使用既有真實公廁及 YouBike 快照／快取，不新增模擬正式資料。來源、授權與雜湊沿用 [公廁文件](taipei-companion.md)、[YouBike 文件](taipei-youbike.md)。
- 同一來源的重複收藏 ID 保留第一筆紀錄；結果 ID 加上 `toilet:` 或 `youbike:` 以避免跨來源衝突。原始資料與原頁面未重寫。
- 公廁來源時間基準保留 2026-08-24；YouBike 顯示各站來源更新時間，數量非保證即時。下載時間不充作來源時間。
- 距離為座標計算的球面直線估算，非步行距離或通行承諾。定位精度由裝置決定；本頁不儲存位置、不持續追蹤、不把使用者座標放入地圖 URL。
- 網頁定位需要 HTTPS 或 localhost 及瀏覽器授權。Android 補上概略定位宣告；iOS 使用中定位說明改為可選的附近搜尋用途。實體裝置權限流程仍需驗收。
- 外部地圖使用 [Google Maps URLs](https://developers.google.com/maps/documentation/urls/get-started) 的 `api=1`、`destination`、`travelmode=walking`，不需要地圖 API key。外部地圖自身的定位及資料處理依其服務設定。
- 一般步行路線不代表陰涼、無階差或無障礙路線；本版沒有遮蔭評分、AED／飲水設備資料，也沒有警方或附近救援人員通報服務。

## 模組介面

| 檔案 | 責任與介面 |
| --- | --- |
| `lib/page/facility_finder/place.dart` | `FacilityPlace` 對既有資料做轉接；`GeoPoint` 驗證有限座標與計算公尺距離；`findFacilities` 接收關鍵字、行政區、類型、需求、收藏、位置與範圍，輸出含可選距離的結果 |
| `lib/page/facility_finder/finder_repository.dart` | 組合兩項 repository，各自載入／快取／更新；保留各來源錯誤、去重及共用收藏；單一來源失敗可繼續查詢 |
| `lib/page/facility_finder/finder_location.dart` | 使用既有 geolocator，只有主動呼叫才要求權限，取得單次位置；不啟動背景或串流定位 |
| `lib/page/facility_finder/finder_page.dart` | 搜尋、篩選、資料狀態、附近操作、詳細資料、來源與外部地圖；repository、定位及 URL 開啟可注入以驗證行為 |

飲水設備、AED 等新來源須先確認官方資料、授權、更新頻率、識別碼及座標品質，再擴充 `FacilityKind` 與來源轉接器。陰涼路線及緊急通知的資料契約、授權與負責人留待下次會議決定。

## 驗證

```sh
flutter test
flutter analyze lib/page/facility_finder lib/page/youbike/bike_station.dart lib/daily_services_demo.dart lib/page/home/home_view.dart lib/util/tp_route.dart test/finder_test.dart test/finder_widget_test.dart test/finder_location_test.dart test/finder_fixtures.dart test/youbike_entry_test.dart
flutter build web -t lib/daily_services_demo.dart --no-web-resources-cdn
```

測試涵蓋真實快照載入、重複紀錄、需求交集、距離與未知座標、來源部分失敗、離線保留、跨頁收藏、定位權限、頁面離開後的非同步完成、外部 URL 與失敗提示，以及窄螢幕兩倍字體。測試定位與地圖開啟使用替身；通過不代表已在實體手機或外部地圖完成導航驗收。

新增程式、測試與本文件採 AGPL-3.0-or-later，保留既有授權與資料歸屬。
