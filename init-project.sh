#!/bin/bash
# ============================================
# init-project.sh — AI 輔助開發專案初始化腳本
# ============================================
# 用法：在新專案根目錄執行
#   bash init-project.sh
# 或
#   chmod +x init-project.sh && ./init-project.sh
# ============================================

set -e

echo "🚀 正在初始化 AI 輔助開發專案..."
echo ""

# --- 1. 建立 .ai-memory/ 目錄結構 ---
echo "📁 建立 .ai-memory/ 記憶目錄..."
mkdir -p .ai-memory/{decisions,progress,issues,context,lessons}

# 決策索引
cat > .ai-memory/decisions/_index.md << 'EOF'
# 架構決策索引

| 日期 | 標題 | 狀態 | AI |
|------|------|------|-----|
<!-- 範例：| 2025-03-15 | 選擇 JWT 認證 | ✅ 已執行 | Claude | -->
EOF

# 進度索引
cat > .ai-memory/progress/_index.md << 'EOF'
# 全域進度總覽

> 最後更新：（由 AI 自動更新）

## 模組進度
| 模組 | 狀態 | 負責 AI | 最後更新 |
|------|------|---------|---------|
<!-- 範例：| 前端 | 🔄 進行中 | Gemini | 2025-03-16 | -->
EOF

# Issues
cat > .ai-memory/issues/open.md << 'EOF'
# 未解決問題

<!-- 格式：
## [日期 | AI] 問題標題
- 描述：
- 優先級：🔴高 / 🟡中 / 🟢低
- 相關檔案：
-->
EOF

cat > .ai-memory/issues/resolved.md << 'EOF'
# 已解決問題

<!-- 已解決的問題從 open.md 移到這裡，保留歷史參考 -->
EOF

cat > .ai-memory/issues/_index.md << 'EOF'
# 問題追蹤索引

- [未解決問題](./open.md)
- [已解決問題](./resolved.md)
EOF

# 經驗索引
cat > .ai-memory/lessons/_index.md << 'EOF'
# 經驗學習索引

| 日期 | 標題 | 標籤 | AI |
|------|------|------|-----|
<!-- 範例：| 2025-03-18 | AG Grid 佈局陷阱 | AG-Grid, CSS | Claude | -->
EOF

# 架構文件
cat > .ai-memory/architecture.md << 'EOF'
# 系統架構概觀

> 由 AI 在開發過程中維護，記錄系統的整體架構。

## 技術棧
<!-- 填入專案使用的技術 -->

## 目錄結構
<!-- 填入專案的目錄結構說明 -->

## 模組關係
<!-- 填入各模組之間的關係 -->
EOF

cat > .ai-memory/setup.md << 'EOF'
# 環境設定

## 開發環境需求
<!-- 填入所需的開發工具和版本 -->

## 安裝步驟
<!-- 填入安裝步驟 -->

## 環境變數
<!-- 填入需要的環境變數（不含實際值） -->
EOF

cat > .ai-memory/coding-standards.md << 'EOF'
# 開發規範

> 本檔案補充 AGENTS.md 中的通用程式碼規範，記錄本專案的特定慣例。

## 專案特定規範
<!-- 填入本專案特有的開發規範 -->
EOF

echo "  ✅ .ai-memory/ 目錄建立完成"

# --- 1-1. 建立 OpenSpec 目錄骨架 ---
echo "📐 建立 OpenSpec 目錄骨架..."
mkdir -p openspec/{changes,specs}

cat > openspec/project.md << 'EOF'
# Project Context

## Purpose
<!-- 填入專案目的 -->

## Conventions
- GitHub Issues are operational trackers.
- OpenSpec changes are required for new capabilities, governance changes, security changes, architecture changes, and ambiguous work.
- Keep GitHub Issue, OpenSpec tasks, PR, and .ai-memory synchronized until closeout.
EOF

cat > openspec/AGENTS.md << 'EOF'
# OpenSpec Instructions

Use OpenSpec for new capabilities, governance changes, security changes, architecture changes, and ambiguous work.

Workflow:
1. Create `openspec/changes/<change-id>/proposal.md`.
2. Add `tasks.md`, optional `design.md`, and spec deltas under `specs/<capability>/spec.md`.
3. Run `openspec validate <change-id> --strict`.
4. Sync GitHub Issue, OpenSpec tasks, PR, and .ai-memory progress until confirmed closure.
EOF

echo "  ✅ OpenSpec 目錄骨架建立完成"

# --- 2. 建立 GitHub Actions CI ---
echo "📦 建立 CI/CD Pipeline..."
mkdir -p .github/workflows
mkdir -p .github/ISSUE_TEMPLATE

cat > .github/workflows/ci.yml << 'EOF'
name: CI

on:
  pull_request:
    branches: [main]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # TODO: 依專案語言替換以下步驟
      # Node.js:  npm install && npm run lint && npm test && npm run build
      # PHP:      composer install && vendor/bin/phpunit
      # Python:   pip install -r requirements.txt && pytest
      # Go:       go build ./... && go test ./...
      - name: Build & Test
        run: echo "請替換為專案實際的 build/test 命令"
EOF

echo "  ✅ .github/workflows/ci.yml 建立完成"

# --- 2-1. 建立 GitHub Issue / PR 模板 ---
echo "🧾 建立 GitHub issue / PR 模板..."

cat > .github/ISSUE_TEMPLATE/feature.yml << 'EOF'
name: Feature / Change Request
description: 規劃新功能、重大修補或跨模組變更
title: "[feature] "
labels:
  - enhancement
body:
  - type: markdown
    attributes:
      value: |
        請先確認這不是 trivial 修正。凡是會跨 PR、跨工作日、影響 release / staging / 驗收，或改動多模組的工作，必須指定 milestone。
  - type: input
    id: summary
    attributes:
      label: 一句話問題定義
      description: 這個功能或變更要解決什麼問題？
    validations:
      required: true
  - type: input
    id: milestone
    attributes:
      label: Milestone
      description: 請填入既有 milestone 名稱；trivial 例外請填 `trivial-exception`。
      placeholder: 例如：v0.4.0 / Phase 1 - MVP
    validations:
      required: true
  - type: textarea
    id: scope
    attributes:
      label: 範圍與邊界
      description: 請列出這次要做與明確不做的內容。
    validations:
      required: true
  - type: textarea
    id: verification
    attributes:
      label: 驗證方式
      description: 這個工作完成後，要用什麼方式驗證？
    validations:
      required: true
EOF

cat > .github/ISSUE_TEMPLATE/bug.yml << 'EOF'
name: Bug Report
description: 回報功能異常、回歸問題或交付缺陷
title: "[bug] "
labels:
  - bug
body:
  - type: markdown
    attributes:
      value: |
        若此問題會影響 release、staging、驗收，或需要跨多次修補，必須指定 milestone。只有非常小的單點修正可視為 trivial 例外。
  - type: input
    id: problem
    attributes:
      label: 問題摘要
      description: 用一句話描述錯誤現象
    validations:
      required: true
  - type: input
    id: milestone
    attributes:
      label: Milestone
      description: 請填入既有 milestone 名稱；trivial 例外請填 `trivial-exception`。
      placeholder: 例如：v0.4.0
    validations:
      required: true
  - type: textarea
    id: reproduction
    attributes:
      label: 重現步驟
      description: 請提供最小可重現步驟
    validations:
      required: true
  - type: textarea
    id: expected
    attributes:
      label: 預期結果 / 實際結果
    validations:
      required: true
EOF

cat > .github/ISSUE_TEMPLATE/tracked_problem.yml << 'EOF'
name: Tracked Problem
description: 追蹤非 trivial 問題、回歸、治理缺口或需要 OpenSpec 的變更
title: "[tracked] "
labels:
  - enhancement
body:
  - type: textarea
    id: problem
    attributes:
      label: 問題摘要
      description: 用白話描述要解決的問題。
    validations:
      required: true
  - type: input
    id: milestone
    attributes:
      label: Milestone
      description: 請填入既有 milestone；trivial 例外請填 `trivial-exception`。
    validations:
      required: true
  - type: textarea
    id: duplicate-search
    attributes:
      label: 查重結果
      description: 說明已搜尋哪些症狀 / 頁面 / API / 錯誤訊息 / OpenSpec change。
    validations:
      required: true
  - type: textarea
    id: openspec
    attributes:
      label: OpenSpec 判斷
      description: 若需要 OpenSpec，填 change id；若不需要，說明原因。
    validations:
      required: true
  - type: textarea
    id: progress
    attributes:
      label: 進度總表
      value: |
        | Status | Owner | Branch / PR | OpenSpec | Verification | Next Action |
        | --- | --- | --- | --- | --- | --- |
        | accepted | _待指派_ | _pending_ | _pending_ | _pending_ | _pending_ |
    validations:
      required: true
EOF

cat > .github/PULL_REQUEST_TEMPLATE.md << 'EOF'
## Summary
-

## Issue / Milestone
- Issue:
- Milestone:
- OpenSpec change:
- 若未掛 milestone，請說明為何屬於 trivial 例外：

## Scope
- 本次有做：
- 本次明確沒做：

## Risk
-

## Verification
- [ ] 已附 preview URL 或 fallback artifact 說明
- [ ] 已列出最小驗證步驟與結果
- [ ] required checks 全綠後才請求合併
- [ ] 已同步 Issue 進度與 OpenSpec tasks

### Evidence
- Preview / Artifact:
- CI / Smoke / Healthcheck:

## Issue Lifecycle Closeout
- [ ] 已在 Issue 更新 branch / PR / OpenSpec / 驗證結果 / 下一步
- [ ] 若要詢問是否關閉 Issue，已先完成驗證並附證據
- [ ] 未取得使用者或授權 maintainer 明確確認前，Issue 保持 open
- [ ] 關閉 Issue 時會附 PR、驗證證據、部署證據（若有）與 rollback reference

## Rollback
-
EOF

echo "  ✅ GitHub issue / PR 模板建立完成"

# --- 3. 建立 CODEOWNERS ---
echo "👔 建立 CODEOWNERS..."
cat > CODEOWNERS << 'EOF'
# 所有 PR 自動指派老闆 review
# 請將下方的 @owner 替換為老闆的 GitHub 帳號
* @owner
EOF

echo "  ✅ CODEOWNERS 建立完成（請修改 @owner 為實際帳號）"

# --- 4. 建立 .gitignore ---
echo "📝 建立 .gitignore..."
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
venv/
__pycache__/

# Build
dist/
build/
*.egg-info/

# Environment
.env
.env.local
.env.*.local

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
*.log
npm-debug.log*

# AI memory context (keep structure, ignore large session files older than 3 months)
# .ai-memory/context/ files are managed per AGENTS.md quarterly cleanup rules
EOF

echo "  ✅ .gitignore 建立完成"

# --- 5. 下載 AI 開發標準檔案並啟用自動同步 ---
echo "📥 下載 AI 開發標準檔案..."

AI_STD_REPO="${AI_STD_REPO:-<your-org>/ai-dev-standard}"
AI_STD_REF="${AI_STD_REF:-main}"
AI_STD_FILES=(
  "AGENTS.md"
  "CLAUDE.md"
  "CODEX.md"
  "GEMINI.md"
  "ANTIGRAVITY.md"
  "skills-development-guide.md"
  "skills-memory-standard.md"
  "issue-lifecycle-governance.md"
  "openspec/AGENTS.md"
  "openspec/project.md"
  ".github/ISSUE_TEMPLATE/feature.yml"
  ".github/ISSUE_TEMPLATE/bug.yml"
  ".github/ISSUE_TEMPLATE/tracked_problem.yml"
  ".github/PULL_REQUEST_TEMPLATE.md"
  "scripts/issue_lifecycle.sh"
)

DOWNLOAD_OK=true
for f in "${AI_STD_FILES[@]}"; do
  URL="https://raw.githubusercontent.com/${AI_STD_REPO}/${AI_STD_REF}/${f}"
  mkdir -p "$(dirname "$f")"
  HTTP_CODE=$(curl -sL -w "%{http_code}" -o "$f" "$URL")
  if [[ "$HTTP_CODE" == "200" ]]; then
    echo "  ✅ ${f}"
  else
    echo "  ❌ ${f}（HTTP ${HTTP_CODE}）"
    DOWNLOAD_OK=false
  fi
done

if [[ -f scripts/issue_lifecycle.sh ]]; then
  chmod +x scripts/issue_lifecycle.sh
fi

# 取得最新 commit SHA
LATEST_SHA=$(curl -sL \
  "https://api.github.com/repos/${AI_STD_REPO}/commits/${AI_STD_REF}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('sha','unknown'))" 2>/dev/null || echo "unknown")

# 建立同步元數據
cat > .ai-dev-standard.json << EOF
{
  "source_repo": "${AI_STD_REPO}",
  "source_ref": "${AI_STD_REF}",
  "synced_commit": "${LATEST_SHA}",
  "synced_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "files": $(python3 -c "import json; print(json.dumps([$(printf '"%s",' "${AI_STD_FILES[@]}" | sed 's/,$//')]))")
}
EOF
echo "  ✅ .ai-dev-standard.json"

# 安裝同步腳本
mkdir -p .github/scripts
curl -sL "https://raw.githubusercontent.com/${AI_STD_REPO}/${AI_STD_REF}/scripts/sync-ai-standard.sh" \
  -o .github/scripts/sync-ai-standard.sh
chmod +x .github/scripts/sync-ai-standard.sh
echo "  ✅ .github/scripts/sync-ai-standard.sh"

# 安裝 GitHub Action
curl -sL "https://raw.githubusercontent.com/${AI_STD_REPO}/${AI_STD_REF}/scripts/sync-ai-standard.yml" \
  -o .github/workflows/sync-ai-standard.yml
echo "  ✅ .github/workflows/sync-ai-standard.yml"

# 安裝 Git Hook
mkdir -p .githooks
curl -sL "https://raw.githubusercontent.com/${AI_STD_REPO}/${AI_STD_REF}/scripts/post-merge-hook.sh" \
  -o .githooks/post-merge
chmod +x .githooks/post-merge
git config core.hooksPath .githooks 2>/dev/null || true
echo "  ✅ .githooks/post-merge (git pull 後自動檢查更新)"

echo "  ✅ AI 開發標準已下載並啟用自動同步"

# --- 6. 完成 ---
echo ""
echo "=========================================="
echo "🎉 專案初始化完成！"
echo "=========================================="
echo ""
echo "📋 下一步："
echo "  1. 修改 CODEOWNERS 中的 @owner 為老闆的 GitHub 帳號"
echo "  2. 根據專案類型修改 .github/workflows/ci.yml"
echo "  3. 如需專案專屬設定，建立 CLAUDE.local.md（如 DB 連線資訊）"
echo "  4. git init && git add . && git commit -m 'init: 專案初始化'"
echo "  5. git remote add origin <repo-url> && git push -u origin main"
echo ""
echo "🔄 AI 標準自動同步已啟用："
echo "  - GitHub Action：每週一自動檢查並建立 PR"
echo "  - Git Hook：每次 git pull 後提示更新"
echo "  - 手動同步：bash .github/scripts/sync-ai-standard.sh"
echo ""
