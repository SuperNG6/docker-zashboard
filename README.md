# docker-zashboard

自动跟踪上游 [Zephyruso/zashboard](https://github.com/Zephyruso/zashboard) 的 Release，构建并推送多平台 Docker 镜像到 Docker Hub 和 GHCR。

## 功能

- 定时轮询上游 release（每周一 UTC 03:00）
- 上游出现新版本时自动构建并推送 Docker Hub + GHCR
- 上游出现新版本时，同步当前仓库的 release tag 与 GitHub Release
- 每个 release 会构建所有 `dist*.zip` 资产变体
- 主标签（无变体后缀）固定对应 `dist.zip`
- 多平台镜像：`linux/amd64`、`linux/arm64`、`linux/arm/v7`
- 镜像仓库名：`superng6/zashboard`（Docker Hub）与 `ghcr.io/superng6/zashboard`（GHCR）
- 已同步过的同版本 release 会自动跳过，不重复更新
- 避免重复构建：如果目标 tag 已存在则自动跳过
- 支持 `workflow_dispatch` 手动指定 tag / asset / 强制重建

## 镜像地址

默认推送到：

- `superng6/zashboard`
- `ghcr.io/superng6/zashboard`

## 使用方式

1. 将仓库推送到 GitHub。
2. 确认仓库 Actions 已启用。
3. 首次运行可在 Actions 页面手动触发 `Build and Push Container Images`。
4. 之后由定时任务每周自动检查上游 release 并构建。

## 默认 Tag 规则

- `vX.Y.Z`
- `X.Y.Z`
- `X.Y`
- `X`
- `latest`（仅非预发布版本）
- `sha-<commit>`

## Docker 设计说明

- 使用多阶段构建：
  - 构建阶段下载并解压上游发布产物
  - 运行阶段使用官方 `caddy:2-alpine` + 静态文件
- 运行容器使用 `caddy` 用户
- SPA 路由回退到 `index.html`
- `.dockerignore` 最小化构建上下文
