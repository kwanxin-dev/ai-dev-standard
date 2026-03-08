# AI Agent Skills 開發規範指南

> 定義 Skill 的架構理念、資料夾結構、漸進式加載機制、確定性執行規範、跨工具實現建議，以及安全與治理規範。

---

## 一、核心架構理念：從「造人」轉向「手冊」

### 單一內核原則

不要為每個業務場景建立獨立的 Agent。應保留一個具備高 IQ 的通用 Agent 內核，透過加載不同的 **Skills（技能包）** 來擴展專業能力。

### 解耦連接與邏輯

| 層級 | 職責 | 範例 |
|------|------|------|
| **MCP（連接層）** | 僅負責「能連上什麼」 | MSSQL 資料庫、CRM API、檔案系統 |
| **Skills（邏輯層）** | 負責「怎麼把事做對」 | SOP、業務規則、檢查點、回覆格式 |

> MCP 不涉及業務判斷，Skills 不涉及連線細節。兩者嚴格分離。

---

## 二、標準化技能資料夾結構

每個 Skill 應作為一個獨立模組存儲，遵循以下目錄結構：

```
skills/
  <skill-name>/
    ├── SKILL.md              ← (必需) 技能核心說明書
    ├── reference.md          ← (可選) 補充資料、API 參考或業務知識庫
    ├── forms.md              ← (可選) 輸入表單規範
    ├── templates.md          ← (可選) 輸出回覆模板
    └── scripts/              ← (可選) 確定性執行腳本
        ├── calculate.py
        ├── format.sh
        └── ...
```

### 各檔案職責

| 檔案 | 必要性 | 職責 |
|------|--------|------|
| `SKILL.md` | **必需** | 技能元數據（name、description）+ 完整工作流程（SOP）+ 適用/不適用場景 |
| `reference.md` | 可選 | 補充資料、API 參考文件、業務知識庫 |
| `forms.md` / `templates.md` | 可選 | 定義輸入表單規範或輸出的回覆模板 |
| `scripts/` | 可選 | Python 或 Shell 腳本，用於執行高確定性任務（數據過濾、格式轉換、複雜計算） |

### SKILL.md 最小結構範例

```markdown
# Skill: <skill-name>

## 元數據
- **name**: <skill-name>
- **description**: 一句話描述此技能的功能
- **version**: 1.0
- **author**: <author>

## 適用場景
- 場景 A：...
- 場景 B：...

## 不適用場景
- 場景 X：...（應改用 <other-skill>）
- 場景 Y：...

## 工作流程（SOP）
### Step 1: ...
### Step 2: ...
### Step 3: ...

## 邊界條件
- 條件 A 時應 ...
- 超過 N 時須轉人工
```

---

## 三、漸進式披露加載規範（L1 → L2 → L3）

為優化 Token 成本與推理精準度，調度邏輯必須遵循以下三層加載：

```
┌─────────────────────────────────────────────────────┐
│ L1 元數據預加載（系統啟動時）                          │
│   → 僅加載 Skill 的 name 與 description               │
│   → 模型以此判斷是否需要該技能                         │
├─────────────────────────────────────────────────────┤
│ L2 執行指南加載（任務匹配時）                          │
│   → 讀取 SKILL.md 中的完整 SOP 與邊界條件              │
│   → 模型依據 SOP 規劃執行步驟                          │
├─────────────────────────────────────────────────────┤
│ L3 配套資源調用（具體執行步驟需要時）                   │
│   → 觸發讀取 reference.md                             │
│   → 執行 scripts/ 中的腳本                             │
│   → 載入 forms.md / templates.md                       │
└─────────────────────────────────────────────────────┘
```

### 加載時機判斷

| 層級 | 觸發條件 | 加載內容 | Token 成本 |
|------|---------|---------|-----------|
| L1 | 系統啟動 | name + description | 極低 |
| L2 | 任務匹配到 Skill | SKILL.md 完整內容 | 中等 |
| L3 | SOP 步驟需要參考資料或執行腳本 | reference.md / scripts/ | 按需 |

> **原則**：不要在 L1 階段就加載所有 Skill 的完整內容，這會浪費 Token 並干擾模型判斷。

---

## 四、確定性執行規範

### 計算與格式化轉移

涉及以下任務時，**禁止**讓模型直接推理，必須封裝腳本執行：

- 數值計算（金額、稅率、統計）
- 排序（多欄位排序、自定義排序規則）
- 大規模數據格式化（批量轉換、報表生成）
- 正規表達式匹配與替換
- 日期計算與格式轉換

### 職責分工

```
模型（AI）                          腳本（Scripts）
  ├── 理解需求                        ├── 數值計算
  ├── 決策與規劃                      ├── 數據排序
  ├── 選擇執行路徑                    ├── 格式轉換
  ├── 組裝最終回覆                    ├── 正則匹配
  └── 處理異常與用戶溝通              └── 批量處理
       ↓                                   ↓
  「什麼時候做、做什麼」             「怎麼做、精確執行」
```

### 腳本規範

- 腳本必須有明確的輸入輸出格式（JSON 優先）
- 腳本必須有錯誤處理，回傳結構化錯誤訊息
- 腳本執行結果回傳模型後，由模型生成最終回覆

---

## 五、跨工具實現建議（Implementation Mapping）

根據不同 AI 工具的特性，Skill 概念的對應實現方式：

| 概念層級 | Codex / Cursor | Claude (Anthropic) | Gemini / CLI |
|---------|----------------|-------------------|-------------|
| **Skill 核心指令** | `.cursorrules` 文件 | `SKILL.md`（原生支持） | System Instructions / Workflow |
| **連接外部數據** | MCP Server / API | MCP Server | Tools / Function Calling |
| **業務 SOP** | 規則文件中的流程定義 | `SKILL.md` 流程章節 | 結構化 Prompt 流程 |
| **確定性腳本** | 項目內的 Python 腳本 | 腳本調用（Scripts） | Code Execution / Scripts |
| **記憶管理** | `.ai-memory/` | `.ai-memory/` | `.ai-memory/` |

### 各工具安裝路徑

| 工具 | 預設安裝路徑 | 環境變數覆寫 |
|------|-------------|-------------|
| Claude | `$HOME/.claude/skills/` | `CLAUDE_SKILLS_DIR` |
| Codex | `$HOME/.codex/skills/` | `CODEX_SKILLS_DIR` |
| Gemini | `$HOME/.gemini/skills/` | `GEMINI_SKILLS_DIR` |
| Antigravity | `$HOME/.antigravity/skills/` | `ANTIGRAVITY_SKILLS_DIR` |

---

## 六、安全與治理規範

### 邊界定義（強制）

每個 `SKILL.md` **必須**明確定義：

```markdown
## 適用場景
- [明確列出此 Skill 處理的場景]

## 不適用場景
- [明確列出此 Skill 不應處理的場景]

## 硬性邊界
- 嚴禁揭露金額資訊（若適用）
- 超過 N 天未處理須轉人工（若適用）
- 不得自動執行刪除/修改資料庫操作（若適用）
```

### 版本管理（強制）

- 所有 Skills 必須納入 **Git 版本控制**
- SOP 的變更必須可審計、可回滾
- 重大變更需透過 PR 審核

### 執行審計（強制）

系統需具備觀測性，記錄以下資訊：

```json
{
  "timestamp": "2026-03-08T10:30:00Z",
  "actor": "claude",
  "skill": "memory-hub-sync",
  "action": "append-event",
  "project": "org/repo-name",
  "outcome": "success",
  "summary": "同步 3 筆事件到 memory hub"
}
```

### 治理檢查清單

- [ ] `SKILL.md` 包含元數據（name、description、version）
- [ ] `SKILL.md` 定義適用場景與不適用場景
- [ ] 數值計算相關邏輯已封裝為腳本
- [ ] Skill 已納入 Git 版本控制
- [ ] 四環境（Claude / Codex / Gemini / Antigravity）均有安裝步驟
- [ ] 執行動作有審計記錄

---

## 與本專案其他規範的關係

| 文件 | 關係 |
|------|------|
| `AGENTS.md` | 共用核心規則，定義 Skill 觸發與記憶治理的基本原則 |
| `skills-memory-standard.md` | 集中記憶治理標準，定義 `ai-memory-hub` 與事件格式 |
| **本文件** | Skills 開發的完整規範，涵蓋架構、結構、加載、執行、安全 |
| `CLAUDE.md` / `CODEX.md` / `GEMINI.md` / `ANTIGRAVITY.md` | 各工具的 Skill 安裝與觸發擴展 |
