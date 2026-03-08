# 🤖 AI Agent 專案預設規則

> 為 AI 編程助手打造的專案預設規則集。

---

## 📌 這是什麼？

一套可直接複製到任何新專案根目錄的 **AI 編程助手規則檔案**，讓 Codex CLI、Claude Code、Gemini CLI、Antigravity IDE、GitHub Copilot 等工具在開發時自動遵循統一的工作規範。

### 核心理念
- 🎯 **問題導向** — 從最小可行方案開始，拒絕過度設計
- 🧠 **上下文工程** — 精準管理 AI 的上下文窗口，提升輸出品質
- 🔄 **跨 AI 協作** — 不同 AI 工具可無縫交接同一個專案
- 📁 **目錄化記憶** — 使用 `.ai-memory/` 取代單一檔案，適應大型專案

---

## 📂 檔案結構

```
本目錄/
├── README.md                          ← 本文件
├── AGENTS.md                          ← 共用核心規則（Single Source of Truth）
├── CLAUDE.md                          ← Claude Code 專屬擴展
├── CODEX.md                           ← Codex CLI 專屬擴展
├── GEMINI.md                          ← Gemini CLI 專屬擴展
├── ANTIGRAVITY.md                     ← Antigravity IDE 專屬擴展
├── skills-development-guide.md         ← Skill 開發規範指南（架構/結構/加載/執行/安全）
├── skills-memory-standard.md          ← Skill + ai-memory-hub 治理標準草案
├── 新專案開發流程規範.html              ← 開發流程規範（HTML 視覺化版）
├── github-project-lifecycle-sop.md    ← GitHub 權限/PR/合併完整 SOP（實戰版）
├── 為什麼這樣規劃_設計理念說明.html      ← 規則設計理念與背景知識
├── init-project.sh                    ← 一鍵初始化腳本（Linux/Mac）
├── init-project.ps1                   ← 一鍵初始化腳本（Windows）
└── example-project/                   ← 範例專案模板（可直接複製使用）
```

### 規則繼承架構

```
AGENTS.md（共用核心）
  ↑ 繼承          ↑ 繼承         ↑ 繼承            ↑ 繼承
CLAUDE.md        CODEX.md       GEMINI.md         ANTIGRAVITY.md
（Claude 專屬）  （Codex 專屬） （Gemini 專屬）   （Antigravity 專屬）
```

| 檔案 | 角色 | 內容 |
|------|------|------|
| **AGENTS.md** | 共用核心 | 需求決策樹、上下文工程、`.ai-memory/` 記憶管理、程式碼規範、邊界規則、跨 AI 協作規範 |
| **CLAUDE.md** | 擴展 | 長上下文策略、子任務委派、結構化回寫、Prompt 迭代法 |
| **CODEX.md** | 擴展 | Skill 優先觸發、最小變更策略、記憶回寫一致性 |
| **GEMINI.md** | 擴展 | 分層指令架構、多模態運用、YAML 工具描述模板、效能追蹤指標 |
| **ANTIGRAVITY.md** | 擴展 | IDE 任務啟動檢查、Skill 安裝檢核、記憶追溯要求 |
| **skills-development-guide.md** | 開發規範 | Skill 架構理念、資料夾結構、漸進式加載(L1→L2→L3)、確定性執行、跨工具映射、安全治理 |
| **skills-memory-standard.md** | 治理 | Skill 中央倉 + 記憶中央倉、append-only、成功/失敗案例記錄 |

---

## 🚀 使用方式

### 方法 1：複製範例專案（最快）

```bash
cp -r example-project/ /path/to/your/new-project/
```

### 方法 2：一鍵初始化腳本

```bash
# Linux / Mac
cd /path/to/your/new-project/
bash /path/to/Agent指南/init-project.sh

# Windows PowerShell
cd C:\path\to\your\new-project
.\init-project.ps1
```

腳本會自動建立：`.ai-memory/` 目錄結構、`.github/workflows/ci.yml`、`CODEOWNERS`、`.gitignore`，並**自動下載 AI 開發標準檔案 + 啟用自動同步**。

### 方法 3：既有專案啟用自動同步

```bash
# 在既有專案根目錄執行（會自動備份現有檔案為 *.local.md）
curl -sL https://raw.githubusercontent.com/<your-org>/ai-dev-standard/main/enable-sync.sh | bash
```

### 方法 4：手動設定

1. 將 `AGENTS.md`、`CLAUDE.md`、`CODEX.md`、`GEMINI.md`、`ANTIGRAVITY.md` 複製到你的專案根目錄
2. 建立 `.ai-memory/` 目錄結構（參考 AGENTS.md）
3. AI 工具啟動時會自動讀取對應的規則檔

### 搭配不同 AI 工具

| AI 工具 | 會讀取的檔案 |
|---------|-------------|
| **Codex CLI** | AGENTS.md → CODEX.md → `*.local.md` → `.ai-memory/` |
| **Claude Code** | AGENTS.md → CLAUDE.md → `CLAUDE.local.md` → `.ai-memory/` |
| **Gemini CLI** | AGENTS.md → GEMINI.md → `*.local.md` → `.ai-memory/` |
| **Antigravity IDE** | AGENTS.md → ANTIGRAVITY.md → `*.local.md` → `.ai-memory/` |
| **GitHub Copilot / Cursor** | AGENTS.md → `*.local.md` → `.ai-memory/` |

### 🔄 自動同步機制

啟用後，專案會自動與中央 repo 保持同步：

| 觸發方式 | 時機 | 行為 |
|---------|------|------|
| **GitHub Action** | 每週一凌晨 | 自動建立 PR（不直推主線） |
| **Git Hook** | 每次 `git pull` | 提示是否有新版本 |
| **手動** | 隨時 | `bash .github/scripts/sync-ai-standard.sh` |

**專案專屬設定**不會被覆蓋 — 使用 `*.local.md` 檔案（如 `CLAUDE.local.md`）存放專案特有的設定。

---

## 📋 涵蓋的專案生命週期

### 前期規劃（PLANNING）
- 需求評估決策樹（API → Workflow → Agent → 混合架構）
- System Prompt 迭代法（3-5 條 → 觀察 → 精煉）

### 中期開發（DEVELOPMENT）
- 上下文工程（資訊品質分級、卸載策略）
- 工具描述標準格式
- `.ai-memory/` 目錄化記憶管理
- Skill 觸發流程與 `ai-memory-hub` 集中同步（append-only）

### 後期驗證（VERIFICATION）
- 除錯 SOP（精確定位 → 最小重現 → 根因 → 最小修復）
- Always / Ask First / Never 邊界規則

### 跨 AI 協作
- 統一記憶寫入格式（`[日期 | AI名]` 標注）
- AI 切換交接清單
- 新 AI 啟動流程

## 🧭 工程師實作與交付流程（PR/CI 版）
- 以 `ai/<工程師>/<任務>` 分支開發，不直接在 `主線分支` 上提交。
- 每次提交前先補齊需求理解、最小影響檢查，並完成本地 build / 功能 smoke。
- 每個分支必須先完成 `preview` 自我驗證後再提 PR。
- 預覽網址規則（`ai/<engineer>/<task>`）：`https://<your-staging-domain>/p/<engineer>/<task>/`。
- 確認項目至少包含登入與授權 API（`/api/auth/me`, `/api/auth/login`）回應正常、目標頁面主流程可載入、主要 API（例如 `GET /api/stock/movements`）不再回 500，以及新增或變更功能可重複操作且不殘留舊快取錯誤。
- 每次修改完成回報（含中間交付）必須附上「合併前預覽網址」，且只需提供本次修改目標頁（若有指定單號/ID 需附完整路徑）。
- 除非使用者另外要求，不需主動提供分支入口、列表頁或模組首頁預覽網址。
- 所有 preview 變更先回報 PM，由 PM 回覆「可上線」後才進入合併流程。
- PR 建立時務必附上變更摘要、風險、回退方案、影像或截圖證據、測試步驟與結果（包含 smoke/healthcheck）。
- PR 必須通過 CI（含部署健康檢查）才可合併到 `主線分支`。
- 每次 PR（含更新 commit 後）都必須維持 required checks 全綠；任一檢查非綠燈時，禁止宣告完成、禁止請求合併。
  - required checks 只接受 `success`；`expected`/`pending`/`neutral`/`skipped`/`cancelled` 均視為未通過。
  - PR 必須無衝突且可合併（若顯示 `Checks awaiting conflict resolution` 則先解衝突）。
  - required approvals 與 unresolved conversations 必須達標，且 strict required checks 專案需先同步分支再重跑檢查。
- 不得在 `deploy/healthcheck failed` 未修正前發佈到正式或繼續宣告完成。
- 合併後以 staging 實際觀測結果覆核一次，作為版本收斂前最後回路。

### 📋 新專案開發流程
- 完整的開新專案 SOP（Repo → 開發端 → CI/CD → 伺服端 → 驗收）
- 多工程師協作（分支策略、衝突預防、小 PR 原則）
- AI 第一關 Review + 老闆最終 Approve 的雙層審核
- 詳見：[新專案開發流程規範.html](./新專案開發流程規範.html)
- GitHub 權限與合併實戰 SOP（開新專案 → 工程師加入 → 提交修改 → 管理者合併）：[github-project-lifecycle-sop.md](./github-project-lifecycle-sop.md)

---

## ⚙️ 自訂與擴展

### 修改共用規則
編輯 `AGENTS.md`，所有 AI 工具都會遵循更新後的規則。

### 新增 AI 工具支援
建立新的擴展檔（如 `COPILOT.md`），開頭聲明繼承 AGENTS.md：
```markdown
# 📌 本檔案繼承 AGENTS.md 的所有共用規則。
# 以下僅定義 [工具名稱] 特有的能力優化。
```

### 調整記憶目錄
依據專案規模調整 `.ai-memory/` 的子目錄結構，但保持 `_index.md` 索引機制。

### Skill 開發與治理
- **開發規範**：依 [`skills-development-guide.md`](./skills-development-guide.md) 建立 Skill，遵循單一內核原則、標準化資料夾結構、漸進式加載（L1→L2→L3）、確定性執行
- **記憶治理**：依 [`skills-memory-standard.md`](./skills-memory-standard.md) 建立集中記憶管理：
  - 獨立 skill 倉（`ai-skills`）
  - 獨立記憶倉（`ai-memory-hub`）
  - append-only 事件寫入與成功/失敗 case 留存

---

## 📄 授權

本規則集為開放使用，歡迎依據自身需求修改與分享。

## Verification
- Last verified: 2026-02-18 (Public Access Test)

