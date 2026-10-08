# 台北安心行（賽前準備原型）

新增繁體中文公共廁所需求查詢、真實公開資料快照、收藏與離線提示；可明確同意後取得單次位置依直線距離排序，並從詳細頁開啟外部地圖路線（不保證路線無障礙）。功能與授權、展示步驟、實際建置限制見 [台北安心行文件](docs/taipei-companion.md)。網頁展示：`flutter run -t lib/companion_demo.dart -d chrome`。

## 下載最新建置 / Download builds

每次 push 都會自動建置 Android、網站與 iOS。

**[查看最新成功建置與下載檔案](https://github.com/steventeng2022/TownPass-self/actions/workflows/autobuild.yml?query=is%3Asuccess)**：開啟最上方成功的執行紀錄，在 **Artifacts** 下載所需平台。需登入 GitHub；Actions 下載為 ZIP，請先解壓縮。

目前已驗證成功的建置：[Build downloadable apps](https://github.com/steventeng2022/TownPass-self/actions/runs/37725315934)。

- [Android APK](https://github.com/steventeng2022/TownPass-self/actions/runs/37725315934/artifacts/11527931587)：完整 TownPass 原生 app，debug 簽署；解壓縮後安裝 `.apk`。
- [網站 ZIP](https://github.com/steventeng2022/TownPass-self/actions/runs/37725315934/artifacts/11527698876)：台北安心行獨立網頁版本，不是完整 TownPass；解壓縮下載的 artifact，再解壓縮內部 `townpass-web.zip`，將內容部署到靜態網站主機。不要直接用 `file://` 開啟。
- [iOS IPA](https://github.com/steventeng2022/TownPass-self/actions/runs/37725315934/artifacts/11527144700)：未設定 Apple 簽署時提供 `townpass-ios-unsigned.ipa`；**須另行簽署與 provisioning 才能安裝至 iPhone**，不是可直接安裝的正式發行版。

Artifacts 保存 30 日；固定建置的下載連結可能到期，請優先使用上方「最新成功建置」入口。建置成功不代表已完成實機功能驗收。

# What is Town Pass?

Town Pass is an open-source project developed by the Taipei City Government. With the growth of smart cities, the demand for digitalization in city management and citizen services continues to rise. As we enter a new digital era, our goal is to involve citizens in the process, combining third-party expertise and innovation to make digital life in Taipei more convenient.

Town Pass is not just an application; it is an open community project. Through open-source, every citizen can participate in the ideation, development, and optimization of the application. This not only enhances citizen engagement and satisfaction but also leverages collective intelligence to continuously improve the application, making it truly serve the people. Furthermore, we hope that various municipalities can widely adopt the open-source framework of Town Pass, integrate it with their existing municipal service systems, and quickly have their own applications to enhance digital governance.

Open source is a key driver of technological progress and social development. Through open-source, Town Pass will become an ever-evolving platform, attracting developers from all backgrounds to contribute. We welcome experts to submit code, report issues, provide suggestions, and even develop new features and creative ideas, working together to perfect Town Pass as we advance toward a smart city.

# Getting Started

We highly recommend to read through our [document](https://tpe-guideline.web.app/en/docs/) for more detail.

Here are some quick setup guide.

## Requirement

- [Flutter](https://docs.flutter.dev/get-started/install) or [FVM](https://fvm.app/documentation/getting-started/installation)
- [XCode](https://developer.apple.com/xcode/) (for iOS)
- [Android SDK](https://developer.android.com/studio/index.html) (for Android, with or without Android Studio)

## Build the Project

1. Get the packages project needed:

   ``` bash
   flutter pub get
   ```

2. Generate additional needed dart code for the project.

   ``` bash
   flutter packages pub run build_runner build
   ```

3. You are all set now, Run the project from your IDE or the through the command line:

   ``` bash
   flutter run
   ```
