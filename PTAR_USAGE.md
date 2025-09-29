# Ptar 打包脚本使用说明

## 简介

`create_package.sh` 是一个专为 Clash for Linux Install 项目设计的打包脚本，使用 macOS 原生的 `ptar` 命令创建干净的项目发布包，自动排除 Git 相关文件和其他项目无关文件。

## 使用方法

### 基本用法

```bash
# 在项目根目录下执行
./create_package.sh
```

### 输出说明

脚本会创建一个以项目名称命名的压缩包：
```
clash-for-linux-install.tar.gz
```

## 排除的文件和目录

### Git 相关
- `.git/` - Git 仓库目录
- `.github/` - GitHub 配置目录
- `.gitignore` - Git 忽略配置
- `.gitattributes` - Git 属性配置
- `.gitmodules` - Git 子模块配置

### IDE 和编辑器文件
- `.idea/` - IntelliJ IDEA 配置
- `.vscode/` - VS Code 配置
- `.vs/` - Visual Studio 配置
- `*.swp`, `*.swo` - Vim 临时文件
- `*~` - 编辑器备份文件

### 系统文件
- `.DS_Store` - macOS 系统文件
- `Thumbs.db` - Windows 缩略图
- `desktop.ini` - Windows 桌面配置
- `*.lnk` - Windows 快捷方式

### 项目特定排除
- `config.yaml` - 用户配置文件
- `resources/bin/` - 二进制文件目录
- `*.log` - 日志文件
- `*.tmp`, `*.temp` - 临时文件

### 构建和打包文件
- `node_modules/` - Node.js 依赖
- `dist/`, `build/`, `target/` - 构建输出
- `*.tar.gz`, `*.zip` 等压缩文件
- `create_package.sh` - 脚本自身
- `PTAR_USAGE.md` - 说明文档

## 包含的文件

脚本会包含所有项目核心文件：
- ✅ `install.sh` - 安装脚本
- ✅ `uninstall.sh` - 卸载脚本  
- ✅ `README.md` - 项目文档
- ✅ `LICENSE` - 开源协议
- ✅ `script/` - 脚本目录
- ✅ `resources/` - 资源文件目录

## 验证功能

脚本执行后会自动验证：
1. 打包是否成功
2. 文件大小和数量统计
3. 关键文件是否包含
4. 排除规则是否生效

## 解压使用

### 使用 ptar 命令解压
```bash
ptar -x -z -f clash-for-linux-install.tar.gz
```

### 使用 tar 命令解压
```bash
tar -xzf clash-for-linux-install.tar.gz
```

## 技术说明

### ptar 命令
- `ptar` 是 macOS 上基于 Perl Archive::Tar 模块的命令
- 提供与 `tar` 兼容的功能，但使用 Perl 实现
- 支持创建、提取和列出 tar 档案
- 原生支持 gzip 压缩（-z 选项）
