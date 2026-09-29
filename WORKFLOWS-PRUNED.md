# WORKFLOWS PRUNED — 自维护构建管线

本 fork 的 `.github/workflows/` 已于 2026-09-29 全量清理（原 59 个官方 workflow），
只保留本仓库自维护的 `build-publish.yml`。

## 纪律
- **禁止使用 GitHub「Sync fork」按钮**：它会把被删的官方 CI 原样还原。
- 上游同步一律走 `sync-upstream.sh`（fetch upstream → merge → 重删白名单外的 workflows → push tags）。
- 构建标准与 key-agent 统一：5 架构（linux amd64/arm64/armv7 + darwin amd64/arm64），
  产物 5×2=10 包（当前版本 + 上一版本），发布到 IHEP S3 `alloy-releases/`（CT100 半小时同步进内网）。
