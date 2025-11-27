# K3s安装脚本 Linux发行版兼容性说明

本文档详细说明脚本支持哪些Linux发行版，以及各发行版的使用注意事项。

## ✅ 完全支持的发行版

### Debian系列

#### Debian 11 (Bullseye) ✅
- **状态**：完全支持
- **测试版本**：Debian 11.0+
- **注意事项**：
  - 默认没有sudo，需要直接以root运行
  - 确保curl已安装：`apt-get install -y curl`

#### Debian 12 (Bookworm) ✅
- **状态**：完全支持
- **测试版本**：Debian 12.0+
- **注意事项**：
  - 默认没有sudo，需要直接以root运行
  - 确保curl已安装：`apt-get install -y curl`

#### Debian 13 (Trixie) ✅
- **状态**：完全支持
- **测试版本**：Debian 13.0+
- **注意事项**：
  - 默认没有sudo，需要直接以root运行
  - 确保curl已安装：`apt-get install -y curl`

### Ubuntu系列

#### Ubuntu 20.04 LTS (Focal) ✅
- **状态**：完全支持
- **测试版本**：Ubuntu 20.04.0+
- **注意事项**：
  - 可以使用sudo运行
  - 确保curl已安装：`apt-get install -y curl`

#### Ubuntu 22.04 LTS (Jammy) ✅
- **状态**：完全支持
- **测试版本**：Ubuntu 22.04.0+
- **注意事项**：
  - 可以使用sudo运行
  - 确保curl已安装：`apt-get install -y curl`

#### Ubuntu 24.04 LTS (Noble) ✅
- **状态**：完全支持
- **测试版本**：Ubuntu 24.04.0+
- **注意事项**：
  - 可以使用sudo运行
  - 确保curl已安装：`apt-get install -y curl`

### RHEL/CentOS系列

#### CentOS 7 ✅
- **状态**：完全支持
- **测试版本**：CentOS 7.0+
- **注意事项**：
  - 需要安装curl：`yum install -y curl`
  - 确保systemd可用
  - 内核版本需要3.10+

#### CentOS 8 / Rocky Linux 8 ✅
- **状态**：完全支持
- **测试版本**：CentOS 8.0+, Rocky Linux 8.0+
- **注意事项**：
  - 使用dnf包管理器：`dnf install -y curl`
  - 确保systemd可用

#### CentOS 9 / Rocky Linux 9 ✅
- **状态**：完全支持
- **测试版本**：CentOS 9.0+, Rocky Linux 9.0+
- **注意事项**：
  - 使用dnf包管理器：`dnf install -y curl`
  - 确保systemd可用

#### RHEL 7 ✅
- **状态**：完全支持
- **测试版本**：RHEL 7.0+
- **注意事项**：
  - 需要订阅或使用开发者版本
  - 安装curl：`yum install -y curl`

#### RHEL 8 / RHEL 9 ✅
- **状态**：完全支持
- **测试版本**：RHEL 8.0+, RHEL 9.0+
- **注意事项**：
  - 需要订阅或使用开发者版本
  - 安装curl：`dnf install -y curl`

### 其他发行版

#### Fedora ✅
- **状态**：完全支持
- **测试版本**：Fedora 35+
- **注意事项**：
  - 使用dnf包管理器
  - 安装curl：`dnf install -y curl`

#### openSUSE Leap ✅
- **状态**：完全支持
- **测试版本**：openSUSE Leap 15.0+
- **注意事项**：
  - 使用zypper包管理器
  - 安装curl：`zypper install -y curl`

#### Alpine Linux ⚠️
- **状态**：部分支持
- **测试版本**：Alpine 3.15+
- **注意事项**：
  - 使用apk包管理器
  - 安装curl：`apk add curl`
  - 可能需要额外配置（Alpine使用musl libc）

#### Arch Linux ✅
- **状态**：完全支持
- **测试版本**：Arch Linux (rolling)
- **注意事项**：
  - 使用pacman包管理器
  - 安装curl：`pacman -S curl`

## 🔍 系统要求

### 最低要求

所有发行版都需要满足以下最低要求：

1. **内核版本**
   - Linux 3.10+（推荐4.14+）
   - 检查命令：`uname -r`

2. **内存**
   - 最低：512MB
   - 推荐：1GB+

3. **CPU**
   - 最低：1核心
   - 推荐：2核心+

4. **磁盘空间**
   - 最低：1GB可用空间
   - 推荐：10GB+

5. **网络**
   - 需要互联网连接（下载K3s）
   - 需要开放必要端口（6443, 10250等）

### 必要依赖

所有发行版都需要安装：

- **curl**：用于下载K3s安装脚本
- **systemd**：用于服务管理（大多数现代发行版默认包含）

## 📋 各发行版安装依赖命令

### Debian/Ubuntu
```bash
apt-get update
apt-get install -y curl
```

### RHEL/CentOS 7
```bash
yum install -y curl
```

### RHEL/CentOS 8+/Rocky Linux/Fedora
```bash
dnf install -y curl
```

### openSUSE
```bash
zypper install -y curl
```

### Alpine Linux
```bash
apk add curl
```

### Arch Linux
```bash
pacman -S curl
```

## ⚠️ 已知问题和限制

### 1. 容器运行时兼容性

K3s默认使用containerd作为容器运行时，某些发行版可能需要额外配置：

- **Alpine Linux**：可能需要额外配置
- **旧版本内核**：可能不支持某些容器功能

### 2. 网络插件兼容性

- **Flannel**：默认网络插件，大多数发行版支持
- **Calico/Cilium**：需要额外配置

### 3. SELinux支持

- **RHEL/CentOS**：默认启用SELinux，K3s会自动配置
- **其他发行版**：如果启用SELinux，可能需要额外配置

### 4. AppArmor支持

- **Ubuntu/Debian**：默认启用AppArmor，K3s会自动配置
- **其他发行版**：如果启用AppArmor，可能需要额外配置

## 🧪 测试状态

| 发行版 | 版本 | 测试状态 | 备注 |
|--------|------|----------|------|
| Debian | 11/12/13 | ✅ 已测试 | 完全支持 |
| Ubuntu | 20.04/22.04/24.04 | ✅ 已测试 | 完全支持 |
| CentOS | 7/8 | ✅ 已测试 | 完全支持 |
| Rocky Linux | 8/9 | ✅ 已测试 | 完全支持 |
| RHEL | 7/8/9 | ✅ 已测试 | 完全支持 |
| Fedora | 35+ | ✅ 已测试 | 完全支持 |
| openSUSE | Leap 15+ | ✅ 已测试 | 完全支持 |
| Alpine | 3.15+ | ⚠️ 部分测试 | 可能需要额外配置 |
| Arch | Rolling | ✅ 已测试 | 完全支持 |

## 🔧 发行版特定配置

### Debian/Ubuntu

无需特殊配置，脚本会自动检测并使用apt包管理器。

### RHEL/CentOS

如果使用SELinux，K3s会自动配置必要的SELinux策略。

### Alpine Linux

可能需要额外配置：
```bash
# 安装必要工具
apk add curl bash

# 确保使用bash而非sh
bash install_k3s.sh
```

## 📝 验证脚本兼容性

在运行脚本前，可以执行以下命令验证系统兼容性：

```bash
# 检查操作系统
cat /etc/os-release

# 检查内核版本
uname -r

# 检查必要工具
command -v curl && echo "curl: OK" || echo "curl: MISSING"
command -v systemctl && echo "systemd: OK" || echo "systemd: MISSING"

# 检查内存
free -h

# 检查磁盘空间
df -h
```

## 💡 推荐发行版

### 生产环境推荐

1. **Ubuntu 22.04 LTS** - 长期支持，稳定性好
2. **Debian 12** - 稳定可靠，资源占用低
3. **Rocky Linux 9** - RHEL兼容，企业级支持

### 开发/测试环境推荐

1. **Ubuntu 22.04/24.04** - 易于使用，文档丰富
2. **Debian 12/13** - 轻量级，适合资源受限环境
3. **Fedora** - 最新特性，适合测试

### 边缘计算推荐

1. **Alpine Linux** - 极轻量级（需要额外配置）
2. **Debian** - 轻量级且稳定
3. **Ubuntu Core** - 专为IoT设计

## 🆘 获取帮助

如果遇到发行版特定的问题：

1. 查看K3s官方文档：https://docs.k3s.io/
2. 检查系统日志：`journalctl -u k3s -f`
3. 启用调试模式：`DEBUG=1 ./install_k3s.sh`

---

**总结**：脚本支持所有主流的Linux发行版，特别是基于systemd的现代发行版。对于特殊发行版（如Alpine），可能需要额外配置。
