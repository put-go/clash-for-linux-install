# Linux 一键安装 Clash

> 🌟 **项目源码** Fork 来自 [@nelvko/clash-for-linux-install](https://github.com/nelvko/clash-for-linux-install) 
> 
> 😼 优雅地使用基于 clash/mihomo 的代理环境，一键部署，开箱即用！

![GitHub License](https://img.shields.io/github/license/put-go/clash-for-linux-install)
![GitHub top language](https://img.shields.io/github/languages/top/put-go/clash-for-linux-install)
![GitHub Repo stars](https://img.shields.io/github/stars/put-go/clash-for-linux-install)

![preview](resources/preview.png)

## 🚀 项目特色

- **🔧 简单易用**：一键安装脚本，自动化配置，零学习成本
- **⚡ 高性能内核**：默认安装 `mihomo` 内核，[可选安装](https://github.com/nelvko/clash-for-linux-install/wiki/FAQ#%E5%AE%89%E8%A3%85-clash-%E5%86%85%E6%A0%B8) `clash`
- **🔄 订阅转换**：支持使用 [subconverter](https://github.com/tindy2013/subconverter) 进行本地订阅转换
- **🌐 多架构支持**：支持 `x86_64`、`ARM64` 架构，适配主流 `Linux` 发行版：`CentOS 7.6`、`Debian 12`、`Ubuntu 24.04.1 LTS`
- **📊 可视化管理**：集成 Web 控制台，支持节点切换、流量监控、日志查看
- **🔒 安全可靠**：支持 TUN 模式、DNS 劫持、系统代理自动配置
- **⏰ 自动更新**：支持定时更新订阅，保持节点实时可用
- **🎯 灵活配置**：Mixin 配置持久化，自定义规则不丢失

## 📋 系统要求

| 项目 | 要求 |
|------|------|
| **操作系统** | CentOS 7.6+、Debian 12+、Ubuntu 24.04.1 LTS+ |
| **架构支持** | x86_64、ARM64(aarch64) |
| **用户权限** | `root` 或 `sudo` 用户 ([普通用户安装指南](https://github.com/nelvko/clash-for-linux-install/issues/91)) |
| **Shell 环境** | `bash`、`zsh`、`fish` |
| **网络要求** | 能够访问 GitHub 或使用代理镜像 |

## 📖 项目说明

本项目是 [nelvko/clash-for-linux-install](https://github.com/nelvko/clash-for-linux-install) 的 Fork 版本，专注于提供更加完善的 Linux 环境下 Clash 代理工具的安装和管理解决方案。

### 🎯 适用场景

- **开发环境**：为开发者提供稳定的网络代理环境
- **服务器部署**：在 VPS 或云服务器上快速部署代理服务
- **ARM 设备**：支持树莓派、ARM 开发板、Apple Silicon Mac 等 ARM 架构设备
- **容器化应用**：支持 Docker 容器的网络代理
- **自动化运维**：支持脚本化管理和定时任务
- **团队协作**：统一的代理配置管理方案

### 🔧 核心功能

| 功能模块 | 说明 | 命令示例 |
|---------|------|----------|
| **代理管理** | 一键启停代理服务 | `clashon` / `clashoff` |
| **Web 控制台** | 可视化节点管理 | `clashui` |
| **自启动管理** | 开机自启动控制 | `clashctl autostart on` |
| **自动加载代理** | 登录终端自动加载代理 | `clashctl autoproxy on` |
| **订阅管理** | 自动更新订阅配置 | `clashupdate` |
| **TUN 模式** | 透明代理所有流量 | `clashtun on` |
| **系统代理** | 自动配置系统代理 | `clashproxy on` |
| **配置持久化** | Mixin 配置管理 | `clashmixin -e` |
| **状态监控** | 实时查看运行状态 | `clashctl status` |

## 🚀 快速开始

### 📋 环境检查

在开始安装前，请确保您的系统满足以下要求：

- **用户权限**：`root` 或 `sudo` 用户 ([普通用户安装指南](https://github.com/nelvko/clash-for-linux-install/issues/91))
- **Shell 环境**：`bash`、`zsh`、`fish` 任一支持
- **网络连接**：能够访问 GitHub 或配置代理镜像
- **系统工具**：`curl`、`wget`、`tar`、`gzip` 等基础工具

### 一键安装

**适用于所有支持的架构**（脚本会自动检测并选择对应的二进制文件）：

支持的架构包括：
- ✅ `x86_64` (Intel/AMD 64位)
- ✅ `ARM64` / `aarch64` (ARM 64位，如树莓派4B、M1/M2 Mac、云服务器等)

```bash
git clone --branch master --depth 1 https://gh-proxy.com/https://github.com/put-go/clash-for-linux-install.git \
  && cd clash-for-linux-install \
  && sudo bash install.sh
```

> 如遇问题，请在查阅[常见问题](https://github.com/nelvko/clash-for-linux-install/wiki/FAQ)及 [issue](https://github.com/nelvko/clash-for-linux-install/issues?q=is%3Aissue) 未果后进行反馈。

- 上述克隆命令使用了[加速前缀](https://gh-proxy.com/)，如失效请更换其他[可用链接](https://ghproxy.link/)。
- 默认通过远程订阅获取配置进行安装，本地配置安装详见：[#39](https://github.com/nelvko/clash-for-linux-install/issues/39)
- 没有订阅？[click me](https://次元.net/auth/register?code=oUbI)

### 命令一览

执行 `clashctl` 列出开箱即用的快捷命令。


```bash
$ clashctl
Usage:
    clashctl    COMMAND [OPTION]
    
Commands:
    on                   开启代理
    off                  关闭代理
    ui                   面板地址
    status               内核状况
    proxy    [on|off]    系统代理
    tun      [on|off]    Tun 模式
    mixin    [-e|-r]     Mixin 配置
    secret   [SECRET]    Web 密钥
    update   [auto|log]  更新订阅
    autostart [on|off]   开机自启 (enable|disable)
    autoproxy [on|off]   登录自动加载代理环境
```

💡`clashon` 等同于 `clashctl on`，`Tab` 补全更方便！

### 优雅启停

```bash
$ clashon
😼 已开启代理环境

$ clashoff
😼 已关闭代理环境
```
- 启停代理内核的同时，设置系统代理。
- 亦可通过 `clashproxy` 单独控制系统代理。

### Web 控制台

```bash
$ clashui
╔═══════════════════════════════════════════════╗
║                😼 Web 控制台                  ║
║═══════════════════════════════════════════════║
║                                               ║
║     🔓 注意放行端口：9090                      ║
║     🏠 内网：http://192.168.0.1:9090/ui       ║
║     🌏 公网：http://255.255.255.255:9090/ui   ║
║     ☁️ 公共：http://board.zash.run.place      ║
║                                               ║
╚═══════════════════════════════════════════════╝

$ clashsecret 666
😼 密钥更新成功，已重启生效

$ clashsecret
😼 当前密钥：666
```

- 通过浏览器打开 Web 控制台，实现可视化操作：切换节点、查看日志等。
- 若暴露到公网使用建议定期更换密钥。

### 自启动管理

🔧 **便捷管理**：轻松控制 Clash 开机自启动设置

```bash
# 查看自启动状态
$ clashctl autostart
🔒 开机自启动：已禁用

# 启用开机自启动
$ clashctl autostart on
✅ 已启用开机自启动
ℹ️ 服务将在下次重启时自动启动

# 禁用开机自启动
$ clashctl autostart off
✅ 已禁用开机自启动
ℹ️ 服务将不会在重启时自动启动
```

- 安装时默认启用开机自启动
- 支持后续随时开启或关闭
- 查看当前自启动状态

### 自动加载代理环境

🔄 **智能管理**：控制登录终端时是否自动执行 `clashon`（显示"😼 已开启代理环境"）

```bash
# 查看自动加载状态
$ clashctl autoproxy
🔒 登录自动加载代理：已禁用

# 启用登录自动加载代理环境
$ clashctl autoproxy on
✅ 已启用登录自动加载代理环境
ℹ️ 下次登录终端时将自动执行 clashon

# 禁用登录自动加载代理环境
$ clashctl autoproxy off
✅ 已禁用登录自动加载代理环境
ℹ️ 下次登录终端时不会自动加载代理
```

- **自启动 vs 自动加载的区别**：
  - `autostart`：控制系统启动时是否自动启动 Clash 服务
  - `autoproxy`：控制登录终端时是否自动加载代理环境变量
- 安装时可选择是否启用自动加载
- 默认禁用，避免不必要的自动行为

### 更新订阅

```bash
$ clashupdate https://example.com
👌 正在下载：原配置已备份...
🍃 下载成功：内核验证配置...
🍃 订阅更新成功

$ clashupdate auto [url]
😼 已设置定时更新订阅

$ clashupdate log
✅ [2025-02-23 22:45:23] 订阅更新成功：https://example.com
```

- `clashupdate` 会记住上次更新成功的订阅链接，后续执行无需再指定。
- 可通过 `crontab -e` 修改定时更新频率及订阅链接。
- 通过配置文件进行更新：[pr#24](https://github.com/nelvko/clash-for-linux-install/pull/24#issuecomment-2565054701)

### `Tun` 模式

```bash
$ clashtun
😾 Tun 状态：关闭

$ clashtun on
😼 Tun 模式已开启
```

- 作用：实现本机及 `Docker` 等容器的所有流量路由到 `clash` 代理、DNS 劫持等。
- 原理：[clash-verge-rev](https://www.clashverge.dev/guide/term.html#tun)、 [clash.wiki](https://clash.wiki/premium/tun-device.html)。
- 注意事项：[#100](https://github.com/nelvko/clash-for-linux-install/issues/100#issuecomment-2782680205)

### `Mixin` 配置

```bash
$ clashmixin
😼 less 查看 mixin 配置

$ clashmixin -e
😼 vim 编辑 mixin 配置

$ clashmixin -r
😼 less 查看 运行时 配置
```

- 持久化：将自定义配置项写入`Mixin`（`mixin.yaml`），而非原订阅配置（`config.yaml`），可避免更新订阅后丢失。
- 配置加载：代理内核启动时使用 `runtime.yaml`，它是订阅配置与 `Mixin` 配置的合并结果集，相同配置项以 `Mixin` 为准。
- 注意：因此直接修改 `config.yaml` 并不会生效。

### 卸载

```bash
sudo bash uninstall.sh
```

## 常见问题

[wiki](https://github.com/nelvko/clash-for-linux-install/wiki/FAQ)

## 引用

- [Clash 知识库](https://clash.wiki/)
- [Clash 家族下载](https://www.clash.la/releases/)
- [Clash Premium](https://downloads.clash.wiki/ClashPremium/)
- [mihomo](https://github.com/MetaCubeX/mihomo)
- [subconverter: 订阅转换](https://github.com/tindy2013/subconverter)
- [yacd: Web 控制台](https://github.com/haishanh/yacd)
- [yq: 处理 yaml](https://github.com/mikefarah/yq)

## Star History

<a href="https://www.star-history.com/#put-go/clash-for-linux-install&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=put-go/clash-for-linux-install&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=put-go/clash-for-linux-install&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=nelvko/clash-for-linux-install&type=Date" />
 </picture>
</a>

## 🤝 项目贡献

### 原项目致谢

本项目基于 [@nelvko/clash-for-linux-install](https://github.com/nelvko/clash-for-linux-install) 开发，感谢原作者及贡献者们的辛勤付出！

特别感谢：
- [@鑫哥](https://github.com/TrackRay) - 项目原始贡献者
- [@nelvko](https://github.com/nelvko) - 原项目维护者
- 所有参与项目改进的开发者和用户

### 🔄 更新记录

#### Fork 版本改进
- ✅ 完善项目文档和说明
- ✅ 优化安装脚本的错误处理
- ✅ **全面支持 ARM64 架构**：新增 ARM64/aarch64 架构完整支持
- ✅ 增强多架构支持：智能架构检测和对应二进制文件选择
- ✅ **优化安装体验**：保持开机自启动默认启用，可选择自动加载代理环境
- ✅ **自启动管理**：新增 `clashctl autostart` 命令管理开机自启
- ✅ **自动加载代理管理**：新增 `clashctl autoproxy` 命令控制登录自动加载
- ✅ 离线安装包：所有必要工具已集成，无需在线下载
- ✅ **改进用户体验**：统一命令接口，简化操作流程
- ✅ 改进 Web 控制台界面
- ✅ 优化订阅更新机制

#### 计划中的功能
- 🔄 支持更多 Linux 发行版
- 🔄 增加配置备份和恢复功能
- 🔄 优化网络连接检测
- 🔄 增强安全性配置选项
- 🔄 集成更多代理协议支持

### 🐛 问题反馈

如果您在使用过程中遇到问题，请：

1. 首先查阅 [常见问题](https://github.com/nelvko/clash-for-linux-install/wiki/FAQ)
2. 搜索已有的 [Issues](https://github.com/nelvko/clash-for-linux-install/issues)
3. 如果问题未解决，请提交新的 Issue，包含：
   - 系统环境信息（OS、架构、版本）
   - 详细的错误信息或日志
   - 复现问题的步骤
   - 期望的行为描述

### 🚀 参与贡献

欢迎提交 Pull Request 来改进项目！贡献指南：

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 📚 相关资源

### 官方文档
- [Clash 官方文档](https://clash.wiki/) - Clash 核心功能介绍
- [Mihomo 文档](https://wiki.metacubex.one/) - Mihomo 内核说明
- [Clash Verge Rev](https://www.clashverge.dev/) - 桌面客户端

### 配置参考
- [Clash 配置文件详解](https://clash.wiki/configuration/outbound.html)
- [规则集合](https://github.com/Loyalsoldier/clash-rules)
- [GeoIP 数据库](https://github.com/Dreamacro/maxmind-geoip)

### 订阅转换
- [Sub-Store](https://github.com/sub-store-org/Sub-Store) - 订阅管理工具
- [Subconverter 在线版](https://dove.589669.xyz/web/)
- [ACL4SSR 规则](https://github.com/ACL4SSR/ACL4SSR)

## ⚖️ 特别声明

1. **学习目的**：编写本项目主要目的为学习和研究 `Shell` 编程，不得将本项目中任何内容用于违反国家/地区/组织等的法律法规或相关规定的其他用途。

2. **使用责任**：用户在使用本项目时，应当遵守所在国家和地区的法律法规，作者不承担因使用本项目而产生的任何法律责任。

3. **免责条款**：本项目保留随时对免责声明进行补充或更改的权利，直接或间接使用本项目内容的个人或组织，视为接受本项目的特别声明。

4. **开源协议**：本项目遵循 MIT 开源协议，详见 [LICENSE](LICENSE) 文件。

## 📞 联系方式

- **原项目地址**：https://github.com/nelvko/clash-for-linux-install
- **当前 Fork**：https://github.com/put-go/clash-for-linux-install
- **问题反馈**：[提交 Issue](https://github.com/nelvko/clash-for-linux-install/issues)
- **讨论交流**：[GitHub Discussions](https://github.com/nelvko/clash-for-linux-install/discussions)

---

<div align="center">

**如果这个项目对您有帮助，请给个 ⭐ Star 支持一下！**

</div>
