#!/usr/bin/env bash
# sync-upstream.sh — Seek-Key-LTD/alloy 上游同步纪律
# 用途：跟随 grafana/alloy 上游版本，同时保持本 fork 的 CI 裁剪状态
# 纪律：禁止使用 GitHub「Sync fork」按钮（会还原被删的官方 CI），同步一律跑本脚本
#
# 用法: ./sync-upstream.sh [--tags-only]
#   默认: merge upstream main → 重删白名单外 workflows → push main → 在 main 上打最新版 tag 触发构建
#   --tags-only: 跳过 merge/重删，只做打 tag 触发

set -euo pipefail

ORIGIN=https://github.com/Seek-Key-LTD/alloy.git
UPSTREAM=https://github.com/grafana/alloy.git
KEEP_WHITELIST='build-publish.yml'

main() {
  git remote add origin "$ORIGIN" 2>/dev/null || true
  git remote add upstream "$UPSTREAM" 2>/dev/null || true
  git fetch upstream main --tags

  if [ "${1:-}" != "--tags-only" ]; then
    git checkout main
    git merge --ff-only upstream/main || {
      echo "!! upstream/main 无法 ff merge（本 fork main 有自己的 commit），改用 merge："
      git merge upstream/main || { echo "!! merge 冲突，请人工处理"; exit 1; }
    }
    prune_workflows
    git push origin main
  fi

  # 在我们的 main（已 merge upstream）上打同名 tag 再推——
  # 禁止直推上游原始 tag：其树上有官方 CI，会误触发（见 WORKFLOWS-PRUNED.md）
  LATEST_UPSTREAM="$(git tag --list 'v*' --sort=-version:refname --merged upstream/main | head -1)"
  if [ -n "${LATEST_UPSTREAM:-}" ]; then
    if git rev-parse "refs/tags/${LATEST_UPSTREAM}^{commit}" >/dev/null 2>&1 \
       && [ "$(git rev-parse "refs/tags/${LATEST_UPSTREAM}^{commit}")" = "$(git rev-parse main)" ]; then
      echo "· ${LATEST_UPSTREAM} 已指向我们的 main，跳过"
    else
      git tag -f "${LATEST_UPSTREAM}" main
      git push origin "refs/tags/${LATEST_UPSTREAM}"
      echo "✓ tagged ${LATEST_UPSTREAM} on our main → build-publish 触发"
    fi
  fi

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
