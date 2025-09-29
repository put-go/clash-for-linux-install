#!/bin/bash

# Clash for Linux Install 项目打包脚本
# 使用 macOS ptar 命令排除 git 相关隐藏文件和项目无关文件

set -e

# 获取项目名称（当前目录名）
PROJECT_NAME=$(basename "$(pwd)")

# 打包文件名（不含日期）
ARCHIVE_NAME="${PROJECT_NAME}.tar.gz"

echo "🚀 开始打包 ${PROJECT_NAME} 项目..."
echo "📦 打包文件: ${ARCHIVE_NAME}"
echo "🔧 使用 macOS ptar 命令..."

# 创建临时目录和文件列表
TEMP_DIR=$(mktemp -d)
FILE_LIST="${TEMP_DIR}/files.txt"

echo "🔍 正在扫描项目文件..."

# 定义需要排除的文件和目录模式
EXCLUDE_PATTERNS=(
    # Git 相关文件
    ".git"
    ".github"
    ".gitignore"
    ".gitattributes" 
    ".gitmodules"
    
    # IDE 和编辑器文件
    ".idea"
    ".vscode"
    ".vs"
    "*.swp"
    "*.swo"
    "*~"
    ".DS_Store"
    "Thumbs.db"
    
    # 开发工具配置
    ".editorconfig"
    ".eslintrc*"
    ".prettierrc*"
    ".stylelintrc*"
    
    # 项目特定排除
    "config.yaml"           # 用户配置文件
    "resources/bin"         # 二进制文件目录（.gitignore中已排除）
    
    # 临时文件和日志
    "*.log"
    "*.tmp"
    "*.temp"
    ".cache"
    "cache"
    "tmp"
    "temp"
    
    # 构建和包管理器文件
    "node_modules"
    ".npm"
    ".yarn"
    "dist"
    "build"
    "target"
    
    # 系统文件
    ".Trashes"
    "desktop.ini"
    "*.lnk"
    
    # 备份文件
    "*.bak"
    "*.backup"
    "*.orig"
    
    # 打包文件本身
    "*.tar.gz"
    "*.tar.bz2"
    "*.tar.xz"
    "*.zip"
    "*.rar"
    "*.7z"
    
    # 文档文件
    "*.md"
    
    # 本脚本自身（避免递归打包）
    "create_package.sh"
)

# 构建排除模式的正则表达式
EXCLUDE_REGEX=""
for pattern in "${EXCLUDE_PATTERNS[@]}"; do
    # 转换 glob 模式为正则表达式
    regex_pattern=$(echo "$pattern" | sed 's/\*/\.\*/g' | sed 's/\?/\./g')
    if [ -z "$EXCLUDE_REGEX" ]; then
        EXCLUDE_REGEX="($regex_pattern)"
    else
        EXCLUDE_REGEX="$EXCLUDE_REGEX|($regex_pattern)"
    fi
done

# 使用 find 命令生成文件列表，排除不需要的文件
find . -type f ! -path "./.git/*" ! -path "./.github/*" | while read -r file; do
    # 移除开头的 ./
    clean_file="${file#./}"
    
    # 特殊处理：resources/zip/ 目录下的文件必须保留
    if [[ "$clean_file" == resources/zip/* ]]; then
        echo "${PROJECT_NAME}/${clean_file}" >> "$FILE_LIST"
        continue
    fi
    
    # 检查是否匹配排除模式
    if ! echo "$clean_file" | grep -qE "^($EXCLUDE_REGEX)$"; then
        # 检查父目录是否在排除列表中
        exclude_file=false
        for pattern in "${EXCLUDE_PATTERNS[@]}"; do
            if [[ "$clean_file" == *"$pattern"* ]] && [[ "$pattern" != *"*"* ]]; then
                exclude_file=true
                break
            fi
        done
        
        if [ "$exclude_file" = false ]; then
            # 添加项目目录前缀
            echo "${PROJECT_NAME}/${clean_file}" >> "$FILE_LIST"
        fi
    fi
done

# 检查文件列表是否为空
if [ ! -s "$FILE_LIST" ]; then
    echo "❌ 没有找到要打包的文件！"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# 显示要打包的文件数量
FILE_COUNT=$(wc -l < "$FILE_LIST" | tr -d ' ')
echo "📊 找到 ${FILE_COUNT} 个文件待打包"

# 使用 ptar 创建压缩包
echo "🔄 正在使用 ptar 打包..."
# 切换到上级目录执行打包，这样可以包含完整的目录结构
cd ..
ptar -c -z -v -f "${PROJECT_NAME}/${ARCHIVE_NAME}" -T "${FILE_LIST}"
cd "${PROJECT_NAME}"

# 清理临时文件
rm -rf "$TEMP_DIR"

# 检查打包结果
if [ -f "$ARCHIVE_NAME" ]; then
    FILE_SIZE=$(du -h "$ARCHIVE_NAME" | cut -f1)
    echo "✅ 打包完成！"
    echo "📁 文件位置: $(pwd)/${ARCHIVE_NAME}"
    echo "📊 文件大小: ${FILE_SIZE}"
    
    # 显示打包内容概览
    echo ""
    echo "📋 打包内容概览:"
    ptar -t -f "$ARCHIVE_NAME" | head -20
    
    TOTAL_FILES=$(ptar -t -f "$ARCHIVE_NAME" | wc -l | tr -d ' ')
    echo "..."
    echo "📈 总计文件数: ${TOTAL_FILES}"
    
    # 验证关键文件是否包含
    echo ""
    echo "🔍 验证关键文件:"
    CRITICAL_FILES=("install.sh" "uninstall.sh" "LICENSE")
    for file in "${CRITICAL_FILES[@]}"; do
        if ptar -t -f "$ARCHIVE_NAME" | grep -q "${PROJECT_NAME}/${file}$"; then
            echo "  ✅ ${file}"
        else
            echo "  ❌ ${file} (缺失)"
        fi
    done
    
else
    echo "❌ 打包失败！"
    exit 1
fi

echo ""
echo "🎉 ptar 打包操作完成！"
echo "💡 使用以下命令解压:"
echo "   ptar -x -z -f ${ARCHIVE_NAME}"
echo "   或者: tar -xzf ${ARCHIVE_NAME}"
