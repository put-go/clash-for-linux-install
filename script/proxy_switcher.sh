#!/bin/bash
# Clash 代理节点切换工具
# 作者: clash-for-linux-install 项目
# 功能: 通过命令行参数快速切换 Clash 代理节点

set -e

# 默认配置
api_url="http://localhost:9090"
Secret=""

# 从配置文件读取设置
_load_config() {
    local config_file="/opt/clash/runtime.yaml"
    if [ -f "$config_file" ]; then
        # 尝试从配置文件读取 external-controller 和 secret
        if command -v yq >/dev/null 2>&1; then
            local ext_controller=$(yq '.external-controller // ""' "$config_file" 2>/dev/null)
            local secret=$(yq '.secret // ""' "$config_file" 2>/dev/null)
            
            if [ -n "$ext_controller" ]; then
                api_url="http://$ext_controller"
            fi
            
            if [ -n "$secret" ]; then
                Secret="$secret"
            fi
        fi
    fi
}

# 显示帮助信息
show_help() {
    cat << EOF
Clash 代理节点切换工具

用法: $0 [选项] [命令]

选项:
  -u, --url URL        指定 Clash API 地址 (默认: $api_url)
  -s, --secret SECRET  指定 API 密钥
  -m, --mode MODE      指定代理模式 (默认: GLOBAL)
  -h, --help          显示此帮助信息

命令:
  list                 列出所有可用的代理节点
  select               交互式选择代理节点
  switch NODE          直接切换到指定节点
  current              显示当前使用的代理节点
  test                 测试 API 连接

示例:
  $0 list                          # 列出所有节点
  $0 select                        # 交互式选择节点
  $0 switch "香港节点01"            # 直接切换到指定节点
  $0 -m Proxy select               # 在 Proxy 模式下选择节点
  $0 -u http://127.0.0.1:9090 list # 使用自定义 API 地址

EOF
}

# 测试 API 连接
test_connection() {
    echo "🔍 测试 Clash API 连接..."
    echo "API 地址: $api_url"
    
    local auth_header=""
    if [ -n "$Secret" ]; then
        auth_header="-H \"Authorization: Bearer $Secret\""
    fi
    
    if eval "curl -s --connect-timeout 5 $auth_header \"$api_url/version\"" >/dev/null 2>&1; then
        echo "✅ API 连接成功"
        local version=$(eval "curl -s $auth_header \"$api_url/version\"" | jq -r '.version // "未知版本"' 2>/dev/null || echo "未知版本")
        echo "📦 Clash 版本: $version"
        return 0
    else
        echo "❌ API 连接失败，请检查："
        echo "   1. Clash 是否正在运行"
        echo "   2. API 地址是否正确: $api_url"
        echo "   3. 密钥是否正确"
        return 1
    fi
}

# 获取 Clash 代理节点列表
get_proxy_list() {
    local mode=${1:-"GLOBAL"}
    local auth_header=""
    
    if [ -n "$Secret" ]; then
        auth_header="-H \"Authorization: Bearer $Secret\""
    fi
    
    # 获取代理节点列表
    proxies=$(eval "curl -s -X GET -H \"Content-Type: application/json\" $auth_header \"$api_url/proxies\"" | jq -c ".proxies.$mode.all // []" 2>/dev/null)
    
    if [ "$proxies" = "null" ] || [ "$proxies" = "[]" ] || [ -z "$proxies" ]; then
        echo "❌ 无法获取代理节点列表，请检查模式名称: $mode"
        return 1
    fi
    
    echo "$proxies"
}

# 获取当前代理节点
get_current_proxy() {
    local mode=${1:-"GLOBAL"}
    local auth_header=""
    
    if [ -n "$Secret" ]; then
        auth_header="-H \"Authorization: Bearer $Secret\""
    fi
    
    local current=$(eval "curl -s -X GET -H \"Content-Type: application/json\" $auth_header \"$api_url/proxies\"" | jq -r ".proxies.$mode.now // \"未知\"" 2>/dev/null)
    echo "$current"
}

# 列出所有代理节点
list_proxies() {
    local mode=${1:-"GLOBAL"}
    
    echo "🌐 获取代理节点列表 (模式: $mode)..."
    
    if ! test_connection; then
        return 1
    fi
    
    local proxies=$(get_proxy_list "$mode")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    local current=$(get_current_proxy "$mode")
    
    echo ""
    echo "========== 代理节点列表 =========="
    echo "当前节点: $current"
    echo "================================="
    
    local i=1
    echo "$proxies" | jq -r '.[]' 2>/dev/null | while IFS= read -r proxy; do
        if [ "$proxy" = "$current" ]; then
            echo "$i. $proxy ⭐ (当前)"
        else
            echo "$i. $proxy"
        fi
        i=$((i+1))
    done
    
    echo "================================="
}

# 交互式选择代理节点
select_proxy() {
    local mode=${1:-"GLOBAL"}
    
    if ! test_connection; then
        return 1
    fi
    
    local proxies=$(get_proxy_list "$mode")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    list_proxies "$mode"
    
    echo ""
    read -p "请选择代理节点（输入编号）: " proxy_index
    
    if ! [[ "$proxy_index" =~ ^[0-9]+$ ]]; then
        echo "❌ 请输入有效的数字编号"
        return 1
    fi
    
    local proxy=$(echo "$proxies" | jq -r ".[$((proxy_index-1))]" 2>/dev/null)
    
    if [[ -n "$proxy" ]] && [[ "$proxy" != "null" ]]; then
        switch_proxy "$proxy" "$mode"
    else
        echo "❌ 无效的选择编号: $proxy_index"
        return 1
    fi
}

# 直接切换到指定节点
switch_proxy() {
    local proxy_name="$1"
    local mode=${2:-"GLOBAL"}
    
    if [ -z "$proxy_name" ]; then
        echo "❌ 请指定节点名称"
        return 1
    fi
    
    if ! test_connection; then
        return 1
    fi
    
    echo "🔄 切换代理节点..."
    echo "目标节点: $proxy_name"
    echo "代理模式: $mode"
    
    local auth_header=""
    if [ -n "$Secret" ]; then
        auth_header="-H \"Authorization: Bearer $Secret\""
    fi
    
    # 切换代理节点
    local response=$(eval "curl -s -X PUT \"$api_url/proxies/$mode\" -H \"Content-Type: application/json\" $auth_header --data '{\"name\":\"$proxy_name\"}'")
    
    if [ $? -eq 0 ]; then
        # 验证切换结果
        sleep 1
        local current=$(get_current_proxy "$mode")
        if [ "$current" = "$proxy_name" ]; then
            echo "✅ 代理节点已成功切换为: $proxy_name"
        else
            echo "⚠️  切换请求已发送，但验证失败"
            echo "   当前节点: $current"
            echo "   目标节点: $proxy_name"
        fi
    else
        echo "❌ 切换失败，请检查节点名称是否正确"
        return 1
    fi
}

# 显示当前代理节点
show_current() {
    local mode=${1:-"GLOBAL"}
    
    if ! test_connection; then
        return 1
    fi
    
    local current=$(get_current_proxy "$mode")
    echo "📍 当前代理节点 (模式: $mode): $current"
}

# 主函数
main() {
    # 加载配置
    _load_config
    
    # 解析参数
    local mode="GLOBAL"
    local command=""
    local proxy_name=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -u|--url)
                api_url="$2"
                shift 2
                ;;
            -s|--secret)
                Secret="$2"
                shift 2
                ;;
            -m|--mode)
                mode="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            list|select|current|test)
                command="$1"
                shift
                ;;
            switch)
                command="$1"
                proxy_name="$2"
                shift 2
                ;;
            *)
                echo "❌ 未知参数: $1"
                echo "使用 $0 --help 查看帮助信息"
                exit 1
                ;;
        esac
    done
    
    # 检查必要依赖
    if ! command -v curl >/dev/null 2>&1; then
        echo "❌ 错误: 需要安装 curl"
        exit 1
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        echo "❌ 错误: 需要安装 jq"
        exit 1
    fi
    
    # 执行命令
    case "$command" in
        list)
            list_proxies "$mode"
            ;;
        select)
            select_proxy "$mode"
            ;;
        switch)
            if [ -z "$proxy_name" ]; then
                echo "❌ 错误: switch 命令需要指定节点名称"
                echo "用法: $0 switch \"节点名称\""
                exit 1
            fi
            switch_proxy "$proxy_name" "$mode"
            ;;
        current)
            show_current "$mode"
            ;;
        test)
            test_connection
            ;;
        "")
            echo "❌ 错误: 请指定命令"
            echo "使用 $0 --help 查看帮助信息"
            exit 1
            ;;
        *)
            echo "❌ 错误: 未知命令: $command"
            echo "使用 $0 --help 查看帮助信息"
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
