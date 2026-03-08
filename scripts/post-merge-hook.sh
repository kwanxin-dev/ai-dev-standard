#!/bin/bash
# .githooks/post-merge — 每次 git pull 後檢查 AI 標準是否需要更新
# 安裝方式：git config core.hooksPath .githooks

if [ -f ".ai-dev-standard.json" ] && [ -f ".github/scripts/sync-ai-standard.sh" ]; then
  bash .github/scripts/sync-ai-standard.sh --check-only 2>/dev/null
fi
