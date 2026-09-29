#!/usr/bin/env bash
# sync-upstream.sh — Seek-Key-LTD/alloy 上游同步纪律
# 用途：跟随 grafana/alloy 上游版本，同时保持本 fork 的 CI 裁剪状态
# 纪律：禁止使用 GitHub「Sync fork」按钮（会还原被删的官方 CI），同步一律跑本脚本
#
# 用法: ./sync-upstream.sh [--tags-only]
#   默认: merge upstream main → 重删白名单外 workflows → push main
#   --tags-only: 只把上游新 tag 推到 fork（触发 build-publish）

set -euo pipefail

ORIGIN=https://github.com/Seek-Key-LTD/alloy.git
UPSTREAM=https://github.com/grafana/alloy.git
KEEP_WHITELIST='build-publish.yml'

main() {
  git remote add origin "$ORIGIN"  2>/dev/null || true
  git remote add upstream "$UPSTREAM" 2>/dev/null || true
  git fetch upstream --tags

  if [ "${1:-}" != "--tags-only" ]; then
    git checkout main
    git merge --ff-only upstream/main || {
      echo "!! upstream/main 无法 ff merge，请人工处理"; exit 1; }
    prune_workflows
    git push origin main
  fi

  # 推上游 tag 到 fork → 触发 build-publish
  git push origin --tags

  echo "✓ sync complete"
}

prune_workflows() {
  # 官方 CI 一律重删，白名单（我们的管线）保留
  find .github/workflows -type f ! -name "$KEEP_WHITELIST" -print -delete
  if [ -n "$(git status --porcelain .github/workflows)" ]; then
    git add .github/workflows
    git commit -m "chore(ci): re-prune upstream workflows (sync restore guard) — see WORKFLOWS-PRUNED.md"
  else
    echo "· workflows already clean"
  fi
}

main "$@"
