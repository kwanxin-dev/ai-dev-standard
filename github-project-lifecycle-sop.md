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

## 8. Issue / Milestone 規劃治理（管理者 + 工程師 + AI）

1. `Issue` 是正式工作單位，`Milestone` 是交付批次；兩者不可省略成只用 PR 溝通。
2. 任何非 trivial 工作都應先有 issue，再開始實作。
3. 任何符合以下條件的 issue，必須掛入明確 milestone：
   - 會跨 1 個以上 PR
   - 會跨工作日或需要多次交接
   - 會影響 release、staging、驗收、上線決策
   - 會同時改動多個模組、流程或文件
4. 只有 trivial 工作可不掛 milestone，例如 typo、純格式修正、單點小修且不影響交付邊界。
5. milestone 名稱必須能代表可交付結果，建議格式：
   - release：`v0.4.0`
   - phase：`Phase 1 - MVP`
   - timebox：`2026-04 Runtime Hardening`
6. 每個 milestone 至少應具備：
   - 標題
   - 範圍說明
   - 完成定義
   - 目標日期（若有版本或時程要求）
7. labels 用來分類類型；milestone 用來定義交付批次。不要把 `bug` / `docs` / `incident` 這類 label 當成 milestone 替代品。
8. PR 必須對應 issue；若 issue 已屬於某個 milestone，PR 不得脫離該 milestone 的交付邏輯。
9. AI 在實作前必須先確認：
   - 這次工作屬於哪個 issue
   - 該 issue 屬於哪個 milestone
   - 若缺 milestone，是否應先補建
10. AI 在回報進度時，除 issue 狀態外，還必須同步回報：
   - milestone 尚餘 open issues
   - 主要阻塞
   - 目前是否仍在 milestone 範圍內

### 8-1. CLI 快速操作（選用）

建立 issue 時直接指定 milestone：

```bash
gh issue create -R <your-org>/<your-repo> \
  --title "Add runtime health automation" \
  --body "..." \
  --milestone "v0.4.0"
```

既有 issue 補掛 milestone：

```bash
gh issue edit 123 -R <your-org>/<your-repo> --milestone "v0.4.0"
```

## 9. 工程師日常提交流程

1. 從最新主線開分支：`ai/<engineer>/<task>`。
2. 完成功能後 commit + push 到該分支。
3. 開發前先確認對應 issue 與 milestone，若缺任一項，先補齊或明確記錄例外原因。
4. 驗證 Preview：
   - `https://<your-staging-domain>/p/<engineer>/<task>/`
   - 實際 host / path / 深連結規則必須由專案在 `AGENTS.local.md` 宣告，不得默認沿用其他專案的 preview 網址。
   - Canonical preview 必須使用專案自有、可持續的 URL；`ngrok` / `localtunnel` / `localhost.run` 只能當臨時示意，不可視為正式 PR preview。
5. 每次修改完成回報（含中間交付）必須附上「合併前預覽網址」，且只需提供本次修改目標頁（若有指定單號/ID 需附完整路徑；除非另外要求，不需附分支入口或列表頁）。
6. 若專案尚未有穩定 preview，`AGENTS.local.md` 必須標示 `preview_mode: fallback_artifact`，並記錄暫行驗證方式與建立 preview 基礎設施的追蹤 task。
7. 必測清單：
   - `/api/auth/me`
   - `/api/auth/login`
   - 目標頁主流程
   - 相關 API 無 500
8. 建 PR，附上：
   - 對應 issue / milestone
   - 變更摘要
   - 風險
   - 測試步驟/結果
   - 回滾方案
9. PR 建立後每次更新 commit 都要重新確認 required checks 全綠；任一檢查非綠燈時，禁止宣告完成、禁止請求合併。

## 10. Preview URL 規則（避免用錯）

對 `ai/<engineer>/<task>` 分支，preview slug 會是：

1. `ai/engineer/workorder-aa-scale-slider`
2. Preview URL 是 `/p/engineer/workorder-aa-scale-slider/`

不是 `/p/<org>/<完整分支>/`。

## 11. 管理者合併流程

1. 開 PR 頁面，先看 `Files changed` 確認範圍。
2. 先確認 PR 對應的 issue 與 milestone 正確；若缺 milestone，需判斷是否真屬 trivial 例外。
3. 確認該 milestone 的完成定義未被本次變更破壞，且未混入不屬於本 milestone 的範圍。
4. 檢查 required checks 全綠（僅 `success` 算通過；`expected`/`pending`/`neutral`/`skipped`/`cancelled` 都不算）。
5. 檢查 PR 必須無衝突且可合併（若顯示 `Checks awaiting conflict resolution`，先解衝突）。
6. 若專案啟用 strict required checks，先確認分支已同步目標分支後重跑檢查。
7. 確認 approvals 達標（例如 2 個）。
8. 確認 conversation 都 resolved。
9. `Merge pull request`（或 `Squash and merge`，依專案規範）。
10. 合併後到 staging 做一次 smoke 驗證。
11. 若 milestone 內 issue 已完成，補 milestone 結案摘要，才算真正完成該批交付。

## 12. 權限與安全守則

1. 禁止共用管理者 PAT。
2. PAT 僅短期、最小權限、最短有效期。
3. Token 一旦貼到聊天、文件、截圖，立刻 `revoke + reissue`。
4. 工程師離開專案時：
   - 移除 Organization member 或 repo access
   - 清理 Outside collaborator
   - 回收席位

## 13. 常見錯誤與處理

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

### Q3-1. 為什麼不能直接拿 tunnel URL 當正式 preview

1. `ngrok` / `localtunnel` / `localhost.run` 類網址通常是短生命週期，不符合 PR 審核需要的可重現性。
2. 這類網址不屬於專案自有 host，無法作為長期治理、PM 驗收與 merge gate 的穩定依據。
3. 若只能先用 tunnel 示意，必須在回報中明確標示為臨時 demo，且同步建立正式 preview 基礎設施的追蹤任務。

### Q4. 顯示 `Checks awaiting conflict resolution`

1. 這不是「全綠」，代表 PR 與目標分支有衝突，required checks 會停在 `Expected/Waiting`。
2. 先更新分支（merge/rebase 目標分支）並解完衝突，再 push 觸發 checks 重跑。
3. 重跑後仍需同時滿足 approvals 與 conversation resolved，才可合併。

### Q5. 為什麼不能只用 `.ai-memory/issues/`，不開 GitHub issue / milestone

1. `.ai-memory/issues/` 是 AI 內部記憶與歷史追溯，不是正式協作與交付治理工具。
2. GitHub issue 才是正式可指派、可連結 PR、可被 reviewer / PM 共同觀察的工作單位。
3. milestone 才能用來表達「這批工作是否可交付」與目前剩餘工作量。

### Q6. 什麼情況可以不掛 milestone

1. 僅限 trivial 工作，例如 typo、格式化、註解修正、極小範圍且不影響 release 邊界的小修。
2. 若工作已經需要開正式 issue、提 PR、做驗收或進入版本判斷，原則上就應該掛 milestone。

## 14. Skill 與記憶中樞落地（跨工具）

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
