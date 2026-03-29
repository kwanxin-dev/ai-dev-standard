# CLAUDE.md — Claude Code 專屬擴展規則
# 適用於：Claude Code (claude-code CLI / IDE 整合)
# 版本：2.0 | 基於《那些 Agent 神文沒告訴你的事》實操方法論
#
# 📌 本檔案繼承 AGENTS.md 的所有共用規則。
# 以下僅定義 Claude Code 特有的能力優化與工作流程。
# 共用規則（記憶管理、程式碼規範、GitHub issue / milestone / PR 治理、邊界規則、跨 AI 協作）請參閱 AGENTS.md。

---

## 📖 啟動流程

每次 Claude Code 啟動新對話時：
1. 讀取 **AGENTS.md**（共用規則）
2. 讀取 **本檔案**（Claude 專屬擴展）
3. **若存在 `CLAUDE.local.md`，必須讀取**（專案專屬覆寫，如 DB 連線、專案架構）
4. 讀取 `.ai-memory/progress/_index.md`（全域進度）
5. 讀取最新的 `.ai-memory/context/session-*.md`（前次狀態）
6. 檢查 `.ai-memory/issues/open.md`（未解決問題）
7. 確認本次任務的正式 GitHub 規劃容器：
   - 對應 issue 是什麼
   - issue 是否已掛 milestone
   - 若已進入 PR 階段，PR 是否仍與該 issue / milestone 一致

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

## 🔨 Claude 專屬能力

### 長上下文窗口策略

Claude 擁有超長上下文窗口，善用此優勢：
- 可以一次處理較多的相關檔案，減少來回查看
- 但仍需遵守 AGENTS.md 的資訊品質分級，不要無差別灌入
- 對話超過 20 輪時，按 AGENTS.md 規範卸載至 `.ai-memory/context/`

### 子任務委派（TodoRead/TodoWrite）

當任務可以拆分時，使用子任務模式：
```
主任務：實作使用者登入功能
  ├── 子任務 1：建立 API 路由 (/api/auth/login)
  ├── 子任務 2：實作密碼驗證邏輯
  ├── 子任務 3：產生 JWT Token
  └── 子任務 4：建立前端登入表單
```

每個子任務必須：
- 有明確的完成標準
- 結果可獨立驗證
- 不依賴其他未完成的子任務（或標明依賴關係）

### 工具呼叫結構化回寫

工具呼叫結果寫回上下文時使用統一格式：
```
🔧 工具呼叫：[工具名稱]
📥 輸入：[關鍵參數]
📤 結果：[精簡的結果摘要]
⚡ 下一步：[基於結果的下一步行動]
```

### 錯誤重試策略
```
第 1 次失敗 → 檢查參數是否正確，修正後重試
第 2 次失敗 → 換一個方法/工具嘗試
第 3 次失敗 → 停下來分析原因，向使用者報告
```

### System Prompt 迭代法
```
第 1 版：3-5 條核心規則（能跑就好）
    ↓ 觀察實際表現，記錄問題
第 2 版：針對問題加入 5-8 條補充規則
    ↓ 持續觀察
第 3 版：精煉合併，移除無效規則，最終 10-15 條精準規則
```

---

## 🧪 Claude 專屬驗證

### 任務隔離原則
- 一次只處理一個功能點
- 完成一個功能後先驗證，再開始下一個
- 不要在修 Bug 的同時順便重構
- 子任務拆分不得偷偷跨 milestone；若發現任務已超出原 milestone，先停下來回報並重新規劃

### 迭代評估補充
除了 AGENTS.md 的評估標準外，額外檢查：
- [ ] 有沒有硬編碼應該設定化的值？
- [ ] 文件是否需要更新？
- [ ] `.ai-memory/` 是否已同步最新狀態？
- [ ] 對應 issue / milestone 是否正確，且這次交付仍在 milestone 範圍內？

### 命名規範補充
- 遵循專案所用語言/框架的社群慣例
- 專案可在 `CLAUDE.local.md` 定義具體命名規範
- 常數名建議：`UPPER_SNAKE_CASE`（如 `MAX_RETRY_COUNT`）
