#!/usr/bin/env bash
set -Eeuo pipefail

detect_repo() {
  if [[ -n "${GH_REPO:-}" ]]; then
    echo "${GH_REPO}"
    return
  fi
  local url
  url="$(git config --get remote.origin.url 2>/dev/null || true)"
  url="${url#git@github.com:}"
  url="${url#https://github.com/}"
  url="${url%.git}"
  [[ -n "${url}" ]] || return 1
  echo "${url}"
}

REPO="$(detect_repo || true)"
COMMAND="${1:-}"

usage() {
  cat <<'EOF'
Usage:
  scripts/issue_lifecycle.sh search --query "<symptom/page/error>"
  scripts/issue_lifecycle.sh create --title "<title>" --summary "<summary>" --area "<area>" --observed "<observed>" --next-action "<next>"
  scripts/issue_lifecycle.sh update --issue <number> --status <status> --summary "<summary>" --next-action "<next>"
  scripts/issue_lifecycle.sh request-close --issue <number> --summary "<summary>" --verification "<completed evidence>" --pr "<url-or-#>"
  scripts/issue_lifecycle.sh close --issue <number> --summary "<summary>" --verification "<completed evidence>" --pr "<url-or-#>" --rollback "<rollback>" --confirmed-by "<name>" --confirmation-note "<note>"

Statuses:
  accepted, planning, investigating, fixing, pr-opened, validating, deployment-decision, waiting-confirmation, closed

Notes:
  - --repo <owner/repo> overrides GH_REPO / git remote detection.
  - --dry-run prints the issue body/comment without changing GitHub.
  - request-close and close reject incomplete verification text such as pending, TBD, not run, or 待驗證.
EOF
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

need() {
  command -v "$1" >/dev/null 2>&1 || fail "missing required command: $1"
}

require_value() {
  [[ -n "${2:-}" ]] || fail "missing required option: $1"
}

issue_number() {
  local raw="${1:-}"
  raw="${raw#\#}"
  [[ "${raw}" =~ ^[0-9]+$ ]] || fail "--issue must be a number"
  echo "${raw}"
}

validate_status() {
  case "${1:-}" in
    accepted|planning|investigating|fixing|pr-opened|validating|deployment-decision|waiting-confirmation|closed) ;;
    *) fail "unsupported status: ${1:-}" ;;
  esac
}

reject_sensitive_text() {
  local text="$1"
  local pattern
  for pattern in \
    'gh[pousr]_[A-Za-z0-9_]{20,}' \
    'github_pat_[A-Za-z0-9_]{20,}' \
    '-----BEGIN [A-Z ]*PRIVATE KEY-----' \
    '(^|[^A-Za-z0-9_])(pass(word)?|passwd|pwd|token|api[_-]?key|secret|ssh[_-]?private[_-]?key)[[:space:]]*[:=][[:space:]]*[^[:space:]]+' \
    '(^|[^[:alnum:]])(密碼|權杖|私鑰)[[:space:]]*[:=：][[:space:]]*[^[:space:]]+'
  do
    if printf '%s' "${text}" | grep -Eiq -- "${pattern}"; then
      fail "refusing to write content that looks like a credential or private key"
    fi
  done
}

reject_unverified_evidence() {
  local value="$1"
  local normalized
  normalized="$(printf '%s' "${value}" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
  case "${normalized}" in
    pending|none|n/a|na|tbd|todo|unknown|notrun|notverified|未驗證|待驗證|尚未驗證|驗證待跑|檢查待跑|待跑|無)
      fail "completion confirmation requires completed verification evidence"
      ;;
  esac
  if printf '%s' "${value}" | grep -Eiq '(pending|tbd|todo|not[[:space:]]+run|not[[:space:]]+verified|待驗證|尚未驗證|驗證待跑|檢查待跑)'; then
    fail "completion confirmation requires completed verification evidence"
  fi
}

optional() {
  [[ -n "${1:-}" ]] && echo "$1" || echo "${2:-_not provided_}"
}

search_open_issues() {
  gh issue list --repo "${REPO}" --state open --search "$1 in:title,body" --limit "${2:-10}" \
    --json number,title,url,updatedAt \
    --jq '.[] | "#\(.number) \(.title) | \(.url) | updated \(.updatedAt)"'
}

search_duplicates() {
  local limit="$1"
  shift
  local query output
  for query in "$@"; do
    [[ -n "${query}" ]] || continue
    output="$(search_open_issues "${query}" "${limit}" || true)"
    [[ -n "${output}" ]] && printf '%s\n' "${output}"
  done | awk '!seen[$0]++'
}

comment_or_print() {
  if [[ "${DRY_RUN}" == "1" ]]; then
    echo "== dry-run: would comment on #$1 in ${REPO} =="
    cat "$2"
  else
    gh issue comment "$1" --repo "${REPO}" --body-file "$2"
  fi
}

[[ -z "${COMMAND}" || "${COMMAND}" == "-h" || "${COMMAND}" == "--help" ]] && { usage; exit 0; }
shift

QUERY=""; TITLE=""; SUMMARY=""; AREA=""; OBSERVED=""; EVIDENCE=""; SOURCE=""
STATUS="accepted"; NEXT_ACTION=""; BRANCH="$(git branch --show-current 2>/dev/null || true)"
PR=""; VALIDATION=""; DEPLOYMENT=""; ROLLBACK=""; ISSUE=""; LABELS=""; LIMIT="10"
FORCE_NEW="0"; DRY_RUN="0"; CONFIRMED_BY=""; CONFIRMATION_NOTE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="${2:-}"; shift 2 ;;
    --query) QUERY="${2:-}"; shift 2 ;;
    --title) TITLE="${2:-}"; shift 2 ;;
    --summary) SUMMARY="${2:-}"; shift 2 ;;
    --area) AREA="${2:-}"; shift 2 ;;
    --observed) OBSERVED="${2:-}"; shift 2 ;;
    --evidence|--reproduction) EVIDENCE="${2:-}"; shift 2 ;;
    --source) SOURCE="${2:-}"; shift 2 ;;
    --status) STATUS="${2:-}"; shift 2 ;;
    --next-action) NEXT_ACTION="${2:-}"; shift 2 ;;
    --branch) BRANCH="${2:-}"; shift 2 ;;
    --pr) PR="${2:-}"; shift 2 ;;
    --validation|--verification) VALIDATION="${2:-}"; shift 2 ;;
    --deployment) DEPLOYMENT="${2:-}"; shift 2 ;;
    --rollback) ROLLBACK="${2:-}"; shift 2 ;;
    --issue) ISSUE="$(issue_number "${2:-}")"; shift 2 ;;
    --labels) LABELS="${2:-}"; shift 2 ;;
    --limit) LIMIT="${2:-}"; shift 2 ;;
    --force-new) FORCE_NEW="1"; shift ;;
    --dry-run) DRY_RUN="1"; shift ;;
    --confirmed-by) CONFIRMED_BY="${2:-}"; shift 2 ;;
    --confirmation-note) CONFIRMATION_NOTE="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) fail "unknown option: $1" ;;
  esac
done

need gh
require_value "--repo" "${REPO}"

case "${COMMAND}" in
  search)
    require_value "--query" "${QUERY}"
    reject_sensitive_text "${QUERY}"
    search_open_issues "${QUERY}" "${LIMIT}" || true
    ;;
  create)
    require_value "--title" "${TITLE}"
    require_value "--summary" "${SUMMARY}"
    require_value "--area" "${AREA}"
    require_value "--observed" "${OBSERVED}"
    require_value "--next-action" "${NEXT_ACTION}"
    validate_status "${STATUS}"
    [[ -n "${QUERY}" ]] || QUERY="${TITLE} ${AREA} ${OBSERVED}"
    reject_sensitive_text "${TITLE}${SUMMARY}${AREA}${OBSERVED}${EVIDENCE}${SOURCE}${NEXT_ACTION}${QUERY}"
    matches="$(search_duplicates "${LIMIT}" "${QUERY}" "${TITLE}" "${AREA} ${OBSERVED}")"
    if [[ -n "${matches}" && "${FORCE_NEW}" != "1" ]]; then
      echo "Matching open issues found. Reuse one or rerun with --force-new after confirming this is not a duplicate." >&2
      echo "${matches}" >&2
      exit 2
    fi
    tmp="$(mktemp)"; trap 'rm -f "${tmp}"' EXIT
    cat > "${tmp}" <<EOF
## Problem Summary
${SUMMARY}

## Observed Behavior
${OBSERVED}

## Affected Area
${AREA}

## Evidence / Reproduction
$(optional "${EVIDENCE}")

## Progress Summary
| Status | Owner | Branch / PR | Verification | Next Action |
| --- | --- | --- | --- | --- |
| ${STATUS} | _unassigned_ | $(optional "${BRANCH}") | _pending_ | ${NEXT_ACTION} |

## Governance
- Duplicate search: \`${QUERY}\`
- Source context: $(optional "${SOURCE}")
- Close rule: verify first, then ask for explicit completion confirmation before closing.
- No-secrets rule: do not include credentials, private keys, or sensitive production data.
EOF
    if [[ "${DRY_RUN}" == "1" ]]; then
      cat "${tmp}"
    else
      create_args=(issue create --repo "${REPO}" --title "${TITLE}" --body-file "${tmp}")
      [[ -n "${LABELS}" ]] && create_args+=(--label "${LABELS}")
      gh "${create_args[@]}"
    fi
    ;;
  update)
    require_value "--issue" "${ISSUE}"
    require_value "--summary" "${SUMMARY}"
    require_value "--next-action" "${NEXT_ACTION}"
    validate_status "${STATUS}"
    reject_sensitive_text "${SUMMARY}${NEXT_ACTION}${BRANCH}${PR}${VALIDATION}${DEPLOYMENT}${ROLLBACK}"
    tmp="$(mktemp)"; trap 'rm -f "${tmp}"' EXIT
    cat > "${tmp}" <<EOF
## Issue Lifecycle Progress

| Status | Branch / PR | Verification | Next Action |
| --- | --- | --- | --- |
| ${STATUS} | $(optional "${BRANCH}")$(if [[ -n "${PR}" ]]; then printf ' / %s' "${PR}"; fi) | $(optional "${VALIDATION}" "_pending_") | ${NEXT_ACTION} |

${SUMMARY}

### Deployment / Rollback
- Deployment evidence: $(optional "${DEPLOYMENT}")
- Rollback: $(optional "${ROLLBACK}")

No secrets were intentionally included. Closure still requires completed verification and explicit confirmation.
EOF
    comment_or_print "${ISSUE}" "${tmp}"
    ;;
  request-close)
    require_value "--issue" "${ISSUE}"
    require_value "--summary" "${SUMMARY}"
    require_value "--verification" "${VALIDATION}"
    reject_unverified_evidence "${VALIDATION}"
    reject_sensitive_text "${SUMMARY}${VALIDATION}${PR}${DEPLOYMENT}${ROLLBACK}"
    tmp="$(mktemp)"; trap 'rm -f "${tmp}"' EXIT
    cat > "${tmp}" <<EOF
## Completion Confirmation Requested

| Status | PR | Verification | Next Action |
| --- | --- | --- | --- |
| waiting-confirmation | $(optional "${PR}") | ${VALIDATION} | Ask user/maintainer: #${ISSUE} 是否已完成，是否要關閉 issue？ |

${SUMMARY}

### Closeout Evidence
- Deployment evidence: $(optional "${DEPLOYMENT}")
- Rollback: $(optional "${ROLLBACK}")

This issue remains open until explicit completion confirmation.
EOF
    comment_or_print "${ISSUE}" "${tmp}"
    ;;
  close)
    require_value "--issue" "${ISSUE}"
    require_value "--summary" "${SUMMARY}"
    require_value "--verification" "${VALIDATION}"
    require_value "--pr" "${PR}"
    require_value "--rollback" "${ROLLBACK}"
    require_value "--confirmed-by" "${CONFIRMED_BY}"
    require_value "--confirmation-note" "${CONFIRMATION_NOTE}"
    reject_unverified_evidence "${VALIDATION}"
    reject_sensitive_text "${SUMMARY}${VALIDATION}${PR}${DEPLOYMENT}${ROLLBACK}${CONFIRMED_BY}${CONFIRMATION_NOTE}"
    tmp="$(mktemp)"; trap 'rm -f "${tmp}"' EXIT
    cat > "${tmp}" <<EOF
## Issue Closed After Confirmation

| Status | PR | Verification | Confirmed By |
| --- | --- | --- | --- |
| closed | ${PR} | ${VALIDATION} | ${CONFIRMED_BY} |

${SUMMARY}

### Confirmation
${CONFIRMATION_NOTE}

### Deployment / Rollback
- Deployment evidence: $(optional "${DEPLOYMENT}")
- Rollback: ${ROLLBACK}
EOF
    if [[ "${DRY_RUN}" == "1" ]]; then cat "${tmp}"; else gh issue comment "${ISSUE}" --repo "${REPO}" --body-file "${tmp}"; gh issue close "${ISSUE}" --repo "${REPO}" --reason completed; fi
    ;;
  *) fail "unknown command: ${COMMAND}" ;;
esac
