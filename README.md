# docker-zashboard

自动跟踪上游 [Zephyruso/zashboard](https://github.com/Zephyruso/zashboard) 的 Release，构建并推送多平台 Docker 镜像到 Docker Hub 和 GHCR。

## 镜像地址

| 仓库 | 镜像名 |
|------|--------|
| Docker Hub | `superng6/zashboard` |
| GitHub Container Registry | `ghcr.io/superng6/zashboard` |

---

## 快速上手

### docker run

```bash
docker run -d \
  --name zashboard \
  --restart unless-stopped \
  -p 8080:8080 \
  superng6/zashboard:latest
```

访问 `http://<your-server-ip>:8080` 即可打开 zashboard 面板。

---

### Docker Compose

```yaml
services:
  zashboard:
    image: superng6/zashboard:latest
    container_name: zashboard
    restart: unless-stopped
    ports:
      - "8080:8080"
```

```bash
docker compose up -d
```

---

### 与 Mihomo / Clash Meta 集成

zashboard 需要连接到 Mihomo（或 Clash Meta）的外部控制接口（external-controller）。推荐将两者放在同一 Docker 网络中：

```yaml
services:
  mihomo:
    image: metacubex/mihomo:latest
    container_name: mihomo
    restart: unless-stopped
    network_mode: host          # 或自定义 bridge 网络
    volumes:
      - ./mihomo:/root/.config/mihomo

  zashboard:
    image: superng6/zashboard:latest
    container_name: zashboard
    restart: unless-stopped
    ports:
      - "8080:8080"
    network_mode: host          # 与 mihomo 同 host 网络，可直接访问 127.0.0.1:9090
```

打开 `http://<your-server-ip>:8080`，在设置页面填写外部控制地址（默认 `http://127.0.0.1:9090`）和 Secret 即可。

> **提示**：如果 Mihomo 的 `external-controller` 未配置 `external-ui`，则仍然需要单独运行本容器作为 UI 来源。

---

## 环境变量 / 端口配置

| 环境变量 | 默认值 | 说明 |
|----------|--------|------|
| `PORT` | `8080` | 容器内 HTTP 监听端口 |

修改端口示例（改为 80）：

```bash
docker run -d \
  --name zashboard \
  -e PORT=80 \
  -p 80:80 \
  superng6/zashboard:latest
```

---

## 镜像变体

每个 release 会构建上游所有 `dist*.zip` 资产对应的变体镜像：

| 变体 Tag 后缀 | 对应上游资产 | 说明 |
|--------------|-------------|------|
| 无后缀（`latest`、`vX.Y.Z` 等） | `dist.zip` | 默认完整版，含 UI 字体 |
| `-no-fonts` | `dist-no-fonts.zip` | 不含内嵌字体，体积更小，由系统字体渲染 |

示例：

```bash
# 完整版
docker pull superng6/zashboard:latest

# 无字体版
docker pull superng6/zashboard:latest-no-fonts
```

---

## Tag 规则

每个版本会同时打以下 Tag（以 `v1.2.3` 为例）：

| Tag | 示例 |
|-----|------|
| 完整版本号（带 v 前缀） | `v1.2.3` |
| 完整版本号（不带 v） | `1.2.3` |
| 主次版本号 | `1.2` |
| 主版本号 | `1` |
| `latest`（仅非预发布） | `latest` |
| 短 commit SHA | `sha-a1b2c3d` |

---

## 自动化构建（CI/CD）

### 功能

- 每周一 UTC 03:00 定时轮询上游 release
- 上游出现新版本时自动构建并推送 Docker Hub + GHCR
- 上游出现新版本时，同步当前仓库的 release tag 与 GitHub Release
- 每个 release 构建所有 `dist*.zip` 资产变体
- 多平台：`linux/amd64`、`linux/arm64`、`linux/arm/v7`
- 已同步的版本自动跳过，不重复构建
- 支持 `workflow_dispatch` 手动指定 tag / asset / 强制重建

### 手动触发

1. 进入仓库 **Actions** 页面
2. 选择 **Build and Push Container Images**
3. 点击 **Run workflow**，可选填：
   - `release_tag`：指定上游 tag（留空则用 latest）
   - `asset_name`：指定构建某一资产（留空则构建所有）
   - `force_build`：即使 tag 已存在也强制重建

### 所需 Secrets

| Secret | 说明 |
|--------|------|
| `DOCKERHUB_USERNAME` | Docker Hub 用户名（不配置则跳过推送到 Docker Hub） |
| `DOCKERHUB_TOKEN` | Docker Hub Access Token |
| `CR_PAT`（可选） | GHCR 个人访问令牌，缺省时自动使用 `GITHUB_TOKEN` |

---

## Docker 设计说明

- 多阶段构建：
  - **fetcher 阶段**：从上游 release 下载并解压静态前端产物
  - **运行阶段**：基于官方 `caddy:2-alpine`，仅包含静态文件
- 运行容器使用非 root 的 `caddy` 用户
- Caddy 配置启用 gzip/zstd 压缩，SPA 路由自动回退至 `index.html`
- `.dockerignore` 最小化构建上下文
