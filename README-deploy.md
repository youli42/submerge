# youli-compose —— 仅部署文件

从 [gentslava/submerge](https://github.com/gentslava/submerge) fork，此分支只保留**在 podman 上部署所需要的文件**，不含源码。

## 保留的文件

| 文件 | 作用 |
|---|---|
| `docker-compose.yml` | 上游原始定义，生成脚本的输入 |
| `docker-compose.podman.yml` | **生成物**，实际使用（已改 healthcheck） |
| `gen-podman-compose.py` | 由上面的文件生成 podman 版 |
| `fix-ifnames.sh` | netns 网卡名守护（eth0=egress / lan0=gateway-lan） |
| `.env.example` | 环境变量模板 |

## 为什么要生成 podman 版

podman-compose 1.3.0 序列化 `healthcheck.test` 的 CMD 列表时会把 `node -e` 脚本丢给 `/bin/sh -c`，dash 语法错误 → 容器永远 unhealthy → 依赖 `service_healthy` 的 submerge/mihomo 起不来。生成脚本把它改写成字符串形式。

## 用法

```bash
cp .env.example .env        # 填值，.env 已被 gitignore
podman-compose -f docker-compose.podman.yml up -d
```

运行时目录 `mihomo/`、`domain-rules/` 不入库（含节点配置与密钥），需在部署机上自备。

## 同步上游

```bash
git fetch upstream
git merge upstream/master          # 或 rebase
python gen-podman-compose.py       # 重新生成 podman 版
```
