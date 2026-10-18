# TownPass-self｜台北安心行

本專案以臺北市政府開源的 [TownPass](https://github.com/taipei-doit/TownPass) 為基礎，新增「**台北安心行**」公共廁所需求查詢原型，協助使用者依行政區、無障礙廁所、親子廁所與照護床登載資訊尋找地點，並將常用地點收藏在本機。

目前定位為**賽前準備原型**，準備參與的活動頁面為 [Codefest Taipei 2026 秋季活動](https://codefest.taipei/2026-fall/)；正式參賽內容與資格仍須依主辦公告核對。完整功能、資料歸屬與既有驗證紀錄見 [台北安心行詳細文件](docs/taipei-companion.md)。

> 想先看功能：完成下方「快速開始」，使用 `lib/companion_demo.dart` 啟動網頁展示。
> 公開資料並非即時資訊；廁所設施有登載，不代表現場可用、入口無階差或沿途可通行。

## 目錄

- [專案來源與範圍](#專案來源與範圍)
- [目前可以做什麼](#目前可以做什麼)
- [快速開始](#快速開始)
- [操作與展示步驟](#操作與展示步驟)
- [完整 App 與建置](#完整-app-與建置)
- [資料來源與離線行為](#資料來源與離線行為)
- [測試與目前限制](#測試與目前限制)
- [專案結構](#專案結構)
- [常見問題](#常見問題)
- [授權與參與方式](#授權與參與方式)

## 專案來源與範圍

TownPass 是臺北市政府推動的開源城市服務專案，讓市民與開發者能共同參與功能發想、開發與改善，也供其他縣市參考、整合既有市政系統，建立自己的數位服務應用。

此儲存庫是 TownPass 的衍生版本，保留既有 Flutter App 架構，新增台北安心行頁面與獨立網頁展示入口。兩種入口用途如下：

| 入口 | 用途 | 啟動方式 |
| --- | --- | --- |
| 台北安心行獨立展示 | 直接操作公廁查詢，避開完整 App 的原生服務初始化 | `flutter run -t lib/companion_demo.dart -d chrome` |
| 完整 TownPass App | 啟動原有 App，從首頁進入「台北安心行」 | `flutter run -t lib/main.dart -d <裝置ID>` |

台北安心行功能沒有付費 API、雲端模型或商業地圖服務依賴，也不需要定位權限；完整 App 仍包含上游的通知、定位等原生服務。

## 目前可以做什麼

| 功能 | 行為說明 |
| --- | --- |
| 關鍵字搜尋 | 依公廁名稱、地址或行政區搜尋 |
| 行政區篩選 | 選擇單一行政區，或查看全部行政區 |
| 無障礙／親子需求 | 篩選來源登載對應廁座數大於零的地點 |
| 照護床需求 | 篩選「照護床位置」欄位有登載的地點 |
| 多條件查詢 | 所有條件須同時符合；例如同時選無障礙與親子，只顯示兩者皆符合的地點 |
| 地點詳細資料 | 查看地址、設施座數、照護床位置、管理單位及官方來源，並可複製地址 |
| 收藏 | 收藏／取消收藏地點，切換「只看收藏」，重新開啟後可讀取本機收藏 |
| 公開資料更新 | 手動下載來源 CSV；更新失敗時保留既有資料並提示重試 |
| 離線查詢 | 使用已儲存的資料快取或內建真實資料快照 |

目前沒有地圖導航、可通行路線規劃、距離排名、即時開放狀態或跨裝置收藏同步。詳細頁的開放時間與即時可用狀態會標示為「未知」。

## 快速開始

### 1. 準備開發環境

- 安裝 Git。
- 依 [`.fvmrc`](.fvmrc) 使用 **Flutter 3.47.6**。可直接安裝 Flutter，或用 FVM 管理版本。
- [`pubspec.yaml`](pubspec.yaml) 要求 Dart SDK `>=3.13.0 <4.0.0`；Dart 隨 Flutter SDK 提供。
- 網頁展示需要 Chrome。Android 開發需要 Android SDK 與相容的 Java 環境；iOS 開發需要 macOS、Xcode 與 CocoaPods。

先確認環境與可用裝置：

```sh
flutter --version
flutter doctor
flutter devices
```

若使用 FVM，先在專案根目錄執行 `fvm install`，並將下列指令中的 `flutter` 改為 `fvm flutter`。

### 2. 下載專案並安裝套件

```sh
git clone https://github.com/steventeng2022/TownPass-self.git
cd TownPass-self
flutter pub get
```

### 3. 產生必要程式碼

專案包含資源與 JSON 模型的程式碼產生設定；第一次啟動前請執行：

```sh
dart run build_runner build
```

使用 FVM 時，此步改為 `fvm dart run build_runner build`。

### 4. 啟動台北安心行網頁展示

```sh
flutter run -t lib/companion_demo.dart -d chrome
```

啟動後會直接顯示「台北安心行」，不需先進入完整 TownPass 首頁。首次沒有快取時，使用內建公開資料快照；不必先按更新就能查詢。

## 操作與展示步驟

1. **查看資料狀態**：首頁上方顯示資料來源、地點數、來源更新基準與最近成功下載時間。內建快照包含 1,537 個地點、12 個行政區；下載更新後數量可能改變。
2. **選擇需求**：選行政區，再勾選「無障礙廁所」「親子廁所」或「照護床有登載」。多項需求採交集；結果為零時可減少條件。
3. **搜尋地點**：輸入名稱、地址或行政區。搜尋會與已選的需求條件一起套用。
4. **查看詳細內容**：點選地點，確認設施與資料來源，必要時按「複製地址」。出發前仍應向管理單位確認現場情況。
5. **收藏地點**：按書籤圖示或詳細頁的「收藏地點」，返回後開啟「只看收藏」。在同一裝置與瀏覽器環境重新開啟，可檢查收藏是否保留。
6. **嘗試更新與離線使用**：按「更新公開資料」；斷網後再次更新，應顯示失敗提示並保留既有資料。恢復網路後可再重試。

收藏只存在本機，由作業系統或瀏覽器管理；清除應用程式資料或瀏覽器網站資料可能移除收藏。來源若變更地點名稱、地址或行政區，可能需要重新收藏。

## 完整 App 與建置

以下指令均在專案根目錄執行，並先完成套件安裝與程式碼產生。

### 執行完整 TownPass App

先以 `flutter devices` 取得裝置 ID，再把 `<裝置ID>` 替換為實際值，例如 Android 模擬器或手機的 ID：

```sh
flutter run -t lib/main.dart -d <裝置ID>
```

完整 App 會初始化帳號、裝置資訊、定位與通知等上游服務；台北安心行入口位於首頁。要展示網頁版公廁查詢，請使用上方獨立展示指令。

### 建置網頁展示

```sh
flutter build web -t lib/companion_demo.dart --no-web-resources-cdn
```

輸出位於 `build/web/`。請透過 HTTP 靜態伺服器開啟，例如本機 `localhost`，不要直接以 `file://` 開啟 HTML。首次載入仍需能取得應用程式本身與 CanvasKit 等資源；資料可離線查詢，不代表網頁首次啟動即可完全離線。

### 建置 Android 除錯 APK

完成 Android SDK、Java 環境設定並接受 SDK 授權後執行：

```sh
flutter doctor --android-licenses
flutter build apk --debug -t lib/main.dart
```

成功時 APK 通常位於 `build/app/outputs/flutter-apk/app-debug.apk`。此為建置指令說明；既有驗證紀錄尚未產出 APK，詳見下方限制。

## 資料來源與離線行為

- **提供機關**：臺北市政府環境保護局。
- **資料集**：[臺北市公廁點位資訊](https://data.taipei/dataset/detail?id=ca205b54-a06f-4d84-894c-d6ab5079ce79)。
- **內建快照**：[`assets/open_data/taipei_toilets.csv`](assets/open_data/taipei_toilets.csv)，來源更新基準為 **2026-08-24**。
- **資料授權**：[政府資料開放授權條款第 1 版](https://data.gov.tw/license)。原始下載連結與快照 SHA-256 見 [詳細文件](docs/taipei-companion.md#真實資料與歸屬)。

啟動時優先讀取有效的本機快取；沒有快取或快取損毀時改讀內建快照。使用者主動更新成功後，程式才會儲存下載資料；更新失敗不會清除既有資料。快取與內建快照都無法讀取時，畫面會顯示載入失敗並提供重試。

資料欄位空白、無效或負值座數視為「未知」；登載為零則代表來源記錄為零座。未知設施不列入對應需求篩選。「照護床有登載」只表示欄位有內容，不能保證現場可使用。

最近成功下載時間與來源更新時間分開顯示。重新下載不代表來源剛更新；目前仍保守採用內建來源日期基準，超過 30 日會提醒確認。網頁更新可能受來源站的 CORS（跨來源存取限制）影響，此時仍可查詢既有快取或內建快照。

## 測試與目前限制

執行測試與台北安心行相關靜態分析：

```sh
flutter test
flutter analyze lib/page/companion lib/companion_demo.dart test
```

既有測試涵蓋 CSV 解析、需求交集、未知值、快取與更新失敗處理、收藏持久化，以及兩倍字體的畫面檢查。

依 [既有驗證紀錄](docs/taipei-companion.md#本機實際驗證與限制)：

- 已完成套件安裝、程式碼產生、相關測試與網頁建置；新增功能的分析無問題。
- 完整專案分析另有上游警告／提示，尚不能視為全專案零警告。
- 當時驗證環境缺少 Android SDK，APK 建置未成功，未產出 APK。
- 實體手機、螢幕閱讀器與完整 TownPass 啟動仍待驗收。

上述為既有文件記錄，不代表每次文件更新都重新完成全平台驗證。

## 專案結構

```text
lib/
  main.dart                  # 完整 TownPass App 入口
  companion_demo.dart        # 台北安心行獨立展示入口
  page/companion/            # 查詢畫面、資料模型、快取與收藏處理
  page/home/                 # TownPass 首頁與功能入口
  service/                   # 上游帳號、裝置、定位、通知等服務
  util/                      # 共用元件、樣式與路由
assets/
  open_data/                 # 真實公廁資料快照
  fonts/                     # Noto Sans CJK TC 字體與授權
  mock_data/                 # 上游功能使用的模擬資料
docs/taipei-companion.md     # 功能、來源、授權與驗證細節
test/                       # 單元與畫面測試
android/、ios/、web/          # 平台相關設定
```

## 常見問題

| 問題 | 處理方式 |
| --- | --- |
| 出現 Dart／套件版本不相容 | 確認使用 `.fvmrc` 指定的 Flutter，並重新執行 `flutter pub get` |
| 找不到 `assets.gen.dart` 或模型的 `.g.dart` | 在根目錄執行 `dart run build_runner build`；使用 FVM 時加上 `fvm` |
| 找不到 Chrome 或 Android 裝置 | 執行 `flutter doctor` 與 `flutter devices`，確認瀏覽器、模擬器或 USB 偵錯設定 |
| 顯示 `No Android SDK found` | 安裝並設定 Android SDK，依 `flutter doctor` 提示修正後重試 |
| 網頁按更新失敗 | 檢查網路與來源站 CORS 限制；既有快取／快照仍可查詢，稍後再重試 |
| 篩選後沒有地點 | 多條件須同時符合，未知值不列入需求篩選；嘗試清除關鍵字或減少條件 |
| 資料顯示超過 30 日 | 表示來源日期基準較舊；按更新不保證官方內容已更新，仍需確認現場資訊 |

## 授權與參與方式

各部分授權依儲存庫現有檔案分別標示：

- **TownPass 既有程式與通知**：保留上游 [`LICENSE`](LICENSE)（GPLv3）。
- **台北安心行新增程式、相關測試與文件**：依 [`NOTICE-COMPANION.md`](NOTICE-COMPANION.md) 標示為 **AGPL-3.0-or-later**，全文見 [`LICENSE-AGPL-3.0.txt`](LICENSE-AGPL-3.0.txt)。
- **公廁開放資料**：依政府資料開放授權條款第 1 版，保留提供機關與來源標示。
- **打包字體**：Noto Sans CJK TC，採 SIL OFL 1.1，全文見 [`assets/fonts/OFL.txt`](assets/fonts/OFL.txt)。

完整授權範圍、上游素材盤點與正式提交前待確認事項，請閱讀 [授權與合規邊界](docs/taipei-companion.md#授權與合規邊界)。

歡迎透過本儲存庫的 Pull Request 提供改善，並遵守 [行為準則](CODE_OF_CONDUCT.md)。回報問題時請附上執行入口、Flutter 版本、裝置／瀏覽器、重現步驟與錯誤訊息。更多上游開發說明可參考 [TownPass 開發文件（英文）](https://tpe-guideline.web.app/en/docs/)。

