# ============================================
# init-project.ps1 — AI 輔助開發專案初始化腳本（Windows）
# ============================================
# 用法：在新專案根目錄執行
#   .\init-project.ps1
# ============================================

Write-Host "🚀 正在初始化 AI 輔助開發專案..." -ForegroundColor Cyan
Write-Host ""

# --- 1. 建立 .ai-memory/ 目錄結構 ---
Write-Host "📁 建立 .ai-memory/ 記憶目錄..." -ForegroundColor Yellow

$dirs = @(
  ".ai-memory\decisions",
  ".ai-memory\progress",
  ".ai-memory\issues",
  ".ai-memory\context",
  ".ai-memory\lessons"
)
foreach ($dir in $dirs) {
  New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

# 決策索引
@"
# 架構決策索引

| 日期 | 標題 | 狀態 | AI |
|------|------|------|-----|
<!-- 範例：| 2025-03-15 | 選擇 JWT 認證 | ✅ 已執行 | Claude | -->
"@ | Set-Content -Path ".ai-memory\decisions\_index.md" -Encoding UTF8

# 進度索引
@"
# 全域進度總覽

> 最後更新：（由 AI 自動更新）

## 模組進度
| 模組 | 狀態 | 負責 AI | 最後更新 |
|------|------|---------|---------|
<!-- 範例：| 前端 | 🔄 進行中 | Gemini | 2025-03-16 | -->
"@ | Set-Content -Path ".ai-memory\progress\_index.md" -Encoding UTF8

# Issues
@"
# 未解決問題

<!-- 格式：
## [日期 | AI] 問題標題
- 描述：
- 優先級：🔴高 / 🟡中 / 🟢低
- 相關檔案：
-->
"@ | Set-Content -Path ".ai-memory\issues\open.md" -Encoding UTF8

@"
# 已解決問題

<!-- 已解決的問題從 open.md 移到這裡，保留歷史參考 -->
"@ | Set-Content -Path ".ai-memory\issues\resolved.md" -Encoding UTF8

# 問題追蹤索引
@"
# 問題追蹤索引

- [未解決問題](./open.md)
- [已解決問題](./resolved.md)
"@ | Set-Content -Path ".ai-memory\issues\_index.md" -Encoding UTF8

# 經驗索引
@"
# 經驗學習索引

| 日期 | 標題 | 標籤 | AI |
|------|------|------|-----|
<!-- 範例：| 2025-03-18 | AG Grid 佈局陷阱 | AG-Grid, CSS | Claude | -->
"@ | Set-Content -Path ".ai-memory\lessons\_index.md" -Encoding UTF8

# 架構文件
@"
# 系統架構概觀

> 由 AI 在開發過程中維護，記錄系統的整體架構。

## 技術棧
<!-- 填入專案使用的技術 -->

## 目錄結構
<!-- 填入專案的目錄結構說明 -->

## 模組關係
<!-- 填入各模組之間的關係 -->
"@ | Set-Content -Path ".ai-memory\architecture.md" -Encoding UTF8

@"
# 環境設定

## 開發環境需求
<!-- 填入所需的開發工具和版本 -->

## 安裝步驟
<!-- 填入安裝步驟 -->

## 環境變數
<!-- 填入需要的環境變數（不含實際值） -->
"@ | Set-Content -Path ".ai-memory\setup.md" -Encoding UTF8

@"
# 開發規範

> 本檔案補充 AGENTS.md 中的通用程式碼規範，記錄本專案的特定慣例。

## 專案特定規範
<!-- 填入本專案特有的開發規範 -->
"@ | Set-Content -Path ".ai-memory\coding-standards.md" -Encoding UTF8

Write-Host "  ✅ .ai-memory/ 目錄建立完成" -ForegroundColor Green

# --- 2. 建立 GitHub Actions CI ---
Write-Host "📦 建立 CI/CD Pipeline..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path ".github\workflows" -Force | Out-Null
New-Item -ItemType Directory -Path ".github\ISSUE_TEMPLATE" -Force | Out-Null

@"
name: CI

on:
  pull_request:
    branches: [main, develop]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: 安裝依賴
        run: npm install

      - name: 程式碼檢查
        run: npm run lint

      - name: 單元測試
        run: npm test

      - name: 建置確認
        run: npm run build
"@ | Set-Content -Path ".github\workflows\ci.yml" -Encoding UTF8

Write-Host "  ✅ .github/workflows/ci.yml 建立完成" -ForegroundColor Green

# --- 2-1. 建立 GitHub Issue / PR 模板 ---
Write-Host "🧾 建立 GitHub issue / PR 模板..." -ForegroundColor Yellow

@"
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
"@ | Set-Content -Path ".github\ISSUE_TEMPLATE\feature.yml" -Encoding UTF8

@"
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
"@ | Set-Content -Path ".github\ISSUE_TEMPLATE\bug.yml" -Encoding UTF8

@"
## Summary
-

## Issue / Milestone
- Issue:
- Milestone:
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

### Evidence
- Preview / Artifact:
- CI / Smoke / Healthcheck:

## Rollback
-
"@ | Set-Content -Path ".github\PULL_REQUEST_TEMPLATE.md" -Encoding UTF8

Write-Host "  ✅ GitHub issue / PR 模板建立完成" -ForegroundColor Green

# --- 3. 建立 CODEOWNERS ---
Write-Host "👔 建立 CODEOWNERS..." -ForegroundColor Yellow
@"
# 所有 PR 自動指派老闆 review
# 請將下方的 @owner 替換為老闆的 GitHub 帳號
* @owner
"@ | Set-Content -Path "CODEOWNERS" -Encoding UTF8

Write-Host "  ✅ CODEOWNERS 建立完成（請修改 @owner 為實際帳號）" -ForegroundColor Green

# --- 4. 建立 .gitignore ---
Write-Host "📝 建立 .gitignore..." -ForegroundColor Yellow
@"
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
"@ | Set-Content -Path ".gitignore" -Encoding UTF8

Write-Host "  ✅ .gitignore 建立完成" -ForegroundColor Green

# --- 5. 完成 ---
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "🎉 專案初始化完成！" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 下一步："
Write-Host "  1. 複製 AGENTS.md, CLAUDE.md, CODEX.md, GEMINI.md, ANTIGRAVITY.md 到專案根目錄"
Write-Host "  2. 修改 CODEOWNERS 中的 @owner 為老闆的 GitHub 帳號"
Write-Host "  3. 根據專案類型修改 .github/workflows/ci.yml"
Write-Host "  4. 參考 skills-memory-standard.md 配置 skill 與 ai-memory-hub"
Write-Host "  5. git init; git add .; git commit -m 'init: 專案初始化'"
Write-Host "  6. git remote add origin <repo-url>; git push -u origin main"
Write-Host ""
