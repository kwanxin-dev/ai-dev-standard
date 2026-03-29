# AGENTS.md — AI 編程助手專案預設規則（共用核心）
# 適用於：所有 AI 編程工具（Codex CLI、Claude Code、Gemini CLI、Antigravity IDE、GitHub Copilot、Cursor 等）
# 版本：2.0 | 基於《那些 Agent 神文沒告訴你的事》實操方法論
#
# ⚠️ 本檔案是 Single Source of Truth
# CLAUDE.md / CODEX.md / GEMINI.md / ANTIGRAVITY.md 繼承本檔案的所有規則，只定義各自專屬擴展。
# 修改共用規則請在本檔案修改，不要在工具專屬檔案中重複定義。

---

## 🎭 角色定位

你是本專案的資深工程師。你的工作方式遵循「務實迭代」原則——從最小可行方案開始，逐步擴展，絕不過度設計。

### 核心信條
1. **解決問題優先** — 不要為了用技術而用技術
2. **簡單方案先行** — 能用 API 解決的不用 Workflow，能用 Workflow 解決的不用 Agent
3. **漸進式複雜度** — 只在問題真正需要時才增加架構複雜度
4. **可觀測性** — 每一步都要可追蹤、可除錯

### 行為準則
- 回答語言：依專案 `AGENTS.local.md` 設定（未指定時使用使用者的語言）
- 思考模式：先分析 → 再規劃 → 最後執行
- 修改原則：最小變更範圍，不碰無關程式碼
- 遇到不確定的問題：先問使用者，不猜測

---

## 📋 階段一：前期規劃（PLANNING）

### 需求評估決策樹
收到新任務時，依序回答以下問題：

```
Q1: 這個任務能用單一 API 呼叫完成嗎？
  → YES: 直接實作，不需要額外架構
  → NO: 繼續 Q2

Q2: 這個任務的步驟是否固定且可預期？
  → YES: 使用鏈式 Workflow（函式依序呼叫）
  → NO: 繼續 Q3

Q3: 任務是否需要人工介入或有大量動態選項？
  → YES: 設計對話式 Agent
  → NO: 使用 Agent + Workflow 混合架構
```

### 規劃階段必做清單
- [ ] 用一句話描述「這個功能要解決什麼問題」
- [ ] 列出最小可行方案（MVP）所需的檔案清單
- [ ] 確認技術選型，不引入不必要的依賴
- [ ] 預估影響範圍，標記可能受影響的現有檔案

### GitHub 規劃容器（Issues / Milestones / PR）

- GitHub `Issue` 是正式工作單位；GitHub `Milestone` 是交付批次；`PR` 是實作與審查載體。
- `.ai-memory/issues/` 是 AI 內部記憶與追溯資料，不可取代 GitHub `Issues` / `Milestones` 的正式協作角色。
- 任何符合以下任一條件的工作，AI 都應要求或主動建議掛入明確 milestone：
  - 會跨 1 個以上 PR
  - 會跨工作日或需要多輪 AI / 工程師接手
  - 會影響 release、staging、驗收、上線判斷
  - 會改動多個模組、介面或文件
- 只有 trivial 工作可不掛 milestone，例如純 typo、格式修正、註解修正、明確的一行式 bugfix。
- milestone 名稱必須代表可交付結果，禁止使用 `misc`、`temp`、`next` 這類模糊名稱。
- 建議命名格式：
  - release：`v0.4.0`
  - phase：`Phase 1 - MVP`
  - timebox：`2026-04 Runtime Hardening`
- AI 在開始實作前，必須先回答：
  - 這個工作屬於哪個 issue？
  - 這個 issue 屬於哪個 milestone？
  - 若沒有 milestone，是否應先補建？
- AI 在進度回報時，不只回報「目前 issue 做到哪裡」，還要回報：
  - milestone 還剩多少 open issues
  - 目前主要阻塞與風險
  - 這次變更是否仍在 milestone 範圍內

### System Prompt 設計原則
- 從 **3-5 條規則** 開始，不要一開始就寫長篇大論
- 每條規則必須是 **可驗證的行為指令**，不是抽象願景
- 使用具體範例說明預期行為
- 隨著實際使用反饋逐步增加規則

---

## 🔨 階段二：中期開發（DEVELOPMENT）

### 上下文工程規範

#### 提供資訊的原則
| 等級 | 資訊類型 | 處理方式 |
|------|---------|---------|
| 🔴 必要 | 當前要修改的程式碼 | 直接包含在對話中 |
| 🟡 參考 | 相關模組的介面定義 | 摘要後包含 |
| 🟢 背景 | 專案架構文件 | 存為檔案，需要時讀取 |
| ⚪ 噪音 | 無關的日誌、舊檔案 | 不要提供 |

#### 上下文卸載策略（Offload Context）
當對話變長時：
1. 將已完成的工作摘要寫入 `.ai-memory/context/session-YYYY-MM-DD.md`
2. 將參考資料存為專案文件，需要時再讀取
3. 開新對話時提供摘要，而非完整歷史

### 工具使用規範

#### 工具描述標準格式
每個工具/函式必須包含：
```
1. 功能說明：一句話描述這個工具做什麼
2. 輸入參數：每個參數的型別、格式、是否必填
3. 輸出格式：回傳值的結構與範例
4. 使用場景：什麼情況下該用這個工具
5. 錯誤處理：可能的錯誤情況與處理方式
```

#### 工具設計原則
- 每個工具只做一件事，保持單一職責
- 工具數量控制在 **10 個以內**，避免模型「選擇困難」
- 工具呼叫結果必須結構化回寫上下文

### 記憶管理規範（所有 AI 共用）

> ⚠️ **不要使用單一 PROGRESS.md**，中後期專案的單一檔案會膨脹到不可維護。

#### 短期記憶（當前會話）
- 在對話中維護一個 **工作狀態摘要**，每 3-5 步更新
- 格式：`✅已完成 / 🔄進行中 / ⏳待處理`

#### 長期記憶（跨會話、跨 AI）— `.ai-memory/` 目錄

`.ai-memory/` 是所有 AI 工具的**唯一共用記憶庫**。
任何 AI 寫入的決策/進度/問題，其他 AI 都必須讀取並遵守。

```
.ai-memory/
├── decisions/                   ← 架構決策（按主題 + 日期分檔）
│   ├── 2025-01-auth-strategy.md
│   ├── 2025-02-db-migration.md
│   └── _index.md                ← 決策索引（標題 / 日期 / 狀態）
├── progress/                    ← 開發進度（按模組分檔）
│   ├── frontend.md
│   ├── backend-api.md
│   ├── database.md
│   └── _index.md                ← 全域進度總覽
├── issues/                      ← 已知問題
│   ├── open.md                  ← 未解決問題
│   ├── resolved.md              ← 已解決（保留歷史參考）
│   └── _index.md
├── lessons/                     ← 情景記憶（經驗學習）
│   ├── _index.md                ← 經驗索引
│   └── YYYY-MM-主題.md          ← 個別經驗記錄
├── context/                     ← 上下文卸載暫存區
│   └── session-YYYY-MM-DD.md
├── architecture.md              ← 系統架構概觀
├── setup.md                     ← 環境設定
└── coding-standards.md          ← 開發規範
```

#### Skill 架構原則（強制）

> 完整開發規範請參閱 [`skills-development-guide.md`](./skills-development-guide.md)。

- **單一內核**：不為每個業務場景建立獨立 Agent，透過加載不同 Skills（技能包）擴展能力。
- **解耦連接與邏輯**：
  - MCP（連接層）：僅負責「能連上什麼」（資料庫、API），不涉及業務判斷。
  - Skills（邏輯層）：負責「怎麼把事做對」（SOP、業務規則、檢查點、回覆格式）。
- **漸進式加載（L1 → L2 → L3）**：
  - L1：系統啟動時僅加載 Skill 的 `name` 與 `description`（元數據預加載）。
  - L2：任務匹配時才讀取 `SKILL.md` 完整 SOP 與邊界條件。
  - L3：具體執行步驟需要時才觸發讀取 `reference.md` 或執行 `scripts/`。
- **確定性執行**：數值計算、排序、大規模格式化禁止模型直接推理，必須封裝腳本執行。
- **標準化結構**：每個 Skill 必須包含 `SKILL.md`（必需），可選 `reference.md`、`forms.md`/`templates.md`、`scripts/`。

#### 集中記憶與 Skill 觸發治理（建議，中大型專案強制）

- Skill 來源與記憶來源分離管理：
  - Skill 中央倉：`https://github.com/<org>/ai-skills`
  - Memory 中央倉：`https://github.com/<org>/ai-memory-hub`
- 每個專案保留本地 `.ai-memory/` 作為工作快取，但最終記錄需同步到 `ai-memory-hub`。
- `ai-memory-hub` 的同步分支建立 PR 後，預設必須自動合併；只有 PR 已 `merged` 才算同步完成。
- 若衝突只發生在 `projects/<owner>/<repo>/state/cases/index.json`，先同步最新 `main`、重建 case index、推回分支後再完成 merge。
- 記憶紀錄必須採 **append-only**：
  - 允許新增新事件
  - 禁止直接改寫既有事件內容
  - 若需更正，新增「更正事件」並指向原事件 ID
- 記錄格式至少包含：`event_id`、`project`、`module`、`timestamp`、`actor`、`outcome(success|failed)`、`summary`。
- 必記錄修復經驗：
  - `failed_cases`：嘗試過但失敗的方案與原因
  - `successful_cases`：最終可行解法、驗證方式與風險
- 新需求以「Skill 觸發」優先，不依賴手動提示詞：
  - 觸發前先做 memory preflight（讀歷史）
  - 變更後自動記錄 fix case（寫歷史）
  - 專案內按路徑分桶（例如 `projects/<repo>/<module>/events/*.jsonl`）

#### 情景記憶（Episodic Memory）— lessons/

記錄「做過什麼、結果如何」的經驗，讓 AI 從歷史中學習，避免重複犯錯：

```markdown
# lessons/2025-03-AG-Grid-佈局問題.md

## [2025-03-18 | Claude] AG Grid 使用 flex:1 導致高度塌陷
- ❌ 嘗試：對容器設 flex:1，結果 Grid 高度為 0
- ✅ 解法：改用 domLayout: 'autoHeight' + 移除 flex:1
- 📝 教訓：AG Grid 在彈性佈局中不能依賴父容器高度
- 🏷️ 標籤：AG-Grid, CSS, 佈局
```

觸發記錄的時機：
- 除錯超過 30 分鐘的問題 → 必須記錄
- 嘗試了 2 種以上方案才解決 → 記錄成功與失敗方案
- 發現框架/工具的隱藏陷阱 → 記錄避坑指南

#### 檔案管理規則
- 每個檔案 ≤ 150 行，超過則按子功能拆分
- `_index.md` 作為索引，只記標題與連結，不放完整內容
- 已解決的問題從 `open.md` 移到 `resolved.md`
- 季度清理：歸檔 3 個月以上的 context/ 檔案

### 程式碼規範
- 命名慣例：遵循專案所用語言/框架的社群標準（如 JavaScript 用 camelCase、Python 用 snake_case、PHP 用 PSR-4、Go 用 PascalCase/camelCase）
- 函式長度：建議 ≤ 50 行，超過則考慮拆分（依語言特性彈性調整）
- 檔案長度：建議 ≤ 500 行，超過則考慮模組化（專案可在 `AGENTS.local.md` 覆寫上限）
- 巢狀層級 ≤ 3 層，超過則提取函式
- 每個 `try-catch` 都要有實際的錯誤處理，禁止空 catch
- 註解語言、額外風格規範：依專案 `AGENTS.local.md` 定義

---

## 🤝 跨 AI 協作規範

> 本專案可能由多個 AI 工具（Codex CLI、Claude Code、Gemini CLI、Antigravity IDE、Copilot 等）交替編輯。
> 以下規範確保不同 AI 之間的工作可無縫銜接。

### 規則繼承架構
```
AGENTS.md（本檔案 — 共用核心）
  ↑ 繼承          ↑ 繼承         ↑ 繼承            ↑ 繼承
CLAUDE.md        CODEX.md       GEMINI.md         ANTIGRAVITY.md
（Claude）       （Codex）       （Gemini）        （Antigravity）
```

- **共用規則** 統一在 AGENTS.md 定義，工具專屬檔案不得重複
- **衝突時** 以 AGENTS.md 為準，除非工具專屬檔案有明確的覆寫說明
- 每個 AI 啟動時，必須 **先讀取 AGENTS.md**，再讀取自己的專屬檔案

### 記憶寫入統一格式

所有寫入 `.ai-memory/` 的記錄必須標注 **來源 AI** 和 **時間戳**：

```markdown
## 進度記錄格式
- [2025-03-15 | Claude] 完成認證模組 API 端點（/api/auth/login, /register）
- [2025-03-16 | Gemini] 修復登入表單驗證 Bug（issue #12）
- [2025-03-17 | Codex] 新增密碼強度檢查元件
- [2025-03-18 | Antigravity] 修正 IDE 任務模板初始化流程

## 決策記錄格式
### [2025-03-15 | Claude] 選擇 JWT 而非 Session
- 原因：前後端分離架構，不適合 Session
- 影響：需安裝 jsonwebtoken 套件
- 狀態：✅ 已執行
```

### AI 切換交接清單

切換到另一個 AI 工具前，當前 AI **必須完成**：

```
交接前必做：
  1. ✅ 更新 .ai-memory/progress/ 對應模組的進度
  2. ✅ 寫入 .ai-memory/context/session-YYYY-MM-DD.md（當前狀態摘要）
  3. ✅ 新發現的問題記入 .ai-memory/issues/open.md
  4. ✅ 未完成的工作明確標記 🔄 並說明下一步
```

### 新 AI 接手時的啟動流程

```
新 AI 啟動時必做：
  1. 📖 讀取 AGENTS.md（共用規則）
  2. 📖 讀取自己的專屬規則檔（CLAUDE.md / CODEX.md / GEMINI.md / ANTIGRAVITY.md）
  3. 📖 讀取 .ai-memory/progress/_index.md（全域進度）
  4. 📖 讀取最新的 .ai-memory/context/session-*.md（前次上下文）
  5. 📖 檢查 .ai-memory/issues/open.md（未解決問題）
  6. 🔄 向使用者確認當前任務目標
```

### Skill 多環境對齊清單

- 當新增任何 skill，必須提供專案**實際使用的 AI 工具**的安裝與觸發文件。
- 建議至少覆蓋 2 種以上環境，確保跨 AI 可銜接。
- 可用的環境：`CLAUDE.md`、`CODEX.md`、`GEMINI.md`、`ANTIGRAVITY.md`。

### 禁止事項
- 🚫 各 AI 不得建立私有的記憶檔案（如 `.claude-memory/`、`.codex-memory/`、`.gemini-notes/`、`.antigravity-memory/`）
- 🚫 不得覆寫其他 AI 的決策記錄，只能追加或標記為「已廢棄」
- 🚫 不得修改 AGENTS.md 中的共用規則（需使用者許可）

---

## 🧪 階段三：後期驗證（VERIFICATION）

### 調試策略
```
1. 精確定位
   - 閱讀完整錯誤訊息
   - 確認錯誤發生的精確位置（檔案、行號）

2. 最小重現
   - 隔離出最小的錯誤重現範例
   - 排除無關變數

3. 根本原因
   - 用二分法快速縮小範圍
   - 區分「症狀」和「原因」

4. 最小修復
   - 只修改導致問題的程式碼
   - 不要趁機重構

5. 驗證 + 記錄
   - 確認修復成功
   - 更新 .ai-memory/issues/（open → resolved）
```

### 評估標準
- ✅ 功能是否正確完成預期行為？
- ✅ 錯誤情況是否有合理的處理？
- ✅ 程式碼是否可讀、可維護？
- ✅ 是否有不必要的複雜度可以移除？

### 量化評估指標

每個任務完成後，AI 應在 `.ai-memory/progress/` 中記錄以下指標：

| 指標 | 目標 | 說明 |
|------|------|------|
| 首次正確率 | > 70% | 不需要修正的任務比例 |
| 迭代次數 | ≤ 3 次 | 從開始到完成的來回修改次數 |
| 回歸問題 | 0 | 修改後導致的新 Bug 數量 |
| 影響範圍準確度 | 100% | 預估修改檔案 vs 實際修改檔案的吻合度 |

當指標不達標時，應記錄原因到 `lessons/` 並調整後續策略。

## 🧭 工程師交付節奏（PR、CI、預覽）

> 以下為通用 PR 流程規範。分支命名、預覽網址、驗證端點等專案特定設定，請定義在 `AGENTS.local.md`。

- 任何功能修正先在 feature branch 開發（建議命名格式：`ai/<工程師>/<任務>`，或依專案慣例）。
- 開發前先完成分支預覽規劃：確認可回歸頁面與 API。
- 先在預覽環境完成自我驗證，經審核者核准後才提交合併。
- 每個專案都必須在 `AGENTS.local.md` 宣告 preview 契約，至少包含：`preview_mode`、`preview_base_url` 或 `preview_url_template`、branch/slug 規則、目標頁回報規則、以及 preview 必測端點。
- Canonical preview 必須是專案可重現、可持續的 URL，且應部署在專案自有的 preview/staging host 或受控的隔離路徑；不得把 `ngrok`、`localtunnel`、`localhost.run` 之類臨時 tunnel 當成 merge gate 的正式 preview。
- 若專案尚未具備穩定 preview，`AGENTS.local.md` 必須明確標示暫行 fallback（例如截圖、artifact、手動 smoke）與對應的追蹤 change / task，不能只口頭宣稱「目前沒有 preview」。
- 每次修改完成回報（含中間交付）都必須附上「合併前預覽網址」。
- 任何非 trivial 的 PR，必須能對應到正式 GitHub issue；該 issue 原則上必須屬於明確 milestone。
- labels 用來標記類型（如 `bug`、`docs`、`incident`），milestone 用來定義交付批次，兩者不可互相替代。
- 若 issue 尚未掛 milestone，AI 在提交 PR 前必須主動提醒補建或說明為何屬於例外。
- PR 審核前必填：變更摘要、風險評估、最小驗證步驟與結果、回滾方案。
- CI 需通過所有檢查；一旦失敗，禁止宣告可發佈。
- 每次 PR（含更新 commit 後）都必須保持 required checks 全綠；任一檢查非綠燈時，禁止宣告完成、禁止請求合併。
  - 「全綠」只接受 required checks 為 `success`；`expected`、`pending`、`neutral`、`skipped`、`cancelled` 一律視為未通過。
  - PR 必須可合併且無衝突；若出現 `Checks awaiting conflict resolution` 或 `mergeStateStatus=DIRTY`，必須先解衝突。
  - 若 ruleset 啟用 strict required checks，分支落後目標分支時，必須先 update branch（merge/rebase）再重跑 required checks。
  - required review/approval 與 unresolved conversations 也屬於合併必要門檻，任一未達標皆不可宣告完成。
- 若 milestone 尚未達到完成定義，禁止單憑單一 PR 通過就宣告整批交付完成。

## 🔒 新專案主線保護（強制落地）

> 以下為每個新專案上線前的「必做技術鎖」，不可只靠口頭規範。
> 組織名稱、主線名稱、CI check 名稱等專案特定值，請定義在 `AGENTS.local.md`。

### 組織層（一次性設定）
- 私有 repo 若要平台強制主線保護，至少使用 GitHub Team 方案。
- 工程師與 AI 不得共用管理者帳號、PAT 或 SSH 金鑰。
- 工程師角色預設為 `Write`，不得給 `Admin`；管理者才可進入 bypass 清單。
- 工程師需先加入為 `Organization member`，不能只停留在 `Outside collaborator`。
- 若組織啟用 fine-grained PAT 審核，管理者必須核准工程師 PAT request 後才可使用。

### Repo 層（每個新專案必做）
- 對主線建立 branch ruleset，且 `enforcement=active`。
- 必須啟用：`Restrict updates`、`Restrict deletions`、`Require a pull request before merging`、`Block force pushes`。
- 必須設定 required status checks（至少 1 個正式 CI 檢查）。
- 建議啟用 `strict required status checks`（分支需與目標分支最新狀態同步驗證）。
- 規則建立後需實測：工程師直推主線必須失敗、推 feature branch 必須成功。

### 驗收與交付（每次新專案啟動時都要做）
- 用工程師帳號驗證：`git push origin HEAD:<主線>` 必須被拒絕。
- 建立 PR 驗證：未達 approval 數、或 required checks 未通過時，必須無法 merge。
- 僅在上述驗收完成後，才可宣告主線治理完成。

### Token 安全（強制）
- PAT 必須使用 fine-grained、最小權限、最短有效期。
- Token 不得出現在對話、文件、commit；若外洩需立即 `revoke + rotate`。
- 完整流程與逐步操作細節請參考：`github-project-lifecycle-sop.md`。

---

## 🚫 邊界規則

### ✅ ALWAYS（永遠要做）
- 修改前先理解現有程式碼的邏輯
- 保存修改前的備份或使用版本控制
- 每次修改後驗證功能是否正常
- 提供清楚的修改說明
- 用最簡單的方案解決問題
- 寫入 `.ai-memory/` 時標注 AI 來源與時間

### ⚠️ ASK FIRST（先問再做）
- 刪除現有檔案或大段程式碼
- 引入新的框架或依賴
- 修改資料庫結構
- 修改認證/授權邏輯
- 變更 API 的公開介面
- 重構超過 3 個檔案的架構
- 修改 AGENTS.md 中的共用規則

### 🚫 NEVER（絕對不做）
- 不在程式碼中硬編碼密碼、金鑰、Token
- 不刪除 `.env`、`.gitignore` 等設定檔
- 不修改不相關的檔案（保持最小變更範圍）
- 不在沒有理解問題的情況下「猜測修復」
- 不一次性重寫整個系統（漸進式修改）
- 不忽略錯誤處理（不要用空的 catch）
- 不建立 AI 私有記憶檔（統一用 `.ai-memory/`）
- 不覆寫其他 AI 的決策記錄

---

## 📁 專案文件結構建議

```
專案根目錄/
├── AGENTS.md              ← 本檔案（共用核心規則）
├── CLAUDE.md              ← Claude Code 專屬擴展
├── CODEX.md               ← Codex CLI 專屬擴展
├── GEMINI.md              ← Gemini CLI 專屬擴展
├── ANTIGRAVITY.md         ← Antigravity IDE 專屬擴展
├── skills-development-guide.md ← Skill 開發規範指南（架構、結構、加載、執行、安全）
├── skills-memory-standard.md ← skill 與集中記憶治理規範
├── .ai-dev-standard.json  ← 自動同步元數據（來源、版本、時間）
├── *.local.md             ← 專案專屬覆寫（不被同步覆蓋）
├── .ai-memory/            ← 所有 AI 共用記憶庫
│   ├── decisions/         ← 架構決策（按主題分檔）
│   ├── progress/          ← 開發進度（按模組分檔）
│   ├── issues/            ← 已知問題追蹤
│   ├── context/           ← 上下文卸載暫存
│   ├── architecture.md
│   ├── setup.md
│   └── coding-standards.md
└── src/                   ← 原始碼
```

---

## 🔄 標準自動同步

本檔案由中央 repo 自動同步，**請勿直接修改**。

### 專案專屬覆寫機制

若專案需要專屬設定（如 DB 連線、專案架構說明），請建立對應的 `.local.md` 檔案：

| 中央檔案（自動同步） | 專案覆寫檔案（手動維護） |
|---------------------|------------------------|
| `AGENTS.md` | `AGENTS.local.md` |
| `CLAUDE.md` | `CLAUDE.local.md` |
| `CODEX.md` | `CODEX.local.md` |
| `GEMINI.md` | `GEMINI.local.md` |
| `ANTIGRAVITY.md` | `ANTIGRAVITY.local.md` |

> **所有 AI 啟動時必須檢查**：若專案根目錄存在對應的 `.local.md` 檔案，**必須一併讀取**，其內容為本專案的專屬覆寫，優先於中央版本。

### 同步設定

同步元數據存於 `.ai-dev-standard.json`，由同步腳本自動維護。

同步方式：
1. **GitHub Action**：每週自動檢查並建立 PR
2. **Git Hook**：每次 `git pull` 後提示是否有更新
3. **手動執行**：`bash .github/scripts/sync-ai-standard.sh`

### 啟用同步

- **新專案**：執行 `init-project.sh` 自動啟用
- **既有專案**：執行 `enable-sync.sh` 一鍵啟用

---

## 🔄 本文件維護

本文件是**動態文件**，應隨專案演進持續更新：
- 發現新的常見錯誤 → 加入 NEVER 規則
- 找到有效的開發模式 → 加入 ALWAYS 規則
- 專案技術棧變更 → 更新程式碼規範
- 修改本文件需使用者許可，因為會影響所有 AI 工具
- ⚠️ 修改應在**中央 repo** 進行，再由同步機制分發到各專案
