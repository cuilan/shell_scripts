# NFS自动挂载systemd服务

本目录包含用于自动挂载NFS共享的systemd配置文件和安装脚本。

## 📁 文件说明

| 文件名 | 描述 |
|--------|------|
| `mnt-nfs.mount` | systemd挂载单元文件，定义NFS挂载配置 |
| `mnt-nfs.automount` | systemd自动挂载单元文件，实现按需挂载 |
| `install_nfs_automount.sh` | 自动化安装和配置脚本 |
| `uninstall_nfs_automount.sh` | 自动化卸载脚本，完全移除服务 |
| `config.example` | 配置参数示例和说明 |
| `README.md` | 使用说明文档（本文件） |

## 🚀 快速开始

### 方法一：使用安装脚本（推荐）

1. **修改配置文件**
   ```bash
   # 编辑mount单元文件，修改NFS服务器地址和路径
   sudo nano mnt-nfs.mount
   ```

2. **运行安装脚本**
   ```bash
   sudo ./install_nfs_automount.sh
   ```

3. **测试挂载**
   ```bash
   # 访问挂载点会自动触发挂载
   ls /mnt/nfs
   ```

### 方法二：手动安装

1. **安装NFS工具**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install nfs-common
   
   # CentOS/RHEL
   sudo yum install nfs-utils
   ```

2. **创建挂载点**
   ```bash
   sudo mkdir -p /mnt/nfs
   ```

3. **复制systemd文件**
   ```bash
   sudo cp mnt-nfs.mount /etc/systemd/system/
   sudo cp mnt-nfs.automount /etc/systemd/system/
   sudo chmod 644 /etc/systemd/system/mnt-nfs.*
   ```

4. **启用服务**
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable mnt-nfs.automount
   sudo systemctl start mnt-nfs.automount
   ```

## ⚙️ 配置说明

### 必需修改的参数

在 `mnt-nfs.mount` 文件中修改以下参数：

```ini
[Mount]
# 修改为你的NFS服务器地址和共享路径
What=192.168.1.100:/path/to/share
# 可选：修改本地挂载点
Where=/mnt/nfs
```

### 挂载选项详解

| 选项 | 说明 | 推荐值 |
|------|------|--------|
| `nfsvers` | NFS协议版本 | `4`（最新且安全） |
| `tcp/udp` | 传输协议 | `tcp`（更可靠） |
| `rw/ro` | 读写权限 | `rw`（根据需要） |
| `hard/soft` | 挂载方式 | `hard`（数据安全） |
| `intr` | 允许中断 | 建议启用 |
| `noatime` | 不更新访问时间 | 建议启用（提升性能） |

### 自动卸载配置

在 `mnt-nfs.automount` 文件中：

```ini
[Automount]
# 设置空闲超时时间（可选）
TimeoutIdleSec=60  # 60秒无访问后自动卸载
```

## 🔍 管理和监控

### 服务状态查看

```bash
# 查看自动挂载服务状态
sudo systemctl status mnt-nfs.automount

# 查看挂载状态
sudo systemctl status mnt-nfs.mount

# 查看挂载点信息
mount | grep nfs
```

### 日志查看

```bash
# 查看systemd日志
sudo journalctl -u mnt-nfs.automount
sudo journalctl -u mnt-nfs.mount

# 查看实时日志
sudo journalctl -f -u mnt-nfs.automount
```

### 手动操作

```bash
# 手动挂载
sudo systemctl start mnt-nfs.mount

# 手动卸载
sudo systemctl stop mnt-nfs.mount

# 重新加载配置
sudo systemctl daemon-reload
sudo systemctl restart mnt-nfs.automount
```

## 🗑️ 卸载服务

如果需要完全移除NFS自动挂载服务：

### 使用卸载脚本（推荐）

```bash
# 运行卸载脚本
sudo ./uninstall_nfs_automount.sh
```

卸载脚本会执行以下操作：
- 停止并禁用所有相关服务
- 安全卸载当前的NFS挂载
- 删除systemd单元文件
- 可选删除挂载点目录
- 验证卸载结果

### 手动卸载

```bash
# 停止和禁用服务
sudo systemctl stop mnt-nfs.automount
sudo systemctl disable mnt-nfs.automount
sudo systemctl stop mnt-nfs.mount

# 删除systemd文件
sudo rm -f /etc/systemd/system/mnt-nfs.mount
sudo rm -f /etc/systemd/system/mnt-nfs.automount

# 重新加载配置
sudo systemctl daemon-reload

# 可选：删除挂载点
sudo rmdir /mnt/nfs
```

## 🛠️ 故障排除

### 常见问题

1. **挂载失败**
   - 检查NFS服务器是否运行：`showmount -e NFS_SERVER_IP`
   - 确认网络连接：`ping NFS_SERVER_IP`
   - 查看详细错误：`sudo journalctl -u mnt-nfs.mount`

2. **权限问题**
   - 确保NFS服务器允许客户端访问
   - 检查文件系统权限
   - 考虑使用`no_root_squash`选项（仅测试环境）

3. **性能问题**
   - 调整`rsize`和`wsize`参数
   - 使用NFSv4.1或更高版本
   - 考虑使用`noatime`选项

### 调试命令

```bash
# 手动测试NFS挂载
sudo mount -t nfs 192.168.1.100:/path/to/share /mnt/test

# 显示NFS服务器的可用挂载
showmount -e 192.168.1.100

# 检查NFS统计信息
nfsstat -c
```

## 🔒 安全建议

1. **网络安全**
   - 使用防火墙限制NFS端口（2049）访问
   - 在可能的情况下使用VPN或安全网络

2. **认证安全**
   - 生产环境建议使用Kerberos认证
   - 配置适当的用户ID映射

3. **权限控制**
   - NFS服务器上设置严格的导出权限
   - 避免使用`no_root_squash`选项

## 📋 自定义配置

参考 `config.example` 文件查看各种配置示例：

- 家庭NAS配置
- 生产环境高性能配置  
- 只读挂载配置

根据实际需求修改systemd单元文件中的相应参数。

## 🆘 获得帮助

如果遇到问题，请：

1. 查看systemd日志获取详细错误信息
2. 确认NFS服务器配置正确
3. 检查网络连接和防火墙设置
4. 参考NFS和systemd官方文档

---

**注意**：首次使用前务必根据实际环境修改配置文件中的服务器地址和路径！
