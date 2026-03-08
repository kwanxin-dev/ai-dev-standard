# Skill 與集中記憶治理標準（草案）

> 目標：讓新 skill 可以在 `Codex CLI / Claude Code / Gemini CLI / Antigravity IDE` 四種環境一致安裝與觸發，並把所有記憶統一同步到獨立 `ai-memory-hub`。

## 1. 倉庫分工

- Skill 中央倉：`https://github.com/<org>/ai-skills`
  - 管理 skill 定義、安裝腳本、觸發腳本。
- Memory 中央倉：`https://github.com/<org>/ai-memory-hub`
  - 管理所有專案的歷史記錄與修復經驗。

## 2. 記憶目錄規範（ai-memory-hub）

```text
projects/
  <repo-owner>__<repo-name>/
    _index.md
    modules/
      <module-name>/
        events/
          2026-02.jsonl
        fixes/
          successful/
            2026-02.jsonl
          failed/
            2026-02.jsonl
```

- `<module-name>` 建議用專案路徑分桶（例如 `apps-web-workorder`、`api-auth`）。
- 本地 `.ai-memory/` 視為工作快取，不是最終事實來源。

## 3. 事件資料結構（JSONL）

每行一筆事件，最少欄位：

```json
{
  "event_id": "evt_20260225_001",
  "project": "<your-org>/<your-repo>",
  "module": "apps-web-workorder",
  "timestamp": "2026-02-25T11:28:00Z",
  "actor": "codex",
  "trigger": "skill:memory-hub-sync",
  "outcome": "success",
  "summary": "修正工單列表預設勾選並驗證通過",
  "related_issue": "WO-1042"
}
```

## 4. Append-only 原則（強制）

- 允許：新增事件。
- 禁止：修改或刪除既有事件。
- 更正方式：新增 `correction` 事件，並用 `supersedes_event_id` 指向舊事件。
- 任何自動化腳本不得做 in-place rewrite。

## 5. 成功/失敗經驗記錄（必填）

每次問題處理至少新增：

- `failed_cases`（可多筆）
  - 嘗試方案、失敗原因、觀察到的錯誤訊號。
- `successful_cases`（至少 1 筆）
  - 最終方案、驗證步驟、回歸風險。

目的：避免下次重複修同一問題，先比對歷史 case 再動手。

## 6. Skill 套件結構（ai-skills）

```text
skills/
  memory-hub-sync/
    SKILL.md
    install/
      install-claude.sh
      install-codex.sh
      install-gemini.sh
      install-antigravity.sh
    scripts/
      preflight.sh
      append-event.sh
      sync-hub.sh
```

## 7. 四環境安裝標準

建議由同一入口腳本完成四環境安裝：

```bash
bash scripts/install-skill.sh \
  --skill memory-hub-sync \
  --targets claude,codex,gemini,antigravity
```

預設安裝目錄（可用環境變數覆寫）：

- Claude：`${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}`
- Codex：`${CODEX_SKILLS_DIR:-$HOME/.codex/skills}`
- Gemini：`${GEMINI_SKILLS_DIR:-$HOME/.gemini/skills}`
- Antigravity：`${ANTIGRAVITY_SKILLS_DIR:-$HOME/.antigravity/skills}`

## 8. 觸發流程（不靠提示詞）

- 專案入口檔（`AGENTS.md / CLAUDE.md / CODEX.md / GEMINI.md / ANTIGRAVITY.md`）宣告必裝 `memory-hub-sync`。
- 每次任務開始：
  - 執行 `preflight.sh` 讀取相關歷史事件。
- 每次任務結束：
  - 執行 `append-event.sh` 寫入成功或失敗案例。
  - 執行 `sync-hub.sh` 將事件同步到 `ai-memory-hub`。

## 9. 驗收條件

- 新增一個 skill 時，四環境都要有安裝步驟與觸發說明。
- `ai-memory-hub` 可查到同一任務的完整歷史（包含失敗與成功）。
- 隨機抽查事件不得被覆寫（append-only 生效）。
