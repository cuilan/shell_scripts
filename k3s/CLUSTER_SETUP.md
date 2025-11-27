# K3s 1主2从集群配置指南

本文档详细说明如何使用脚本配置1个主节点（Server）和2个从节点（Agent）的K3s集群。

## 📋 集群架构

```
┌─────────────────┐
│   Master Node   │  (Server)
│   192.168.1.10  │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
┌───▼───┐ ┌───▼───┐
│Agent1 │ │Agent2 │  (Agent)
│.1.11  │ │.1.12  │
└───────┘ └───────┘
```

## 🚀 部署步骤

### 前置准备

1. **准备3台服务器**
   - Master: 192.168.1.10
   - Agent1: 192.168.1.11
   - Agent2: 192.168.1.12

2. **确保网络连通性**
   ```bash
   # 在每台机器上测试
   ping 192.168.1.10
   ping 192.168.1.11
   ping 192.168.1.12
   ```

3. **确保防火墙开放必要端口**
   - 6443: K3s API server
   - 10250: Kubelet API
   - 8472: Flannel VXLAN
   - 51820/51821: Flannel Wireguard（如果使用）

### 步骤1：安装Master节点（Server）

在 **192.168.1.10** 上执行：

```bash
# 1. 下载脚本
wget https://raw.githubusercontent.com/your-repo/shell_scripts/main/k3s/install_k3s.sh
chmod +x install_k3s.sh

# 2. 编辑脚本，修改配置
nano install_k3s.sh
```

**配置内容：**
```bash
# 版本配置
K3S_VERSION="latest"  # 或指定版本如 "v1.28.0"

# 安装模式（Master节点）
INSTALL_MODE="server"

# 集群模式（不是单节点）
SINGLE_NODE_MODE=false

# 网络配置
K3S_NODE_IP="192.168.1.10"  # Master节点IP
K3S_NODE_EXTERNAL_IP=""      # 如果有外部IP

# 安装选项
INSTALL_OPTIONS=(
    "--write-kubeconfig-mode=644"
    "--tls-san=192.168.1.10"        # Master节点IP
    "--tls-san=localhost"            # 本地访问
    # 集群模式不需要禁用Traefik
)
```

**执行安装：**
```bash
su -
./install_k3s.sh
```

**安装完成后，获取Token：**
```bash
# 保存token到文件（方便后续使用）
cat /var/lib/rancher/k3s/server/node-token > /tmp/k3s-token.txt

# 或者直接查看
cat /var/lib/rancher/k3s/server/node-token
```

**记录以下信息：**
- Token: `K10...` (从node-token文件获取)
- Server URL: `https://192.168.1.10:6443`

### 步骤2：安装Agent1节点

在 **192.168.1.11** 上执行：

```bash
# 1. 下载脚本
wget https://raw.githubusercontent.com/your-repo/shell_scripts/main/k3s/install_k3s.sh
chmod +x install_k3s.sh

# 2. 编辑脚本，修改配置
nano install_k3s.sh
```

**配置内容：**
```bash
# 版本配置（必须与Master节点相同）
K3S_VERSION="latest"  # 必须与Master节点版本一致

# 安装模式（Agent节点）
INSTALL_MODE="agent"

# 集群配置（从Master节点获取）
K3S_TOKEN="K10xxxxxxxxxxxxxxxxxxxx"  # 从Master节点获取的token
K3S_URL="https://192.168.1.10:6443"  # Master节点的URL

# 网络配置
K3S_NODE_IP="192.168.1.11"  # Agent1节点IP
K3S_NODE_EXTERNAL_IP=""      # 如果有外部IP

# 安装选项
INSTALL_OPTIONS=(
    "--write-kubeconfig-mode=644"
    "--node-ip=192.168.1.11"
)
```

**执行安装：**
```bash
su -
./install_k3s.sh
```

### 步骤3：安装Agent2节点

在 **192.168.1.12** 上执行：

配置与Agent1相同，只需修改IP地址：

```bash
# 配置内容
K3S_TOKEN="K10xxxxxxxxxxxxxxxxxxxx"  # 与Agent1相同
K3S_URL="https://192.168.1.10:6443"  # 与Agent1相同
K3S_NODE_IP="192.168.1.12"           # Agent2节点IP
```

**执行安装：**
```bash
su -
./install_k3s.sh
```

## ✅ 验证集群

在Master节点（192.168.1.10）上执行：

```bash
# 查看所有节点
kubectl get nodes

# 应该看到3个节点：
# NAME            STATUS   ROLES                  AGE   VERSION
# 192.168.1.10    Ready    control-plane,master   5m    v1.28.x
# 192.168.1.11    Ready    <none>                 2m    v1.28.x
# 192.168.1.12    Ready    <none>                 1m    v1.28.x

# 查看节点详细信息
kubectl get nodes -o wide

# 查看所有Pod
kubectl get pods -A
```

## 🔧 使用环境变量快速配置

如果不想修改脚本，可以使用环境变量：

### Master节点
```bash
export K3S_VERSION="latest"
export INSTALL_MODE="server"
export SINGLE_NODE_MODE="false"
export K3S_NODE_IP="192.168.1.10"

./install_k3s.sh
```

### Agent节点
```bash
export K3S_VERSION="latest"
export INSTALL_MODE="agent"
export K3S_TOKEN="K10xxxxxxxxxxxxxxxxxxxx"
export K3S_URL="https://192.168.1.10:6443"
export K3S_NODE_IP="192.168.1.11"  # Agent1使用.11，Agent2使用.12

./install_k3s.sh
```

## 📝 配置模板

### Master节点配置模板

创建 `master-config.sh`：
```bash
#!/bin/bash
# Master节点配置

export K3S_VERSION="latest"
export INSTALL_MODE="server"
export SINGLE_NODE_MODE="false"
export K3S_NODE_IP="192.168.1.10"

# 执行安装
./install_k3s.sh
```

### Agent节点配置模板

创建 `agent-config.sh`：
```bash
#!/bin/bash
# Agent节点配置

export K3S_VERSION="latest"
export INSTALL_MODE="agent"
export K3S_TOKEN="K10xxxxxxxxxxxxxxxxxxxx"  # 从Master获取
export K3S_URL="https://192.168.1.10:6443"
export K3S_NODE_IP="192.168.1.11"  # 修改为对应节点IP

# 执行安装
./install_k3s.sh
```

## 🛠️ 故障排除

### Agent节点无法加入集群

1. **检查Token和URL**
   ```bash
   # 在Agent节点上验证
   echo $K3S_TOKEN
   echo $K3S_URL
   ```

2. **检查网络连通性**
   ```bash
   # 从Agent节点测试连接Master
   curl -k https://192.168.1.10:6443
   telnet 192.168.1.10 6443
   ```

3. **检查防火墙**
   ```bash
   # 在Master节点上
   ufw allow from 192.168.1.11 to any port 6443
   ufw allow from 192.168.1.12 to any port 6443
   ```

4. **查看日志**
   ```bash
   # Agent节点
   journalctl -u k3s-agent -f
   
   # Master节点
   journalctl -u k3s -f
   ```

### 节点状态为NotReady

```bash
# 查看节点详细信息
kubectl describe node 192.168.1.11

# 检查网络插件
kubectl get pods -n kube-system

# 重启Agent节点服务
systemctl restart k3s-agent
```

## 🔒 安全建议

1. **Token安全**
   - 妥善保管Master节点的token
   - 不要将token提交到版本控制
   - 定期轮换token（需要重新加入节点）

2. **网络隔离**
   - 使用防火墙限制6443端口访问
   - 仅允许集群内节点访问

3. **TLS配置**
   - 确保所有节点IP都在`--tls-san`中
   - 使用有效的域名和证书

## 📊 集群管理

### 查看集群信息
```bash
# 在Master节点
./install_k3s.sh info
```

### 查看节点状态
```bash
kubectl get nodes
kubectl get nodes -o wide
```

### 移除节点
```bash
# 在Master节点上
kubectl delete node 192.168.1.11

# 在Agent节点上卸载
./install_k3s.sh uninstall
```

## 💡 扩展集群

如果需要添加更多Agent节点，只需重复步骤2和步骤3，使用相同的Token和URL即可。

---

**注意**：所有节点的K3S_VERSION必须一致！
