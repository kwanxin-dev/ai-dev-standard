# CODEX.md — Codex CLI 專屬擴展規則
# 適用於：Codex CLI / Codex Agent
# 版本：1.0
#
# 📌 本檔案繼承 AGENTS.md 的所有共用規則。
# 以下僅定義 Codex 專屬流程。

---

## 📖 啟動流程

每次 Codex 啟動新任務時：
1. 讀取 **AGENTS.md**（共用規則）
2. 讀取 **本檔案**（Codex 專屬擴展）
3. 執行 `memory-hub-sync` 的 preflight（先讀歷史）
4. 讀取 `.ai-memory/progress/_index.md` 與最新 `context/session-*.md`

---

## 🔨 Codex 專屬執行規範

### Skill 優先觸發
- 有對應 skill 時，優先走 skill 腳本，不依賴手動提示詞。
- 任務完成後，必須回寫成功/失敗案例到 `ai-memory-hub`。
- `ai-memory-hub` PR 建立後預設要自動 merge；若只在 `state/cases/index.json` 衝突，先更新分支並重建 index 再 merge。

### 變更策略
- 優先採用最小變更，避免同時改動不相干模組。
- 需要修改多檔案時，先列出影響範圍再執行。

### Commit 與記錄一致性
- commit 摘要需可對應到 memory event 的 `summary`。
- 若修復失敗，仍需寫入 `failed_cases`，不得略過。

---

## 🧪 Codex 驗收補充

- [ ] 任務前已執行 preflight
- [ ] 任務後已追加事件（success 或 failed）
- [ ] 事件已同步到 `ai-memory-hub` 且 PR 已 merged
