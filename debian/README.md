# Debian 系统快捷初始化脚本

本目录包含用于快速初始化Debian系统的脚本。

## 📁 文件说明

| 文件名 | 适用系统 | 描述 |
|--------|----------|------|
| `init_debain12.sh` | Debian 12 (Bookworm) | Debian 12系统初始化脚本 |
| `init_debian13.sh` | Debian 13 (Trixie) | Debian 13系统初始化脚本（推荐） |

## 🚀 使用方法

### Debian 13 (推荐)

**重要提示**：Debian 13安装后默认没有sudo命令，此脚本必须直接以root用户运行！

```bash
# 下载脚本
wget https://raw.githubusercontent.com/your-repo/shell_scripts/main/debian/init_debian13.sh

# 设置执行权限
chmod +x init_debian13.sh

# 必须以root用户运行（不能使用sudo，因为系统初始化时没有sudo命令）
# 如果当前不是root用户，先切换：
su -

# 然后执行脚本
./init_debian13.sh
```

### Debian 12

```bash
# 下载脚本  
wget https://raw.githubusercontent.com/your-repo/shell_scripts/main/debian/init_debain12.sh

# 使用脚本
sudo ./init_debain12.sh
```

## ⚙️ 功能特性

### Debian 13脚本特性

#### 🔧 基础配置
- ✅ 系统更新和软件包安装
- ✅ APT镜像源配置（清华大学镜像）
- ✅ 时区和本地化设置
- ✅ Vim编辑器配置
- ✅ Bash环境优化

#### 👥 用户管理
- ✅ 创建用户并配置sudo权限
- ✅ 自动配置用户环境

#### 🌐 网络配置
- ✅ 静态IP配置（支持NetworkManager）
- ✅ DNS服务器配置
- ✅ 网络接口自动检测

#### ⏰ 时间同步
- ✅ Chrony NTP服务配置
- ✅ 中国NTP服务器池
- ✅ 自动时间同步

#### 🐳 Docker支持
- ✅ Docker CE最新版本安装
- ✅ Docker镜像加速配置
- ✅ 用户docker组权限配置
- ✅ 自定义数据目录

#### 🛡️ 安全和稳定性
- ✅ 交互式配置选择
- ✅ 配置文件自动备份
- ✅ 详细的日志输出
- ✅ 错误处理和回滚

## 📋 配置选项

### 可配置变量

在脚本顶部的配置区域可以修改以下变量：

```bash
# 系统配置
SYSTEM_TIMEZONE='Asia/Shanghai'           # 系统时区
SYSTEM_LOCALE='en_US.UTF-8'              # 系统本地化

# APT镜像源
APT_MIRROR_BASE_URL='https://mirrors.tuna.tsinghua.edu.cn/debian/'

# 时间同步服务器
NTP_SERVERS=(
    "ntp.aliyun.com"
    "ntp1.aliyun.com" 
    "ntp2.aliyun.com"
    "cn.pool.ntp.org"
)

# Docker配置
DOCKER_DATA_ROOT="/data/docker"           # Docker数据目录
DOCKER_REGISTRY_MIRRORS=(                 # Docker镜像源
    "http://docker.mirrors.ustc.edu.cn"
    "http://hub-mirror.c.163.com"
)

# 基础软件包
BASIC_PACKAGES=(                          # 要安装的软件包列表
    apt-transport-https ca-certificates
    wget curl vim git htop sudo tzdata
    # ... 更多软件包
)
```

## 🎯 使用场景

### 1. 全新服务器初始化

```bash
# 适用于刚安装的Debian 13系统
sudo ./init_debian13.sh
```

### 2. 开发环境搭建

脚本会自动安装开发常用工具：
- Git版本控制
- Vim编辑器（带配置）
- Docker容器平台
- 系统监控工具（htop, sysstat等）

### 3. 生产环境准备

- 时间同步服务配置
- 安全的用户权限管理
- 系统性能优化
- 日志管理配置

## 🔄 执行流程

1. **系统检查** - 确认Debian版本和权限
2. **交互配置** - 选择需要安装的功能
3. **系统更新** - 更新软件源和系统包
4. **基础配置** - 时区、本地化、环境变量
5. **用户配置** - 创建用户和sudo权限
6. **服务配置** - 时间同步、网络等服务
7. **软件安装** - Docker等可选软件
8. **完成验证** - 显示配置结果和建议

## 📝 注意事项

1. **权限要求**：
   - **Debian 13**：必须直接以root用户运行（不能使用sudo，因为系统初始化时没有sudo命令）
   - **Debian 12**：可以使用sudo运行
   - 脚本会自动检查root权限，如果不是root会提示错误
2. **网络要求**：需要互联网连接下载软件包
3. **交互模式**：脚本会询问配置选项，请根据需要选择
4. **备份机制**：重要配置文件会自动备份
5. **sudo安装**：脚本会在系统更新阶段自动安装sudo包，然后才能配置用户的sudo权限
6. **重启建议**：完成后建议重启系统应用所有更改

## 🛠️ 故障排除

### 常见问题

1. **APT源配置失败**
   - 检查网络连接
   - 尝试更换镜像源

2. **Docker安装失败** 
   - 检查系统架构兼容性
   - 查看错误日志

3. **时间同步问题**
   - 检查NTP服务器可达性
   - 验证防火墙设置

### 调试模式

```bash
# 启用调试输出
DEBUG=1 sudo ./init_debian13.sh
```

## 🔗 相关链接

- [Debian官方文档](https://www.debian.org/doc/)
- [Docker官方文档](https://docs.docker.com/)
- [Chrony配置指南](https://chrony.tuxfamily.org/documentation.html)

---

**注意**：使用前请根据实际环境修改脚本顶部的配置变量！
