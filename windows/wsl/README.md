# wsl2

## 常用命令

```powershell
# 安装并升级 wsl2，需管理员运行
wsl --install
# 更新 wsl2 至最新版
wsl --update

# 查看在线可用的 Linux 发行版
wsl --list --online
wsl -l -o

# 安装 Linux 发行版
wsl --install <Distro>

# 查看已安装的发行版的运行状态
wsl --list --verbose

# 关闭正在运行的 Linux 发行版
wsl --terminate <Distro>

# 设置默认的 Linux 发行版
wsl --set--default <Distro>

# 查看wsl版本、状态、默认发行版等信息
wsl --status

# 删除已安装的 Linux 发行版
wsl --unregister <Distro>
```

## 备份恢复

```powershell
wsl --export ubuntu ubuntu.tar
wsl --import myname C:\wsl .ubuntu.tar
```

## wsl配置文件

* `wsl.conf` 为 WSL1 或 WSL2 上运行的 Linux 发行版配置 每个分发 版的设置。
* `.wslconfig` 用于在 WSL2（WSL1不支持）上运行的所有已安装分发版 全局 配置设置。

```
[wsl2]
networkingMode=nat
```