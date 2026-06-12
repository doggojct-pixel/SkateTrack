# SkateTrack Task-026 ～ 030：技術難點解決方案

**文件日期：** 2026-06-12
**適用版本：** BuildPlan Task-021–030 AccountAligned v2.0
**現行基準：** Task-025b 完成後，Task-026 尚未開始
**參考 ADR：** ADR-0001、ADR-0002、ADR-0003、ADR-0004、ADR-0005

---

## Task-026a｜Backup Package + Local Sync Simulation

---

### 難點①｜BackupPackage Schema 版本控制

**問題核心：**
`BackupPackageManifest` 的 `schemaVersion` 一旦定錯或未預留 migration path，
Task-026b（正式 Google Drive 整合）或未來跨裝置 restore 時會遇到格式不相容。

**解決方案：**

在 `BackupPackageManifest.swift` 定義時，強制加入兩個欄位並設計版本處理邏輯：

```swift
// Shared/Models/BackupPackageManifest.swift
struct BackupPackageManifest: Codable {
    let schemaVersion: Int          // 目前固定為 1
    let appVersion: String          // Bundle short version string
    let createdAt: Date
    let locale: String

    // 版本處理：未來版本升級時在此 switch
    static func decode(from data: Data) throws -> BackupPackageManifest {
        let raw = try JSONDecoder().decode(BackupPackageManifest.self, from: data)
        switch raw.schemaVersion {
        case 1:
            return raw
        default:
            throw BackupError.unsupportedSchemaVersion(raw.schemaVersion)
        }
    }
}
```

**關鍵原則：**
- `schemaVersion` 從 `1` 開始，不要用字串或 float，用 `Int` 最單純。
- Decode 時走 switch，讓未來加 case 不需動原有路徑。
- Cursor Agent prompt 必須明確寫：「`schemaVersion` 為 `Int`，目前只允許 `1`，decode 失敗需 throw `BackupError.unsupportedSchemaVersion`。」

---

### 難點②｜多 Store 資料同時序列化

**問題核心：**
Sessions、Equipment、Spots、Achievements 各自由不同 Repository 管理，
任何一個 model 若有 non-Codable 的 property，整包備份就會 build error 或 runtime crash。

**解決方案：**

在 `BackupPackageEncoder.swift` 中，每個 store 個別 encode，用 `Result` 包裝，
不讓單一 store 失敗拖垮整包：

```swift
// iOS/Core/Sync/BackupPackageEncoder.swift
struct BackupPackageEncoder {
    func encode(
        sessions: [SessionData],
        equipment: [EquipmentProfile],
        spots: [SpotProfile],
        achievements: [AchievementUnlockRecord]
    ) -> BackupPackageResult {
        var errors: [String] = []

        let sessionsData = Result { try JSONEncoder().encode(sessions) }
        let equipmentData = Result { try JSONEncoder().encode(equipment) }
        let spotsData = Result { try JSONEncoder().encode(spots) }
        let achievementsData = Result { try JSONEncoder().encode(achievements) }

        // 收集失敗的 store，不直接 throw
        if case .failure(let e) = sessionsData { errors.append("sessions: \(e)") }
        // ... 其他同理

        return BackupPackageResult(
            sessions: try? sessionsData.get(),
            equipment: try? equipmentData.get(),
            spots: try? spotsData.get(),
            achievements: try? achievementsData.get(),
            encodingErrors: errors
        )
    }
}
```

**關鍵原則：**
- 每個 store 獨立 encode，部分失敗仍可輸出其餘 store 的備份。
- 確認 `SessionData`、`EquipmentProfile`、`SpotProfile`、`AchievementUnlockRecord` 的所有屬性都是 `Codable`（現有 `Shared/Models/` 已是 Codable，但 Task-026 前需先跑一次 `verify_shared_models.py` 確認）。
- Cursor Agent prompt 中加一行：「不要在 `BackupPackageEncoder` 直接 import `CoreData` 或存取 `NSManagedObject`，只接受 domain model。」

---

### 難點③｜Conflict Policy 設計

**問題核心：**
Restore 時若 local data 比 backup 新，沒有明確的 conflict policy，
026b 整合 Drive 時 agent 會自行決定 merge 行為，極易造成資料損毀。

**解決方案：**

在 Task-026a 就在 code 層定義 policy enum，但 Task-026a 只實作 `localWins` 一種：

```swift
// iOS/Core/Sync/CloudBackupProvider.swift
enum BackupConflictPolicy {
    case localWins      // Task-026a 唯一實作：restore 需使用者主動確認
    case remoteWins     // Task-026b 才實作：Drive 強制覆蓋
    case mergeByDate    // 未來：依 createdAt 合併（明確標示 deferred）
}
```

UI 層在 `BackupSyncSettingsView` 做 restore 前，強制顯示確認 dialog：

```swift
// 確認 dialog 必須說明：
// "還原將以備份檔案取代現有資料，目前的本機資料將被覆蓋。"
// 不要用「合併」「同步」等暗示雙向的詞
```

**關鍵原則：**
- ADR-0002 已明確規定「正式 Drive 整合前不自動覆蓋資料」。
- `BackupConflictPolicy.mergeByDate` 只定義 enum case，不實作，加 `// DEFERRED: Task-026b` 註解。
- Cursor Agent prompt 加：「`localWins` 實作必須要求使用者主動 confirm，不可自動靜默覆蓋。」

---

### 難點④｜Provider Boundary 一致性

**問題核心：**
現有 `AuthProvider`、`WeatherProviding` 都是 protocol + disabled + mock 三層，
如果 `CloudBackupProvider` 的注入方式不一致，026b 的 Cursor Agent 很容易繞過 boundary。

**解決方案：**

嚴格複製現有 `WeatherProvider` 的三層結構：

```
CloudBackupProvider.swift       ← protocol（放 Shared/Protocols/ 或 iOS/Core/Sync/）
LocalBackupProvider.swift       ← 本機檔案實作（026a 唯一 live provider）
DisabledDriveProvider.swift     ← Drive 未接時的 disabled stub
```

在 `useBackupSync.swift` hook 中注入，Views 只看 hook，不看 provider：

```swift
// iOS/Hooks/useBackupSync.swift
@MainActor
final class useBackupSync: ObservableObject {
    private let provider: CloudBackupProvider
    // 正式 026b 只需換掉 provider，View 不動
    init(provider: CloudBackupProvider = LocalBackupProvider()) { ... }
}
```

**關鍵原則：**
- Cursor Agent prompt 第一行寫：「`BackupSyncSettingsView` 只能 import `useBackupSync`，不可直接 import `LocalBackupProvider` 或 `DisabledDriveProvider`。」
- 與 `useAccount`、`useWeatherRisk` 的 hook 命名風格保持一致。

---

## Task-027｜AirDrop `.skatetrack` Export + macOS Import Stub

---

### 難點①｜UTType 宣告 vs. Signing 衝突

**問題核心：**
自訂 UTType 若加到 Xcode capabilities 面板會觸動 signing，
但純 `Info.plist` 的 `UTExportedTypeDeclarations` 在沒有 Developer Account 的情況下，
AirDrop 接收端能否正確辨識是未知數。

**解決方案：**

Task-027 採用「不宣告 custom UTType，改用已知 UTType」的安全路徑：

- 匯出時使用 `UTType.data`（`public.data`）包裝 `.skatetrack` zip 檔。
- 檔名副檔名 `.skatetrack` 由 app 自行命名，AirDrop / Files 傳輸後接收端靠**副檔名判斷**，不靠 UTType 宣告。
- 等 Apple Developer Account 申請後，再補 `UTExportedTypeDeclarations`，並在 Task-027 的 verify script 加一個 check：確認 `project.pbxproj` 沒有新增 capability entitlement。

```python
# scripts/verify_skatetrack_package.py 需加的 check
def check_no_new_entitlements():
    # 比對 project.pbxproj 是否新增 com.apple.developer.* key
    # 若有則 FAIL 並提示需 Developer Account
    pass
```

**關鍵原則：**
- Cursor Agent prompt 明確寫：「不要在 Xcode 的 Capabilities 面板新增任何項目，不要改動 `.entitlements` 檔案。」

---

### 難點②｜Package Writer / Reader 的跨平台相容

**問題核心：**
iOS `FileManager` 的 tmp 路徑與 macOS sandbox 的 Document 路徑不同，
若 Writer / Reader 各自 hardcode 路徑，028 的 macOS Viewer 無法讀到 iOS 寫出的包。

**解決方案：**

`SkateTrackPackageWriter` 和 `SkateTrackPackageReader` 放在 `Shared/Export/`，
只接受呼叫端傳入的 `URL`，不在 Shared 層自行取 `FileManager` 路徑：

```swift
// Shared/Export/SkateTrackPackageWriter.swift
struct SkateTrackPackageWriter {
    // 呼叫端（iOS 或 macOS）負責決定目標路徑，Writer 只管寫內容
    func write(package: SkateTrackPackage, to destinationURL: URL) throws {
        // 1. 建立暫存目錄
        // 2. 寫 manifest.json、sessions.json 等
        // 3. 壓縮成 zip，命名為 *.skatetrack
        // 4. 移到 destinationURL
    }
}
```

iOS 端在 `AirDropExportView.swift` 決定路徑：
```swift
let tempURL = FileManager.default.temporaryDirectory
    .appendingPathComponent(UUID().uuidString)
    .appendingPathExtension("skatetrack")
```

macOS 端在 `MacImportView.swift` 透過 `NSOpenPanel` 讓使用者選路徑，不 hardcode。

**關鍵原則：**
- `Shared/Export/` 的 code 不能有 `#if os(iOS)` / `#if os(macOS)` 分支，路徑邏輯由各平台 Feature layer 處理。

---

### 難點③｜Backup Package vs. .skatetrack Package 格式重疊

**問題核心：**
026a 的 `BackupPackage` 和 027 的 `.skatetrack` 都包含 sessions、spots、equipment，
格式如果不明確分開，028 的 macOS Viewer 會搞不清楚要讀哪一個格式。

**解決方案：**

在 Task-027 prompt 開頭明確定義兩種格式的**用途差異**，寫進 manifest 的 `packageType` 欄位：

```swift
// Shared/Models/SkateTrackPackageManifest.swift
enum PackageType: String, Codable {
    case backup       // 026a 備份用：完整資料，含 achievements，供還原
    case export       // 027 分享用：精簡資料，供 AirDrop / macOS 閱覽
}

struct SkateTrackPackageManifest: Codable {
    let packageType: PackageType   // ← 這個欄位讓 028 的 macOS reader 知道如何處理
    let schemaVersion: Int
    // ...其他欄位
}
```

**關鍵原則：**
- `export` 格式不包含 `achievements`（屬於帳號個人資料，不應隨騎乘紀錄 AirDrop 出去）。
- Cursor Agent prompt 加：「`SkateTrackPackageManifest.packageType` 必須是 `backup` 或 `export`，`macOS import stub` 只處理 `export` 類型。」

---

## Task-028｜macOS App Shell + Phase 1a Viewer

---

### 難點①｜Shared Model 在 macOS target 的相容性

**問題核心：**
Task-021 ～ 026 若有任何 `Shared/Models/` 或 `Shared/Persistence/` 的 code 隱含 `UIKit`，
macOS target 會在 028 集中爆發 compile error。

**解決方案：**

**在 Task-026 完成後、Task-028 開始前**，先執行一次專門的 macOS build check：

```bash
xcodebuild build \
  -workspace SkateTrack.xcworkspace \
  -scheme SkateTrack-macOS \
  -destination "platform=macOS" \
  | grep -E "error:|warning:" | head -30
```

若出現 `UIKit` / `UIColor` / `UIImage` 相關 error，在 Task-028 prompt 第一步列出需修正的檔案，統一加 `#if canImport(UIKit)` 隔離，**不要逐一在各 model 手動修改**。

針對現有已知風險點，預先在 `Shared/Models/` 的顏色相關 code 加跨平台 typealias：

```swift
// Shared/Utilities/CrossPlatformTypes.swift（新增）
#if canImport(UIKit)
import UIKit
typealias PlatformColor = UIColor
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformColor = NSColor
typealias PlatformImage = NSImage
#endif
```

**關鍵原則：**
- Cursor Agent prompt 第一條：「先執行 `xcodebuild build -scheme SkateTrack-macOS`，列出所有 error 後再修。不要邊改邊猜。」

---

### 難點②｜macOS Sandbox + FileManager 路徑

**問題核心：**
macOS App Sandbox 下無法直接讀寫任意路徑，
`.skatetrack` import 必須透過 `NSOpenPanel` 取得使用者授權的 URL。

**解決方案：**

`MacImportView.swift` 使用 `NSOpenPanel` + security-scoped bookmark：

```swift
// macOS/Features/Import/MacImportView.swift
func openPackage() {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.data]  // 配合 Task-027 的 UTType 策略
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    
    if panel.runModal() == .OK, let url = panel.url {
        // 用 security-scoped bookmark 讓 macOS shell 有持續讀取權
        importPackage(from: url)
    }
}
```

**關鍵原則：**
- macOS target 不要用 `UIDocumentPickerViewController`（iOS only）。
- Cursor Agent prompt 加：「macOS import 使用 `NSOpenPanel`，不要使用 `UIDocumentPickerViewController`，不要使用 iOS `DocumentPicker` 相關 API。」

---

### 難點③｜macOS NavigationSplitView vs. iOS NavigationStack

**問題核心：**
iOS 的 `RootNavigationView` 是 Tab / pill 導覽，
macOS 應用慣例是 Sidebar + Detail，若直接複用 iOS View 會崩版。

**解決方案：**

`macOS/App/MacRootView.swift` 完全獨立，使用 `NavigationSplitView`：

```swift
// macOS/App/MacRootView.swift
struct MacRootView: View {
    var body: some View {
        NavigationSplitView {
            MacSidebarView()          // 側邊欄：Import、Sessions（locked）
        } detail: {
            MacDetailPlaceholderView()
        }
    }
}
```

`Shared/` 中的 View 元件（如 metric card、chart）可以被 macOS 複用，
但**導覽結構（Navigation）必須在各平台的 App/ 層各自定義**，不從 iOS 拉。

**關鍵原則：**
- Cursor Agent prompt 明確：「`macOS/App/MacRootView.swift` 不能 import 或使用 `iOS/App/RootNavigationView.swift`，導覽結構獨立實作。」

---

### 難點④｜Locked Feature Cards 設計

**問題核心：**
若沒有統一的 locked card 元件，每個 macOS 功能點各自用不同方式顯示 "coming soon"，
Task-029 的 accessibility pass 會很破碎。

**解決方案：**

在 `Shared/` 或 `macOS/Features/` 建立一個可重用的 `LockedFeatureCardView`：

```swift
// macOS/Features/Shared/MacLockedFeatureCardView.swift
struct MacLockedFeatureCardView: View {
    let featureName: String
    let iconName: String
    
    var body: some View {
        VStack {
            Image(systemName: iconName)
            Text(featureName)
            Text("coming.soon.label")  // Localizable key
                .foregroundStyle(.secondary)
        }
        // 統一的灰階 / 透明樣式
    }
}
```

Task-028 所有 "未完成功能" 都用這個元件，Task-029 只需要對它做一次 accessibility 審計。

---

## Task-029｜Localization + Accessibility + Privacy Pass

---

### 難點①｜Localizable Key 審計規模

**問題核心：**
Task-001 到 028 橫跨三個 target，若有 hardcoded 中文或英文字串散落在 View 中，
這個 task 要全部補 key，規模龐大且容易遺漏。

**解決方案：**

用 script 先掃出所有**非 Localizable key 的字串**（即直接用 `"..."` 而非 `NSLocalizedString` 或 `"key".localized` 的字串），縮小人工審查範圍：

```python
# scripts/verify_privacy_copy.py 加入的 check（或新 script）
import re, os

SWIFT_STRING_PATTERN = re.compile(r'Text\("([^"]+)"\)')
LOCALIZED_PATTERN = re.compile(r'Text\(LocalizedStringKey\(|NSLocalizedString\(|String\(localized:')

def find_hardcoded_strings(root):
    issues = []
    for dirpath, _, filenames in os.walk(root):
        for fname in filenames:
            if not fname.endswith('.swift'): continue
            path = os.path.join(dirpath, fname)
            content = open(path).read()
            for line_no, line in enumerate(content.splitlines(), 1):
                if SWIFT_STRING_PATTERN.search(line) and not LOCALIZED_PATTERN.search(line):
                    issues.append(f"{path}:{line_no}: {line.strip()}")
    return issues
```

把這個 script 加進 `scripts/verify_localization_keys.py`，Task-029 開始前先跑一次，列出待修清單。

**關鍵原則：**
- Cursor Agent prompt 加：「先執行 `verify_localization_keys.py` 掃出 hardcoded string，列出清單後按清單修，不要直接猜。」

---

### 難點②｜InfoPlist Privacy Strings 與實際權限對齊

**問題核心：**
ADR-0002 / 0003 都規定「文案不能承諾未完成的外部服務」，
但 Task-023c 加了 Photo 權限，Task-021 有 MapKit，
若文案說「用於提供即時天氣」但 WeatherKit 根本未接，就是違反這個原則。

**解決方案：**

建立一張**權限 ↔ 實際使用狀態**對照表，Task-029 開始時人工確認：

| 權限 Key | 目前文案 | 實際服務狀態 | 是否合規 |
|---|---|---|---|
| `NSPhotoLibraryAddUsageDescription` | 儲存騎乘分享卡 | Task-023c 已實作（add-only）| ✅ |
| `NSLocationWhenInUseUsageDescription` | GPS 路徑記錄 | Task-006 已實作 | ✅ |
| `NSLocationAlwaysUsageDescription` | （若存在）| 未實作 | ⚠️ 需移除或改文案 |
| `WeatherKit` 相關 | （若存在）| DisabledWeatherProvider | ⚠️ 不應出現 |

把這個對照表加進 `docs/PRIVACY_DATA_INVENTORY.md`，並在 `scripts/verify_privacy_copy.py` 中加 check 確認沒有未使用的 NSXxxUsageDescription key。

---

### 難點③｜Dynamic Type 在 Live HUD 畫面

**問題核心：**
Live HUD 是全螢幕大字速度顯示，Dynamic Type 放大時數字可能超出畫面邊界。

**解決方案：**

`LiveSpeedDisplayView.swift` 的速度字型改用 `minimumScaleFactor` + `lineLimit(1)` 組合，
避免字型放大時截斷而非縮放：

```swift
// iOS/Features/SessionRecording/LiveSpeedDisplayView.swift
Text(speedString)
    .font(.system(size: 72, weight: .black, design: .rounded))
    .minimumScaleFactor(0.5)   // 允許縮到 50% 而不截斷
    .lineLimit(1)
    .allowsTightening(true)
```

`TiltIndicatorView` 的說明文字若過長，加 `.lineLimit(2)` + `.fixedSize(horizontal: false, vertical: true)` 讓 card 自動撐高而不截字。

Task-029 的 verify script 加一個 check：掃描 HUD 相關 View 是否有 `.minimumScaleFactor` 或 `dynamicTypeSize` 的限制處理。

---

### 難點④｜Verify Scripts 的環境依賴

**問題核心：**
`verify_accessibility_labels.py` 靠靜態掃描 `.swift` 檔案來確認 accessibility label，
無法驗證 runtime 行為，可能給出「通過」但實際上 VoiceOver 讀不到。

**解決方案：**

**明確定義 verify script 的驗收範圍和限制**，在 script 頂部加說明：

```python
# scripts/verify_accessibility_labels.py
"""
靜態掃描：確認主要互動元件有 .accessibilityLabel 或 .accessibilityHint 呼叫。
不驗證：VoiceOver runtime 行為、動態內容更新、focus order。
Runtime VoiceOver 驗收需手動在 iPhone 上開啟輔助使用 → VoiceOver 測試。
"""
```

Script 的 check 範圍縮小到**可靠的靜態項目**：
- 所有 `Button` 有 `.accessibilityLabel`（不只用 icon 作為 label）
- 所有 `Image(systemName:)` 有 `.accessibilityLabel` 或 `decorative: true`
- Progress ring（`AchievementProgressRingView`）有 `.accessibilityValue`

**關鍵原則：**
- Cursor Agent prompt 加：「`verify_accessibility_labels.py` 只做靜態 pattern check，不要寫成需要 Xcode / simulator 才能跑的動態測試。」

---

## Task-030a｜Local Release Readiness

---

### 難點①｜Mock Provider 審計的完整性

**問題核心：**
從 Task-016 累積到 Task-028 的 mock / disabled provider 清單很長，
任何一個 mock 被意外編進 Release build 就是嚴重問題。

**解決方案：**

建立一個**Mock Provider 主清單**（加進 `docs/RELEASE_READINESS_CHECKLIST.md`），
並在 `verify_release_readiness.py` 中逐一確認每個 mock 都有 `#if DEBUG` 保護：

```python
# scripts/verify_release_readiness.py 的 mock audit 部分
KNOWN_MOCK_PROVIDERS = [
    "LocalAccountProvider.swift",
    "DisabledGoogleAuthProvider.swift",
    "MockWeatherProvider.swift",
    "DisabledWeatherProvider.swift",
    "DisabledDriveProvider.swift",         # Task-026a 新增
    "LocalBackupProvider.swift",           # Task-026a（注意：這個在 Release 是允許的！）
    "SessionRecordingCoordinator+DebugMock.swift",
    "DebugMockSessionFactory.swift",
]

# 需要 #if DEBUG 包裹的（不應進 Release）：
DEBUG_ONLY_FILES = [
    "LocalAccountProvider.swift",
    "SessionRecordingCoordinator+DebugMock.swift",
    "DebugMockSessionFactory.swift",
    # DisabledDriveProvider 在 Release 是允許的（disabled ≠ mock）
]
```

**注意：`DisabledXxxProvider` 和 `MockXxxProvider` 的語意不同：**
- `DisabledXxxProvider`：Release 可以有，代表「這個功能目前不提供」
- `MockXxxProvider`：只應存在於 DEBUG build

**關鍵原則：**
- Cursor Agent prompt：「`LocalAccountProvider` 和 `SessionRecordingCoordinator+DebugMock` 必須有 `#if DEBUG` 包裹，`DisabledGoogleAuthProvider` 不需要但必須不做任何實際 auth 行為。」

---

### 難點②｜xcodebuild 三 target 同時通過

**問題核心：**
Task-028 的 macOS shell 若有 `Shared/` 相容性問題，會在 030a 的 build 驗收時卡住。

**解決方案：**

`verify_release_readiness.py` 在最後一步執行三個 scheme 的 build，並**分開報錯**：

```python
import subprocess

SCHEMES = [
    ("SkateTrack-iOS",    "platform=iOS Simulator,name=iPhone 16"),
    ("SkateTrack-watchOS","platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)"),
    ("SkateTrack-macOS",  "platform=macOS"),
]

for scheme, dest in SCHEMES:
    result = subprocess.run([
        "xcodebuild", "build",
        "-workspace", "SkateTrack.xcworkspace",
        "-scheme", scheme,
        "-destination", dest,
    ], capture_output=True, text=True)
    
    if result.returncode != 0:
        print(f"❌ {scheme} BUILD FAILED")
        # 只印 error: 行，不印完整 log
        for line in result.stdout.splitlines():
            if "error:" in line:
                print(f"   {line}")
    else:
        print(f"✅ {scheme} BUILD PASSED")
```

**關鍵原則：**
- 三個 target 獨立報錯，不因為 iOS 通過就跳過 macOS。
- Cursor Agent prompt 加：「Task-030a 的 verify script 必須跑三個 scheme，不能只跑 iOS。」

---

### 難點③｜Feature Flag Audit vs. Subscription Entitlement

**問題核心：**
DEBUG 模式下的 local entitlement simulation 可能讓某些 Pro-gated 功能看起來正常，
但 Release build 換回 `LocalEntitlementProvider（free）` 後才發現有漏掉的 gate。

**解決方案：**

在 `verify_release_readiness.py` 中加一個 **Free Mode Smoke Test Check**：
掃描每個 `GatedFeature` case，確認有對應的 `LockedFeatureOverlayView` 或 Paywall route 存在於對應的 View 中：

```python
GATED_FEATURES = [
    ("GatedFeature.sessionShareCard",    "SessionShareCardLockedView"),
    ("GatedFeature.advancedCharts",      "AdvancedChartsLockedView"),
    ("GatedFeature.advancedChallenges",  "WeeklyChallengeCardView"),   # pro lock in card
    ("GatedFeature.spotManagement",      "SpotFavoriteLimitBanner"),
    # Task-026a 新增後需補：
    # ("GatedFeature.cloudBackup",        "BackupSyncLockedView"),
]

for feature_key, expected_lock_view in GATED_FEATURES:
    # 確認 expected_lock_view 存在且有被使用
    ...
```

---

### 難點④｜Task-030b Blocked Prerequisites 文件化

**問題核心：**
如果 `KNOWN_LIMITATIONS_PRE_ADP.md` 不夠完整，
申請 Apple Developer Account 後要花很多時間重新整理哪些 task 可以解封。

**解決方案：**

`KNOWN_LIMITATIONS_PRE_ADP.md` 用固定格式，每條 blocked item 都要寫明**解封條件**：

```markdown
# Known Limitations Before Apple Developer Program

## Blocked Items

### B-001 StoreKit Production Subscription
- **Blocked by:** Apple Developer Account + App Store Connect product creation
- **Current state:** `LocalEntitlementProvider` (free) / `DebugOverrideProvider` (debug)
- **Unlock task:** Create `AppStoreSubscriptionProvider` behind existing `EntitlementProviding` boundary
- **Files to change:** `iOS/Core/Subscription/FeatureFlagEngine.swift` (swap provider)

### B-002 WeatherKit Live Data
- **Blocked by:** Apple Developer Account + WeatherKit capability
- **Current state:** `MockWeatherProvider` / `DisabledWeatherProvider`
- **Unlock task:** Create `WeatherKitProvider` behind existing `WeatherProviding` boundary
- **Files to change:** `iOS/Core/HealthReminders/WeatherProvider.swift` (add case)

### B-003 Google Sign-In Production
- **Blocked by:** Google Cloud project + OAuth client ID + reversed URL scheme
- **Current state:** `DisabledGoogleAuthProvider` / `LocalAccountProvider` (debug)
- **Unlock task:** Create `GoogleSignInProvider` behind existing `AuthProvider` boundary
- **Files to change:** `iOS/Core/Account/AuthProvider.swift` (implement real provider)

### B-004 Google Drive Sync
- **Blocked by:** B-003 + Drive API scope authorization
- **Current state:** `DisabledDriveProvider`
- **Unlock task:** Task-026b

### B-005 TestFlight Upload
- **Blocked by:** Apple Developer Account + Bundle ID confirmation + App Store Connect record
- **Current state:** Archive not submitted
- **Unlock task:** Task-030b
```

---

## 跨任務共通解決原則

### 原則 A｜Cursor Agent Prompt 標準開頭模板

每個 Task-026 ～ 030 的 Cursor Agent prompt，前三行必須是：

```
請執行 SkateTrack Task-XXX。
參考 ADR：[列出相關 ADR 編號]
Provider boundary 規則：[列出這個 task 的 disabled / mock provider 清單]
Views 只能 import 對應的 hook（useXxx），不可直接 import provider 或 Core Data。
```

### 原則 B｜`Shared/` 新增 model 前先確認 Codable

Task-026 開始後每次新增 `Shared/Models/` 的 model，先跑：

```bash
python3 scripts/verify_shared_models.py
```

若 model 有 non-Codable 屬性，在進 Task-027 前就要修，不要累積到 Task-028 爆發。

### 原則 C｜macOS Build Check 時機

Task-028 開始前必須先跑一次 macOS build，把 UIKit leak 集中修完後再讓 Cursor Agent 繼續。

### 原則 D｜Disabled vs. Mock 語意區分

| 類型 | 命名 | Release 可否包含 | 說明 |
|---|---|---|---|
| `DisabledXxxProvider` | `Disabled` 前綴 | ✅ 可以 | 功能未接，誠實告知使用者 |
| `MockXxxProvider` | `Mock` 前綴 | ❌ 不可以（需 `#if DEBUG`）| 假資料，只用於開發測試 |
| `LocalXxxProvider` | `Local` 前綴 | 視情況 | 本機實作（如 `LocalBackupProvider`）為 Release 正式功能 |

---

*此文件應在 Task-026 開始前 commit 至 `docs/` 或 `tasks/` 目錄，作為 026-030 執行階段的風險防護參考。*

---

## Task-027a adoption note（2026-06-12）

Task-027a adopted the pre-ADP safe path described in this document:

- No custom UTType declaration or document association was added.
- `.skatetrack` files are shared as normal file URLs through the iOS system share sheet.
- `Shared/Export/SkateTrackPackageWriter.swift` and `Shared/Export/SkateTrackPackageReader.swift` accept caller-provided URLs and do not hardcode iOS or macOS paths.
- `packageType = export` is separate from Task-026 backup packages (`packageType = backup`).
- macOS Import Stub / package preview is explicitly deferred to Task-027b / Task-028.
- Task-026c production Google Drive provider remains blocked and is tracked in `docs/KNOWN_LIMITATIONS_PRE_ADP.md`.

---

## Task-027b implementation alignment note

Task-027b applies the Task-027 / Task-028 risk controls without enabling custom document capabilities:

- macOS import uses `NSOpenPanel`, not `UIDocumentPickerViewController`.
- The panel accepts `UTType.data` and the ViewModel validates the `.skatetrack` extension; the project still does not declare `UTExportedTypeDeclarations` or `CFBundleDocumentTypes`.
- `Shared/Export/SkateTrackPackageReader.swift` remains platform-neutral and does not choose sandbox paths.
- `MacRootView` uses a macOS-native `NavigationSplitView` and does not reuse iOS navigation.
- `MacLockedFeatureCardView` standardizes coming-soon states for Task-028 / Task-029 accessibility review.
- The import preview is read-only: no restore, merge, local database import, Google Drive sync, CloudKit, or production StoreKit behavior is introduced.

### Task-027b UI stability follow-up

After manual macOS testing, Task-027b keeps `NavigationSplitView` but uses a custom fixed sidebar instead of `List(selection:)` to avoid sidebar jump / collapse behavior when selecting locked placeholder destinations. This still satisfies the Task-027 / Task-028 risk control that macOS navigation must be independent from iOS `RootNavigationView`, while keeping document association, custom UTType, import persistence, and cloud sync deferred.

Task-027b verification token: stable custom sidebar.

## Task-028a Implementation Note — Read-only Viewer First

Task-028 was split into Task-028a / Task-028b to reduce macOS shell risk.

Task-028a implements a read-only `Session Browser` foundation:

- The macOS sidebar remains independent from iOS `RootNavigationView`.
- `MacRootView` owns the shared package preview state so Import and Session Browser observe the same validated `.skatetrack` payload.
- The viewer lists sessions from the package and shows only read-only detail metrics.
- Older exports with route / speed samples but empty summary metrics can show viewer-side derived metrics without modifying package contents.
- `MacSpeedSparklineView` uses SwiftUI `Path` instead of Swift Charts, keeping Charts / MapKit risk deferred to Task-028b.

Task-028a explicitly does not add persistent imports, Core Data writes, document association, custom UTType, Finder open-with behavior, report export, MapKit route rendering, Swift Charts, Google Drive, iCloud, CloudKit, or StoreKit production behavior.

## Task-028a Layout Polish Note — compact viewer before visualization

After the first Task-028a implementation, the macOS Session Viewer was adjusted before Task-028b so the layout behaves like a desktop viewer rather than an iOS-style full-height card stack.

- Session list column is compact and list-like.
- Session detail uses a compact macOS dashboard layout.
- Speed preview remains a lightweight SwiftUI `Path`; Swift Charts is still deferred.
- Route information remains summary-only; MapKit route rendering is still deferred.
- No storage import, merge, document association, custom UTType, signing, cloud sync, or paid feature behavior is added.


### Task-028a Layout Restructure Note

The macOS viewer foundation should avoid a three-column layout while iOS export packages remain single-session packages. The safer Task-028a UX is a right-side stacked layout: persistent function sidebar on the left, compact package-session summary at the top of the main content, and the main Session detail dashboard below. Multi-session package selection remains supported as a compact horizontal selector only if a future package contains more than one session.

This restructure remains within the Task-028a safety boundary: read-only package viewer, no persistent import, no merge / restore, no MapKit / Charts, no custom UTType or document association, and no signing / capability changes.
