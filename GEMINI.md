# GEMINI.md — Gemini CLI 專屬擴展規則
# 適用於：Gemini CLI / Google AI Studio / Gemini Code Assist
# 版本：2.0 | 基於《那些 Agent 神文沒告訴你的事》實操方法論
#
# 📌 本檔案繼承 AGENTS.md 的所有共用規則。
# 以下僅定義 Gemini 特有的能力優化與工作流程。
# 共用規則（記憶管理、程式碼規範、GitHub issue / milestone / PR 治理、邊界規則、跨 AI 協作）請參閱 AGENTS.md。

---

## 📖 啟動流程

每次 Gemini 啟動新對話時：
1. 讀取 **AGENTS.md**（共用規則）
2. 讀取 **本檔案**（Gemini 專屬擴展）
3. 讀取 `.ai-memory/progress/_index.md`（全域進度）
4. 讀取最新的 `.ai-memory/context/session-*.md`（前次狀態）
5. 檢查 `.ai-memory/issues/open.md`（未解決問題）
6. 確認本次工作對應的 GitHub 規劃容器：
   - issue 是什麼
   - milestone 是什麼
   - 若已有 PR，是否仍與該 issue / milestone 一致

---

## 🔌 必裝 Skill（memory）

- 必裝 skill：`memory-hub-sync`
- 安裝命令（建議統一入口）：
  ```bash
  bash scripts/install-skill.sh --skill memory-hub-sync --targets claude,codex,gemini,antigravity
  ```
- 任務開始先跑 preflight（先讀歷史），任務結束追加事件並同步到 `ai-memory-hub`。
- `ai-memory-hub` PR 建立後預設要自動 merge；若只在 `state/cases/index.json` 衝突，先更新分支並重建 index 再 merge。
- 詳細治理規格請參考 `skills-memory-standard.md`。

---

## 🔨 Gemini 專屬能力

### 分層指令架構

Gemini 支援三層指令體系，從高到低依次為：

```
第 1 層：全局規則（AGENTS.md + 本檔案）
  └── 適用於所有任務的基礎行為規範

第 2 層：模組規則（各子目錄的 .gemini/ 設定）
  └── 針對特定模組的技術規範與慣例

第 3 層：任務規則（對話中的即時指令）
  └── 針對當前任務的特殊要求
```

**優先級**：第 3 層 > 第 2 層 > 第 1 層（就近原則）
**注意**：第 1 層中若 AGENTS.md 與本檔案衝突，以 AGENTS.md 為準；GitHub 規劃治理不得在下層規則中被削弱或繞過。

### 架構決策框架

每個新任務開始前，用以下框架快速評估：

```markdown
## 任務評估單

### 1. 問題定義
- 要解決的問題：___
- 預期結果：___
- 成功標準：___

### 2. 複雜度評估
- 影響檔案數：[ ] 1-2 個  [ ] 3-5 個  [ ] 6+ 個
- 是否涉及資料庫：[ ] 是  [ ] 否
- 是否涉及外部 API：[ ] 是  [ ] 否

### 3. 風險評估
- 可能的副作用：___
- 回退方案：___
```

### 多模態能力運用

Gemini 支援理解圖片、影片、音檔，善用此能力：
- **UI 問題**：截圖 + 描述預期行為，比純文字描述更精確
- **錯誤畫面**：直接提供螢幕截圖
- **設計稿**：提供 Figma/設計圖，直接轉換為程式碼
- **流程圖**：提供手繪或工具繪製的流程圖作為架構參考

### 工具描述品質標準

Gemini 對工具描述格式特別敏感，使用 YAML 模板：
```yaml
tool_name: search_items
description: |
  在資料庫中搜尋符合條件的項目。
  支援模糊搜尋和精確匹配。
parameters:
  keyword:
    type: string
    required: true
    description: 搜尋關鍵字
    example: "example-keyword"
  category:
    type: string
    required: false
    description: 類別篩選
    enum: [category_a, category_b, category_c]
  max_results:
    type: integer
    required: false
    default: 20
    description: 最大回傳筆數
returns:
  type: array
  items:
    - id: 項目編號
    - name: 項目名稱
    - status: 狀態
errors:
  - code: NO_RESULTS
    description: 找不到符合條件的項目
  - code: INVALID_CATEGORY
    description: 類別名稱不在允許範圍內
usage_scenario: |
  當使用者要查詢項目資訊時使用。
  不適用於修改項目資料（請改用 update_item）。
```

#### 工具管理補充
- 同一任務啟用的工具 ≤ 8 個
- 每個工具的描述 ≤ 200 字
- 工具之間不應有功能重疊
- 危險操作的工具需要確認機制

---

## 🧪 Gemini 專屬驗證

### 效能追蹤指標
| 指標 | 目標 | 量測方式 |
|------|------|---------|
| 任務完成率 | > 90% | 成功完成的任務 / 總任務數 |
| 首次正確率 | > 70% | 不需要修正的任務比例 |
| 平均迭代次數 | < 3 次 | 從開始到完成的對話輪數 |
| 回歸問題 | 0 | 修改後導致的新 Bug |

### 交付治理補充

- 回報進度時，除任務內容外，還要同步回報 milestone 完成度、剩餘 open issues 與主要阻塞。
- 若任務評估後發現工作實際超出原 milestone，必須先回報並要求重新規劃，不得默默擴張交付範圍。

### 上下文壓縮策略（Gemini 專屬）

Gemini 的上下文窗口較大但仍需管理：
- 對話超過 15 輪時，按 AGENTS.md 規範卸載至 `.ai-memory/context/`
- 依據任務類型動態組裝上下文（見 AGENTS.md 資訊品質分級）

---

## 📁 Gemini 專屬目錄設定

```
.gemini/               ← Gemini 分層設定（第 2 層）
└── rules/
    ├── frontend.md    ← 前端模組專用規則
    ├── backend.md     ← 後端模組專用規則
    └── testing.md     ← 測試專用規則
```

> ⚠️ `.gemini/rules/` 中的規則僅供 Gemini 使用。
> 如需所有 AI 共用的規則，請寫入 AGENTS.md。
