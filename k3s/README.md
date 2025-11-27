# K3s 自动化安装脚本

本目录包含用于自动安装和配置K3s（轻量级Kubernetes）的脚本。

## 📁 文件说明

| 文件名 | 描述 |
|--------|------|
| `install_k3s.sh` | K3s自动化安装脚本（支持Server和Agent模式） |
| `README.md` | 使用说明文档（本文件） |
| `CLUSTER_SETUP.md` | 1主2从集群详细配置指南 |
| `COMPATIBILITY.md` | Linux发行版兼容性说明 |

## ❓ 常见问题

### 1. 如何配置1主2从集群？

**答案：脚本完全支持！** 详细配置步骤请参考 [CLUSTER_SETUP.md](./CLUSTER_SETUP.md)

**快速说明：**
- **Master节点**：设置 `INSTALL_MODE="server"` 和 `SINGLE_NODE_MODE="false"`
- **Agent节点**：设置 `INSTALL_MODE="agent"`，并配置 `K3S_TOKEN` 和 `K3S_URL`
- 所有节点使用相同的 `K3S_VERSION`

### 2. 脚本可以在哪些Linux发行版上运行？

**答案：支持所有主流Linux发行版！** 详细兼容性列表请参考 [COMPATIBILITY.md](./COMPATIBILITY.md)

**完全支持的发行版：**
- ✅ Debian 11/12/13
- ✅ Ubuntu 20.04/22.04/24.04 LTS
- ✅ CentOS 7/8 / Rocky Linux 8/9
- ✅ RHEL 7/8/9
- ✅ Fedora 35+
- ✅ openSUSE Leap 15+
- ✅ Arch Linux
- ⚠️ Alpine Linux（需要额外配置）

## 🚀 快速开始

### 基本使用

```bash
# 下载脚本
wget https://raw.githubusercontent.com/your-repo/shell_scripts/main/k3s/install_k3s.sh

# 设置执行权限
chmod +x install_k3s.sh

# 以root用户运行（单节点Server模式）
su -
./install_k3s.sh
```

## ⚙️ 功能特性

### 🔧 核心功能

- ✅ **自动安装**：一键安装K3s Server或Agent
- ✅ **版本控制**：支持指定版本或使用最新版本
- ✅ **单节点模式**：支持单节点快速部署
- ✅ **集群模式**：支持多节点集群部署
- ✅ **自动配置**：自动配置kubectl和网络
- ✅ **服务管理**：自动启用和启动systemd服务

### 🛡️ 安全和稳定性

- ✅ 权限检查：确保以root用户运行
- ✅ 依赖检查：检查必要的系统依赖
- ✅ 已安装检查：避免重复安装
- ✅ 错误处理：完善的错误处理和日志
- ✅ 安装验证：安装后自动验证

### 📊 管理功能

- ✅ 状态查看：查看服务状态和节点信息
- ✅ 集群信息：显示集群配置和token
- ✅ 卸载功能：完全卸载K3s
- ✅ 日志查看：提供日志查看建议

## 📋 配置说明

### 配置变量

在脚本顶部的配置区域可以修改以下变量：

```bash
# 版本配置
K3S_VERSION="latest"  # latest, v1.28.0, v1.27.0 等

# 安装模式
INSTALL_MODE="server"  # server: 控制平面, agent: 工作节点

# 单节点模式
SINGLE_NODE_MODE=true  # true: 单节点, false: 集群

# 集群配置（agent模式）
K3S_TOKEN=""           # 从server节点获取
K3S_URL=""             # https://server-ip:6443

# 网络配置
K3S_NODE_IP=""         # 节点IP（留空自动检测）
K3S_NODE_EXTERNAL_IP="" # 外部IP

# 安装选项
INSTALL_OPTIONS=(
    "--write-kubeconfig-mode=644"
    "--tls-san=localhost"
)
```

### 安装选项说明

| 选项 | 说明 | 示例 |
|------|------|------|
| `--write-kubeconfig-mode` | kubeconfig文件权限 | `644` |
| `--tls-san` | TLS SAN（可添加多个） | `localhost`, `192.168.1.100` |
| `--node-ip` | 节点IP地址 | `192.168.1.100` |
| `--disable=traefik` | 禁用Traefik Ingress | 单节点模式常用 |
| `--system-default-registry` | 镜像仓库地址 | 国内加速使用 |

## 🎯 使用场景

### 1. 单节点Server安装（默认）

最简单的使用方式，适合开发和测试：

```bash
# 使用默认配置
./install_k3s.sh
```

### 2. 自定义版本安装

```bash
# 修改脚本中的K3S_VERSION变量
K3S_VERSION="v1.28.0"
./install_k3s.sh
```

### 3. 集群模式安装

#### 第一步：安装Server节点

```bash
# 在第一个节点上
SINGLE_NODE_MODE=false ./install_k3s.sh
```

安装完成后，获取token：
```bash
cat /var/lib/rancher/k3s/server/node-token
```

#### 第二步：安装Agent节点

```bash
# 在其他节点上，修改脚本配置：
INSTALL_MODE="agent"
K3S_TOKEN="从server节点获取的token"
K3S_URL="https://server-ip:6443"

./install_k3s.sh
```

### 4. 使用环境变量配置

```bash
# 通过环境变量覆盖配置
export INSTALL_MODE="agent"
export K3S_TOKEN="your-token-here"
export K3S_URL="https://192.168.1.100:6443"
export K3S_VERSION="v1.28.0"

./install_k3s.sh
```

## 📝 常用操作

### 查看状态

```bash
./install_k3s.sh status
```

### 查看集群信息

```bash
./install_k3s.sh info
```

### 卸载K3s

```bash
./install_k3s.sh uninstall
```

### 查看日志

```bash
# Server节点
journalctl -u k3s -f

# Agent节点
journalctl -u k3s-agent -f
```

## 🔍 验证安装

安装完成后，脚本会自动验证：

```bash
# 检查服务状态
systemctl status k3s

# 检查节点
kubectl get nodes

# 检查所有Pod
kubectl get pods -A

# 检查K3s版本
k3s --version
```

## 🛠️ 故障排除

### 常见问题

1. **端口6443被占用**
   - 检查是否有其他Kubernetes安装
   - 修改K3s端口或停止冲突服务

2. **Agent节点无法连接Server**
   - 检查防火墙设置
   - 验证K3S_URL和K3S_TOKEN是否正确
   - 检查网络连通性

3. **服务启动失败**
   ```bash
   # 查看详细日志
   journalctl -u k3s -f
   
   # 检查系统资源
   df -h
   free -h
   ```

4. **kubectl不可用**
   ```bash
   # 手动配置kubectl
   export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
   
   # 或创建别名
   alias kubectl='k3s kubectl'
   ```

### 调试模式

```bash
# 启用调试输出
DEBUG=1 ./install_k3s.sh
```

## 📊 系统要求

### 最低要求

- **操作系统**：Linux（推荐Ubuntu 20.04+, Debian 11+, CentOS 7+）
- **内核版本**：Linux 3.10+
- **内存**：512MB（推荐1GB+）
- **CPU**：1核心（推荐2核心+）
- **磁盘**：1GB可用空间（推荐10GB+）

### 网络要求

- **端口6443**：K3s API server端口
- **端口10250**：Kubelet API端口
- **端口8472**：Flannel VXLAN端口（如果使用Flannel）
- **端口51820/51821**：Flannel Wireguard端口（如果使用Wireguard）

## 🔒 安全建议

1. **防火墙配置**
   ```bash
   # 仅允许特定IP访问6443端口
   ufw allow from 192.168.1.0/24 to any port 6443
   ```

2. **Token安全**
   - 妥善保管server节点的token
   - 不要将token提交到版本控制

3. **TLS配置**
   - 添加所有需要访问的IP到`--tls-san`
   - 使用有效的域名和证书

## 📚 相关资源

- [K3s官方文档](https://docs.k3s.io/)
- [K3s GitHub仓库](https://github.com/k3s-io/k3s)
- [Kubernetes官方文档](https://kubernetes.io/docs/)

## 💡 最佳实践

1. **生产环境**
   - 使用固定版本号而非latest
   - 配置高可用（多Server节点）
   - 启用备份和监控

2. **开发环境**
   - 单节点模式即可
   - 可以禁用Traefik使用其他Ingress
   - 使用本地镜像仓库加速

3. **边缘计算**
   - 使用Agent模式连接远程Server
   - 配置合适的资源限制
   - 考虑网络延迟和带宽

---

**注意**：使用前请根据实际环境修改脚本顶部的配置变量！
