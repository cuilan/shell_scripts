# K3s安装脚本快速参考

## ❓ 问题1：如何配置1主2从集群？

### ✅ 答案：脚本完全支持！

### 快速配置步骤

#### Master节点（192.168.1.10）
```bash
# 配置
INSTALL_MODE="server"
SINGLE_NODE_MODE="false"
K3S_NODE_IP="192.168.1.10"

# 安装
./install_k3s.sh

# 获取Token
cat /var/lib/rancher/k3s/server/node-token
```

#### Agent节点（192.168.1.11 和 192.168.1.12）
```bash
# 配置
INSTALL_MODE="agent"
K3S_TOKEN="从Master获取的token"
K3S_URL="https://192.168.1.10:6443"
K3S_NODE_IP="192.168.1.11"  # Agent2使用.12

# 安装
./install_k3s.sh
```

### 验证集群
```bash
# 在Master节点执行
kubectl get nodes
# 应该看到3个节点
```

**详细文档**：查看 [CLUSTER_SETUP.md](./CLUSTER_SETUP.md)

---

## ❓ 问题2：脚本可以在哪些Linux发行版上运行？

### ✅ 答案：支持所有主流Linux发行版！

### 完全支持的发行版

| 发行版 | 版本 | 状态 |
|--------|------|------|
| **Debian** | 11/12/13 | ✅ 完全支持 |
| **Ubuntu** | 20.04/22.04/24.04 LTS | ✅ 完全支持 |
| **CentOS** | 7/8 | ✅ 完全支持 |
| **Rocky Linux** | 8/9 | ✅ 完全支持 |
| **RHEL** | 7/8/9 | ✅ 完全支持 |
| **Fedora** | 35+ | ✅ 完全支持 |
| **openSUSE** | Leap 15+ | ✅ 完全支持 |
| **Arch Linux** | Rolling | ✅ 完全支持 |
| **Alpine Linux** | 3.15+ | ⚠️ 需要额外配置 |

### 系统要求

- **内核**：Linux 3.10+（推荐4.14+）
- **内存**：512MB+（推荐1GB+）
- **CPU**：1核心+（推荐2核心+）
- **磁盘**：1GB+可用空间
- **依赖**：curl, systemd

### 安装依赖命令

```bash
# Debian/Ubuntu
apt-get update && apt-get install -y curl

# RHEL/CentOS 7
yum install -y curl

# RHEL/CentOS 8+/Rocky/Fedora
dnf install -y curl

# openSUSE
zypper install -y curl

# Alpine
apk add curl

# Arch
pacman -S curl
```

**详细文档**：查看 [COMPATIBILITY.md](./COMPATIBILITY.md)

---

## 📚 相关文档

- [集群配置指南](./CLUSTER_SETUP.md) - 详细的1主2从集群配置步骤
- [兼容性说明](./COMPATIBILITY.md) - 完整的Linux发行版兼容性列表
- [主README](./README.md) - 完整的使用说明和功能特性
