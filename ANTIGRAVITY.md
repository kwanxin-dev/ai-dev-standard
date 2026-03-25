# ANTIGRAVITY.md — Antigravity IDE 專屬擴展規則
# 適用於：Antigravity IDE Agent 環境
# 版本：1.0
#
# 📌 本檔案繼承 AGENTS.md 的所有共用規則。
# 以下僅定義 Antigravity 專屬流程。

---

## 📖 啟動流程

每次 Antigravity Agent 啟動任務時：
1. 讀取 **AGENTS.md**（共用規則）
2. 讀取 **本檔案**（Antigravity 專屬擴展）
3. 執行 `memory-hub-sync` preflight（先讀既有修復案例）
4. 完成任務後追加事件並同步到 `ai-memory-hub`，且同步 PR 預設要自動 merge

---

## 🔨 Antigravity 專屬規範

### IDE 任務與 Skill
- 專案若宣告必裝 skill，IDE 啟動後要先檢查安裝狀態。
- 若 skill 缺失，先完成安裝再進行功能修改。
- 若 `ai-memory-hub` PR 只在 `state/cases/index.json` 衝突，先更新分支並重建 index 再 merge。

### 協作與可追溯性
- 任何操作都要能對應到一筆 memory event。
- 記錄需標示 `actor=antigravity`，避免來源混淆。

### 失敗案例管理
- 測試失敗或修復回退時，必須立即追加 `failed_cases`。
- 修復完成再追加 `successful_cases`，不可覆蓋原失敗紀錄。

---

## 🧪 Antigravity 驗收補充

- [ ] 啟動前已確認 skill 安裝完成
- [ ] 任務前後事件已寫入且 append-only
- [ ] 可從 `ai-memory-hub` 追溯完整處理歷程，且同步 PR 已 merged
