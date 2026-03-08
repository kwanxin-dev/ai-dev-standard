#!/bin/bash
# enable-sync.sh — 在既有專案啟用 AI 開發標準自動同步
#
# 用法（在專案根目錄執行）：
#   curl -sL https://raw.githubusercontent.com/<your-org>/ai-dev-standard/main/enable-sync.sh | bash
#
# 或本地執行：
#   bash /path/to/ai-dev-standard/enable-sync.sh

set -euo pipefail

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
)

echo "🔧 啟用 AI 開發標準自動同步"
echo "   來源：${AI_STD_REPO} (${AI_STD_REF})"
echo ""

# --- Step 1: 備份既有的 AI 標準檔案為 .local.md ---
echo "📦 Step 1: 備份既有檔案..."
for f in AGENTS.md CLAUDE.md CODEX.md GEMINI.md ANTIGRAVITY.md; do
  if [ -f "$f" ]; then
    LOCAL_NAME="${f%.md}.local.md"
    if [ -f "$LOCAL_NAME" ]; then
      echo "  ⚠️  ${LOCAL_NAME} 已存在，跳過備份（${f} 將被覆寫）"
    else
      cp "$f" "$LOCAL_NAME"
      echo "  ✅ ${f} → ${LOCAL_NAME}"
    fi
  fi
done

# --- Step 2: 下載中央版本 ---
echo ""
echo "📥 Step 2: 下載中央標準檔案..."
for f in "${AI_STD_FILES[@]}"; do
  URL="https://raw.githubusercontent.com/${AI_STD_REPO}/${AI_STD_REF}/${f}"
  HTTP_CODE=$(curl -sL -w "%{http_code}" -o "$f" "$URL")
  if [[ "$HTTP_CODE" == "200" ]]; then
    echo "  ✅ ${f}"
  else
    echo "  ❌ ${f}（HTTP ${HTTP_CODE}）"
  fi
done

# --- Step 3: 取得最新 commit SHA ---
LATEST_SHA=$(curl -sL \
  "https://api.github.com/repos/${AI_STD_REPO}/commits/${AI_STD_REF}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('sha','unknown'))" 2>/dev/null || echo "unknown")

# --- Step 4: 建立同步元數據 ---
echo ""
echo "📋 Step 3: 建立同步設定..."
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

# --- Step 5: 安裝同步腳本 ---
echo ""
echo "🔧 Step 4: 安裝同步腳本..."
mkdir -p .github/scripts
curl -sL "https://raw.githubusercontent.com/${AI_STD_REPO}/${AI_STD_REF}/scripts/sync-ai-standard.sh" \
  -o .github/scripts/sync-ai-standard.sh
chmod +x .github/scripts/sync-ai-standard.sh
echo "  ✅ .github/scripts/sync-ai-standard.sh"

# --- Step 6: 安裝 GitHub Action ---
mkdir -p .github/workflows
curl -sL "https://raw.githubusercontent.com/${AI_STD_REPO}/${AI_STD_REF}/scripts/sync-ai-standard.yml" \
  -o .github/workflows/sync-ai-standard.yml
echo "  ✅ .github/workflows/sync-ai-standard.yml"

# --- Step 7: 安裝 Git Hook ---
mkdir -p .githooks
curl -sL "https://raw.githubusercontent.com/${AI_STD_REPO}/${AI_STD_REF}/scripts/post-merge-hook.sh" \
  -o .githooks/post-merge
chmod +x .githooks/post-merge
git config core.hooksPath .githooks 2>/dev/null || true
echo "  ✅ .githooks/post-merge"

# --- 完成 ---
echo ""
echo "════════════════════════════════════════════"
echo "✅ AI 開發標準自動同步已啟用！"
echo ""
echo "同步機制："
echo "  1. GitHub Action：每週一自動檢查並建立 PR"
echo "  2. Git Hook：每次 git pull 後提示是否有更新"
echo "  3. 手動執行：bash .github/scripts/sync-ai-standard.sh"
echo ""
echo "專案專屬設定："
echo "  - CLAUDE.local.md   （Claude Code 專屬覆寫）"
echo "  - AGENTS.local.md   （共用規則專屬覆寫）"
echo "  - 其他 *.local.md   （各工具專屬覆寫）"
echo ""
echo "中央標準檔案（自動同步，勿手動編輯）："
echo "  - AGENTS.md, CLAUDE.md, CODEX.md, GEMINI.md, ANTIGRAVITY.md"
echo "  - skills-development-guide.md, skills-memory-standard.md"
echo "════════════════════════════════════════════"
