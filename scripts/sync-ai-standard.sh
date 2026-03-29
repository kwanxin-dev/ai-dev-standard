#!/bin/bash
# sync-ai-standard.sh — 從中央 repo 同步 AI 開發標準檔案
# 用法：bash .github/scripts/sync-ai-standard.sh [--check-only]
#
# 選項：
#   --check-only  僅檢查是否有更新，不執行同步（用於 git hook 提示）
#
# 環境變數：
#   GH_TOKEN      GitHub Token（私有 repo 需要）
#   AI_STD_REPO   來源 repo（預設讀取 .ai-dev-standard.json）
#   AI_STD_REF    來源分支（預設 main）

set -euo pipefail

# --- 常數 ---
CONFIG_FILE=".ai-dev-standard.json"
CHECK_ONLY=false

if [[ "${1:-}" == "--check-only" ]]; then
  CHECK_ONLY=true
fi

# --- 讀取設定 ---
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ 找不到 $CONFIG_FILE，請先執行 init 或 enable-sync"
  exit 2
fi

SOURCE_REPO=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['source_repo'])")
SOURCE_REF=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('source_ref', 'main'))")
SYNCED_COMMIT=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('synced_commit', ''))")

# --- 取得中央 repo 最新 commit SHA ---
AUTH_HEADER=""
if [[ -n "${GH_TOKEN:-}" ]]; then
  AUTH_HEADER="-H \"Authorization: token ${GH_TOKEN}\""
fi

LATEST_SHA=$(curl -sL ${AUTH_HEADER} \
  "https://api.github.com/repos/${SOURCE_REPO}/commits/${SOURCE_REF}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('sha',''))" 2>/dev/null || echo "")

if [[ -z "$LATEST_SHA" ]]; then
  echo "❌ 無法取得 ${SOURCE_REPO} 的最新 commit，請檢查網路或 Token"
  exit 1
fi

# --- 比較版本 ---
if [[ "$LATEST_SHA" == "$SYNCED_COMMIT" ]]; then
  echo "✅ AI 開發標準已是最新版本（${LATEST_SHA:0:7}）"
  exit 0
fi

echo "🔄 發現新版本：${SYNCED_COMMIT:0:7} → ${LATEST_SHA:0:7}"

if [[ "$CHECK_ONLY" == true ]]; then
  echo ""
  echo "⚠️  AI 開發標準有新版本可用。"
  echo "   執行 'bash .github/scripts/sync-ai-standard.sh' 進行更新。"
  exit 1
fi

# --- 讀取要同步的檔案清單 ---
FILES=$(python3 -c "
import json
config = json.load(open('$CONFIG_FILE'))
for f in config.get('files', []):
    print(f)
")

if [[ -z "$FILES" ]]; then
  echo "❌ 設定檔中沒有定義要同步的檔案"
  exit 1
fi

# --- 下載並覆寫 ---
echo "📥 開始下載標準檔案..."
DOWNLOAD_COUNT=0
FAIL_COUNT=0

while IFS= read -r filename; do
  URL="https://raw.githubusercontent.com/${SOURCE_REPO}/${SOURCE_REF}/${filename}"
  HTTP_CODE=$(curl -sL -w "%{http_code}" ${AUTH_HEADER} -o "/tmp/_ai_std_${filename//\//_}" "$URL")

  if [[ "$HTTP_CODE" == "200" ]]; then
    mkdir -p "$(dirname "$filename")"
    cp "/tmp/_ai_std_${filename//\//_}" "$filename"
    echo "  ✅ ${filename}"
    DOWNLOAD_COUNT=$((DOWNLOAD_COUNT + 1))
  else
    echo "  ❌ ${filename}（HTTP ${HTTP_CODE}）"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi

  rm -f "/tmp/_ai_std_${filename//\//_}"
done <<< "$FILES"

if [[ $FAIL_COUNT -gt 0 ]]; then
  echo ""
  echo "⚠️  ${FAIL_COUNT} 個檔案下載失敗，同步未完成"
  exit 1
fi

# --- 更新元數據 ---
python3 -c "
import json
from datetime import datetime, timezone

config = json.load(open('$CONFIG_FILE'))
config['synced_commit'] = '$LATEST_SHA'
config['synced_at'] = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')

with open('$CONFIG_FILE', 'w') as f:
    json.dump(config, f, indent=2, ensure_ascii=False)
    f.write('\n')
"

echo ""
echo "✅ 同步完成！已更新 ${DOWNLOAD_COUNT} 個檔案（${LATEST_SHA:0:7}）"
