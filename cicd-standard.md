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
├── deploy.yml              # 生產環境部署
├── deploy-staging.yml      # 測試環境部署（如有）
├── sync-ai-standard.yml    # AI 標準同步（由 enable-sync.sh 安裝）
└── ci.yml                  # 持續整合（lint/test，如有）
```

### 觸發條件

| Workflow | 觸發 | 說明 |
|----------|------|------|
| `deploy.yml` | push to `main` + `workflow_dispatch` | 只有合併到主分支才部署 |
| `deploy-staging.yml` | push to `develop` | 測試環境跟隨開發分支 |
| `ci.yml` | pull_request to `main` | PR 時自動檢查 |

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
- [ ] 複製 `.github/workflows/deploy.yml` 模板
- [ ] 調整 rsync 排除規則（依專案需求）
- [ ] 測試部署（`workflow_dispatch` 手動觸發）
- [ ] 確認回滾流程可行
- [ ] 清除本地 SSH 私鑰
