# GitHub 新專案到合併完整 SOP（管理者 + 工程師 + AI）

> 目標：強制「工程師不能直推主線」，且所有變更必須走 Preview + PR + 管理者核准。
>
> ⚠️ 本文件使用佔位符（`<your-org>`、`<your-repo>`、`<main-branch>`、`<your-staging-domain>`），請依專案實際值替換。

## 1. 新專案建立（管理者）

1. 建立 GitHub Organization（建議名稱固定，例如 `<your-org>`）。
2. 專案 repo 建在 Organization 下（不要放個人帳號）。
3. 私有 repo 要啟用平台層強制保護，至少使用 GitHub Team。
4. 預設主線只保留一條（例如 `main`）。

## 2. 權限模型（管理者）

1. 管理者角色：`Owner/Admin`（少數人）。
2. 工程師角色：`Write`（不得給 `Admin`）。
3. 工程師必須是 **Organization member**，不是只有 Outside collaborator。
4. 建議用 Team 管 repo 權限：
   - Team: `engineers`
   - Repository: `<your-repo>`
   - Permission: `Write`

## 3. 工程師加入流程（管理者 + 工程師）

1. 管理者到 `Organization -> People` 發送 `Invite member`（Role: `Member`）。
2. 工程師到通知或 email 按 `Accept invitation` 加入組織。
3. 管理者確認：該帳號出現在 `People`，狀態不是 `Pending`。
4. 管理者把工程師加入 Team 或 repo `Write`。

## 4. PAT 流程（工程師）

1. 工程師建立 Fine-grained PAT。
2. `Resource owner` 必須選 Organization（例如 `<your-org>`）。
3. `Repository access` 選 `Only select repositories`，勾目標 repo（例如 `<your-repo>`）。
4. 權限至少開：
   - `Contents: Read and write`
   - （需要查/觸發 workflow 時）`Actions/Workflows: Read and write`
5. 若看到 `waiting admin approval`，管理者要到 Organization 設定核准 PAT request。

## 5. 主線保護 Ruleset（管理者）

在 repo `Settings -> Rulesets -> New branch ruleset`：

1. Target branches：至少包含 `<main-branch>`（若有 `main` 也要包含）。
2. `Enforcement`: `Active`。
3. `Bypass list`：只留 `Repository admin`（不要放工程師）。
4. 必勾規則：
   - `Restrict updates`
   - `Restrict deletions`
   - `Require a pull request before merging`
   - `Block force pushes`
5. PR 規則建議：
   - `Required approvals >= 2`
   - `Require conversation resolution`
   - `Require approval of most recent push`
6. `Require status checks to pass`：至少 2 個
   - `seed-required-check`（seed check）
   - `web-build-check`（正式 CI）

## 6. 先讓 Required checks 可被選到（管理者）

1. 先有對應 workflow（例如 `.github/workflows/ci.yml`）並在主線跑成功至少一次。
2. 若 `Add checks` 空白，先手動觸發一次 workflow 或推一個最小變更讓 check 出現。
3. 回到 Ruleset 選取 check name 並儲存。

## 7. 強制驗收（一定要做一次）

使用工程師 PAT 驗證：

1. `push` 到 `ai/<engineer>/<task>`：應成功。
2. 直接 `push` 到 `<main-branch>`：必須被拒絕（GH013 / ruleset violation）。
3. 開 PR，但不滿足 approval/check：必須不能 merge。

## 8. 工程師日常提交流程

1. 從最新主線開分支：`ai/<engineer>/<task>`。
2. 完成功能後 commit + push 到該分支。
3. 驗證 Preview：
   - `https://<your-staging-domain>/p/<engineer>/<task>/`
4. 每次修改完成回報（含中間交付）必須附上「合併前預覽網址」，且只需提供本次修改目標頁（若有指定單號/ID 需附完整路徑；除非另外要求，不需附分支入口或列表頁）。
5. 必測清單：
   - `/api/auth/me`
   - `/api/auth/login`
   - 目標頁主流程
   - 相關 API 無 500
6. 建 PR，附上：
   - 變更摘要
   - 風險
   - 測試步驟/結果
   - 回滾方案
7. PR 建立後每次更新 commit 都要重新確認 required checks 全綠；任一檢查非綠燈時，禁止宣告完成、禁止請求合併。

## 9. Preview URL 規則（避免用錯）

對 `ai/<engineer>/<task>` 分支，preview slug 會是：

1. `ai/engineer/workorder-aa-scale-slider`
2. Preview URL 是 `/p/engineer/workorder-aa-scale-slider/`

不是 `/p/<org>/<完整分支>/`。

## 10. 管理者合併流程

1. 開 PR 頁面，先看 `Files changed` 確認範圍。
2. 檢查 required checks 全綠（僅 `success` 算通過；`expected`/`pending`/`neutral`/`skipped`/`cancelled` 都不算）。
3. 檢查 PR 必須無衝突且可合併（若顯示 `Checks awaiting conflict resolution`，先解衝突）。
4. 若專案啟用 strict required checks，先確認分支已同步目標分支後重跑檢查。
5. 確認 approvals 達標（例如 2 個）。
6. 確認 conversation 都 resolved。
7. `Merge pull request`（或 `Squash and merge`，依專案規範）。
8. 合併後到 staging 做一次 smoke 驗證。

## 11. 權限與安全守則

1. 禁止共用管理者 PAT。
2. PAT 僅短期、最小權限、最短有效期。
3. Token 一旦貼到聊天、文件、截圖，立刻 `revoke + reissue`。
4. 工程師離開專案時：
   - 移除 Organization member 或 repo access
   - 清理 Outside collaborator
   - 回收席位

## 12. 常見錯誤與處理

### Q1. 工程師 PAT 看不到 repo

1. 工程師還沒成為 Organization member（只在 Outside collaborator）。
2. 邀請還沒接受（Pending）。
3. PAT `Resource owner` 選錯（選到個人帳號）。
4. Organization 啟用 PAT request，但管理者尚未核准。

### Q2. Ruleset 的 `Add checks` 是空白

1. 對應 workflow 尚未跑成功過。
2. 先在主線跑出成功 check，再回 Ruleset 選取。

### Q3. Preview 打開後被導去 `/erp/dashboard`

1. URL 用錯（應用 `/p/<engineer>/<task>/`）。
2. 深路徑 fallback 尚未部署完成，先從 preview 根路徑進入再操作。

### Q4. 顯示 `Checks awaiting conflict resolution`

1. 這不是「全綠」，代表 PR 與目標分支有衝突，required checks 會停在 `Expected/Waiting`。
2. 先更新分支（merge/rebase 目標分支）並解完衝突，再 push 觸發 checks 重跑。
3. 重跑後仍需同時滿足 approvals 與 conversation resolved，才可合併。

## 13. Skill 與記憶中樞落地（跨工具）

1. 建立 skill 中央倉（例如 `ai-skills`），集中管理自製 skill。
2. 建立記憶中央倉（例如 `ai-memory-hub`），集中保存所有專案歷史事件。
3. 在專案入口檔（AGENTS/CLAUDE/CODEX/GEMINI/ANTIGRAVITY）宣告必裝 `memory-hub-sync`。
4. 每次任務開始先做 preflight 讀歷史；任務結束追加 success/failed case。
5. 記錄必須 append-only（不可改寫舊事件）；更正採新增 correction 事件。
6. 新增任何 skill 時，四環境安裝流程都要寫清楚，否則不得視為完成交付。

---

## 最小落地清單（給管理者快速核對）

1. Organization + Team 啟用。
2. 工程師是 Member + Write（非 Admin）。
3. Ruleset active 且只允許 Admin bypass。
4. Required checks 已選 seed + ci。
5. 工程師直推主線被拒絕。
6. 變更可走 preview + PR + 管理者 merge。
