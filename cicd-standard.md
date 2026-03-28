# CI/CD 標準規範

> 適用於 kwanxin-dev 組織下所有專案的持續整合與持續部署標準。

---

## 設計原則

| 原則 | 說明 |
|------|------|
| **最小權限** | Secrets 只授予必要範圍，SSH Key 專用於部署 |
| **部署前驗證** | 語法檢查、關鍵檔案存在性檢查，不通過不部署 |
| **部署後驗證** | 自動確認目標環境正常運作 |
| **可回滾** | 每次部署可追溯到 commit，隨時可回到前一版 |
| **並行保護** | 同一環境不允許並行部署 |

---

## Workflow 命名與觸發規範

### 檔案命名

```
.github/workflows/
├── deploy-main.yml         # 生產環境部署（push to main）
├── deploy-preview.yml      # PR 預覽部署（自動產生預覽網址）
├── pr-ci.yml               # PR 持續整合（lint/test）
├── deploy-staging.yml      # 測試環境部署（如有）
├── sync-ai-standard.yml    # AI 標準同步（由 enable-sync.sh 安裝）
└── ci.yml                  # 其他持續整合（如有）
```

### 觸發條件

| Workflow | 觸發 | 說明 |
|----------|------|------|
| `deploy-main.yml` | push to `main` + `workflow_dispatch` | 只有合併到主分支才部署 |
| `deploy-preview.yml` | pull_request (opened/synchronize/reopened/closed) | PR 預覽，合併前可先確認 |
| `pr-ci.yml` | pull_request to `main` | PR 時自動檢查（lint/test） |
| `deploy-staging.yml` | push to `develop` | 測試環境跟隨開發分支 |

### paths-ignore（部署時排除）

```yaml
paths-ignore:
  - 'docs/**'
  - '*.md'
  - '.ai-memory/**'
  - 'e2e-tests/**'
  - 'test/**'
  - 'sample/**'
```

---

## Secrets 管理規範

### 必要 Secrets

| Secret 名稱 | 用途 | 範例值 |
|-------------|------|--------|
| `SSH_PRIVATE_KEY` | 部署用 SSH 私鑰 (ed25519) | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `SSH_HOST` | 目標主機 IP | `210.60.194.33` |
| `SSH_USER` | SSH 登入帳號 | `bus` |
| `DEPLOY_PATH` | 部署目標路徑 | `/var/www/html` |

### Secrets 設定方式

```bash
# 產生部署專用 SSH Key
ssh-keygen -t ed25519 -C "github-actions-deploy@<project>" -f deploy_key -N ""

# 公鑰加到目標主機
ssh-copy-id -i deploy_key.pub <user>@<host>

# 私鑰加到 GitHub Secrets
gh secret set SSH_PRIVATE_KEY --repo <org>/<repo> < deploy_key
gh secret set SSH_HOST --repo <org>/<repo> <<< "<host>"
gh secret set SSH_USER --repo <org>/<repo> <<< "<user>"
gh secret set DEPLOY_PATH --repo <org>/<repo> <<< "<path>"

# 清除本地私鑰
rm deploy_key deploy_key.pub
```

### 安全規則

- SSH 私鑰 **絕不** 寫入程式碼或文件
- 每個專案使用 **獨立的** 部署 Key
- 定期（每季）輪換 SSH Key
- 密碼型認證 **禁止** 用於 CI/CD（必須用 SSH Key）

---

## 部署流程標準

### PHP 專案部署模板

```yaml
name: Deploy to Production

on:
  push:
    branches: [main]
    paths-ignore:
      - 'docs/**'
      - '*.md'
      - '.ai-memory/**'
  workflow_dispatch:

permissions:
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    concurrency:
      group: production-deploy
      cancel-in-progress: false

    steps:
      - uses: actions/checkout@v4

      - name: Setup SSH
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.SSH_PRIVATE_KEY }}" > ~/.ssh/deploy_key
          chmod 600 ~/.ssh/deploy_key
          ssh-keyscan -H ${{ secrets.SSH_HOST }} >> ~/.ssh/known_hosts

      - name: Pre-deploy validation
        run: |
          # PHP 語法檢查
          find . -name "*.php" -not -path "./vendor/*" -not -path "./test/*" \
            | head -100 | xargs -I{} php -l {} > /dev/null
          echo "PHP 語法檢查通過"

      - name: Deploy via rsync
        run: |
          rsync -avz --delete \
            --exclude='.git/' \
            --exclude='.github/' \
            --exclude='.claude/' \
            --exclude='.ai-memory/' \
            --exclude='node_modules/' \
            --exclude='test/' \
            --exclude='logs/*.log' \
            --exclude='*.md' \
            -e "ssh -i ~/.ssh/deploy_key" \
            ./ ${{ secrets.SSH_USER }}@${{ secrets.SSH_HOST }}:${{ secrets.DEPLOY_PATH }}/

      - name: Post-deploy verification
        run: |
          ssh -i ~/.ssh/deploy_key \
            ${{ secrets.SSH_USER }}@${{ secrets.SSH_HOST }} \
            "php -r \"echo 'PHP OK';\" && echo 'Deploy verified'"
```

### 部署三階段

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│  Pre-deploy      │ ──→ │  Deploy          │ ──→ │  Post-deploy     │
│  驗證            │     │  傳輸            │     │  確認            │
│                  │     │                  │     │                  │
│  - PHP 語法檢查  │     │  - rsync 同步    │     │  - 檔案存在確認  │
│  - 關鍵檔案存在  │     │  - 排除規則      │     │  - PHP 可執行    │
│  - 不通過=中止   │     │  - 並行保護      │     │  - 服務重載      │
└──────────────────┘     └──────────────────┘     └──────────────────┘
```

---

## rsync 排除規則標準

以下檔案/目錄 **不應** 部署到生產環境：

### 開發工具與設定
```
.git/  .github/  .claude/  .cursor/  .vscode/
.ai-memory/  .ai-dev-standard.json  .githooks/
node_modules/  e2e-tests/
```

### 文件與測試
```
docs/  test/  sample/  *.md
```

### 備份與暫存
```
backup/  backups/  stable_backup/  cache/
*.bak  *.sql  *.log
```

### 除錯與安全敏感
```
debug_*  check_*  phpinfo.php
config/*.20*  (舊版設定備份)
```

---

## 並行控制

```yaml
concurrency:
  group: production-deploy
  cancel-in-progress: false  # 不取消進行中的部署
```

- 同一環境（production）同時只能有一個部署
- `cancel-in-progress: false` — 已開始的部署不中斷，新的排隊等待
- 避免 rsync 衝突導致檔案不一致

---

## PR 預覽部署

### 設計目的

每個 PR 自動產生獨立的預覽網址，讓審查者在合併前確認變更效果。
預覽在 PR 關閉後自動清理，不留殘檔。

### 流程

```
PR 開啟/更新 → deploy-preview.yml 觸發
    ↓
部署到 /preview/pr-{N}/
    ↓
自動在 PR 留言貼上預覽網址
    ↓
審查者確認 → 合併
    ↓
PR 關閉 → 自動清理預覽目錄
```

### 預覽網址格式

```
http://<host>/preview/pr-<number>/
```

例如：PR #56 → `http://210.60.194.33/preview/pr-56/`

### Workflow 模板（self-hosted runner）

```yaml
name: Deploy Preview on PR

on:
  pull_request:
    branches: [main]
    types: [opened, synchronize, reopened, closed]

permissions:
  contents: read
  pull-requests: write

concurrency:
  group: preview-pr-${{ github.event.pull_request.number }}
  cancel-in-progress: true

jobs:
  deploy-preview:
    if: github.event.action != 'closed'
    runs-on: [self-hosted, <runner-label>]
    steps:
      - name: Deploy PR branch to preview path
        id: deploy
        shell: bash
        env:
          PR_NUMBER: ${{ github.event.pull_request.number }}
          HEAD_REF: ${{ github.event.pull_request.head.ref }}
          HEAD_SHA: ${{ github.event.pull_request.head.sha }}
          REPO_URL: ${{ github.server_url }}/${{ github.repository }}.git
        run: |
          set -euo pipefail
          preview_root="/var/www/html/preview"
          target_dir="${preview_root}/pr-${PR_NUMBER}"
          mkdir -p "${preview_root}"

          if [ -d "${target_dir}/.git" ]; then
            git -C "${target_dir}" fetch --prune origin "${HEAD_REF}"
          else
            rm -rf "${target_dir}"
            git clone "${REPO_URL}" "${target_dir}"
          fi

          git -C "${target_dir}" checkout -B "${HEAD_REF}" "origin/${HEAD_REF}"
          git -C "${target_dir}" reset --hard "${HEAD_SHA}"

          # 如有 composer.json，安裝依賴
          if [ -f "${target_dir}/composer.json" ]; then
            composer install --working-dir="${target_dir}" \
              --no-interaction --prefer-dist --no-progress || true
          fi

          echo "preview_url=http://<host>/preview/pr-${PR_NUMBER}/" >> "$GITHUB_OUTPUT"

      - name: Comment preview URL on PR
        uses: actions/github-script@v7
        env:
          PREVIEW_URL: ${{ steps.deploy.outputs.preview_url }}
        with:
          script: |
            const marker = '<!-- preview-deploy-url -->'
            const body = `${marker}\n✅ Preview 部署完成\n- URL: ${process.env.PREVIEW_URL}\n- Commit: \`${context.payload.pull_request.head.sha.slice(0,7)}\``
            const { owner, repo } = context.repo
            const issue_number = context.issue.number
            const comments = await github.paginate(
              github.rest.issues.listComments, { owner, repo, issue_number, per_page: 100 }
            )
            const existing = comments.find(c => c.body?.includes(marker))
            if (existing) {
              await github.rest.issues.updateComment({ owner, repo, comment_id: existing.id, body })
            } else {
              await github.rest.issues.createComment({ owner, repo, issue_number, body })
            }

  cleanup-preview:
    if: github.event.action == 'closed'
    runs-on: [self-hosted, <runner-label>]
    steps:
      - name: Remove preview directory
        run: rm -rf "/var/www/html/preview/pr-${{ github.event.pull_request.number }}"

      - name: Comment cleanup
        uses: actions/github-script@v7
        with:
          script: |
            await github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.issue.number,
              body: '<!-- preview-deploy-url -->\n🧹 Preview 已清理（PR 已關閉）'
            })
```

### 關鍵設計

| 要點 | 說明 |
|------|------|
| **PR 留言更新** | 同一 PR 多次 push 時，更新既有留言而非重複留言（用 HTML marker 辨識） |
| **並行隔離** | 每個 PR 獨立目錄 `/preview/pr-{N}/`，互不干擾 |
| **自動清理** | PR 關閉（合併或取消）時自動刪除預覽目錄 |
| **concurrency** | `cancel-in-progress: true` — 同一 PR 的新 push 會取消前一次預覽部署 |

### 生產部署 rsync 排除預覽目錄

生產部署的 rsync 必須排除 `preview/`，否則會被 `--delete` 清除：

```yaml
rsync -av --delete \
  --exclude='preview/' \
  ...
```

### Variables 設定（可選）

| Variable | 用途 | 預設值 |
|----------|------|--------|
| `PREVIEW_BASE_URL` | 預覽網址前綴 | `http://<host>/preview` |
| `PREVIEW_ROOT` | 預覽目錄路徑 | `/var/www/html/preview` |

設定方式：GitHub Repo Settings → Variables（非 Secrets，不含敏感資訊）

---

## 回滾策略

### 快速回滾（推薦）

```bash
# 方法 1：git revert + 重新觸發部署
git revert <bad-commit>
git push origin main
# → 自動觸發 deploy workflow

# 方法 2：手動觸發指定 commit 的部署
gh workflow run deploy.yml --repo <org>/<repo>
# → workflow_dispatch 觸發
```

### 緊急回滾（SSH 直連）

```bash
# 直接在主機操作（僅緊急情況）
ssh <user>@<host>
cd /var/www/html
git log --oneline -5
git checkout <last-good-commit> -- .
sudo systemctl reload apache2
```

---

## 監控與通知（建議）

### 部署摘要

每次部署在 GitHub Actions Summary 記錄：
- Commit SHA
- 觸發者
- 部署時間
- 成功/失敗

### Slack/Teams 通知（可選）

```yaml
- name: Notify on failure
  if: failure()
  run: |
    curl -X POST "${{ secrets.SLACK_WEBHOOK }}" \
      -H 'Content-type: application/json' \
      -d '{"text":"部署失敗: ${{ github.repository }} (${{ github.sha }})"}'
```

---

## 檢查清單

新專案啟用 CI/CD 時，按以下順序設定：

- [ ] 產生部署用 SSH Key (`ssh-keygen -t ed25519`)
- [ ] 公鑰加到目標主機 (`~/.ssh/authorized_keys`)
- [ ] 私鑰加到 GitHub Secrets (`SSH_PRIVATE_KEY`)
- [ ] 設定其他 Secrets (`SSH_HOST`, `SSH_USER`, `DEPLOY_PATH`)
- [ ] 複製 `.github/workflows/deploy-main.yml` 模板
- [ ] 複製 `.github/workflows/deploy-preview.yml` 模板
- [ ] 複製 `.github/workflows/pr-ci.yml` 模板（如需 lint/test）
- [ ] 調整 rsync 排除規則（依專案需求，含 `--exclude='preview/'`）
- [ ] 測試生產部署（`workflow_dispatch` 手動觸發）
- [ ] 測試 PR 預覽（建立測試 PR 確認預覽網址正常）
- [ ] 確認回滾流程可行
- [ ] 清除本地 SSH 私鑰
