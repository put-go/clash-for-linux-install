# shellcheck disable=SC2148
# shellcheck disable=SC2155

_set_system_proxy() {
    local auth=$(sudo "$BIN_YQ" '.authentication[0] // ""' "$CLASH_CONFIG_RUNTIME")
    [ -n "$auth" ] && auth=$auth@

    local bind_addr=$(sudo "$BIN_YQ" '.bind-address // ""' "$CLASH_CONFIG_RUNTIME")
    [[ -z "$bind_addr" || "$bind_addr" == "*" ]] && bind_addr='127.0.0.1'

    local http_proxy_addr="http://${auth}${bind_addr}:${MIXED_PORT}"
    local socks_proxy_addr="socks5h://${auth}${bind_addr}:${MIXED_PORT}"
    local no_proxy_addr="localhost,127.0.0.1,::1"

    export http_proxy=$http_proxy_addr
    export https_proxy=$http_proxy
    export HTTP_PROXY=$http_proxy
    export HTTPS_PROXY=$http_proxy

    export all_proxy=$socks_proxy_addr
    export ALL_PROXY=$all_proxy

    export no_proxy=$no_proxy_addr
    export NO_PROXY=$no_proxy

    sudo "$BIN_YQ" -i '.system-proxy.enable = true' "$CLASH_CONFIG_MIXIN"
}

_unset_system_proxy() {
    unset http_proxy
    unset https_proxy
    unset HTTP_PROXY
    unset HTTPS_PROXY
    unset all_proxy
    unset ALL_PROXY
    unset no_proxy
    unset NO_PROXY

    sudo "$BIN_YQ" -i '.system-proxy.enable = false' "$CLASH_CONFIG_MIXIN"
}

function clashon() {
    _get_proxy_port
    systemctl is-active "$BIN_KERNEL_NAME" >&/dev/null || {
        sudo systemctl start "$BIN_KERNEL_NAME" >/dev/null || {
            _failcat '启动失败: 执行 clashstatus 查看日志'
            return 1
        }
    }
    _set_system_proxy
    _okcat '已开启代理环境'
}

watch_proxy() {
    # 检查是否启用自动加载代理环境
    local auto_proxy_file="/opt/clash/.auto_proxy"
    [ ! -f "$auto_proxy_file" ] && return
    
    local auto_proxy_enabled=$(cat "$auto_proxy_file" 2>/dev/null || echo "false")
    [ "$auto_proxy_enabled" != "true" ] && return
    
    # 新开交互式shell，且无代理变量时
    [ -z "$http_proxy" ] && [[ $- == *i* ]] && {
        # root用户自动开启代理环境（普通用户会触发sudo验证密码导致卡住）
        _is_root && clashon
    }
}

function clashoff() {
    sudo systemctl stop "$BIN_KERNEL_NAME" && _okcat '已关闭代理环境' ||
        _failcat '关闭失败: 执行 "clashstatus" 查看日志' || return 1
    _unset_system_proxy
}

clashrestart() {
    { clashoff && clashon; } >&/dev/null
}

function clashproxy() {
    case "$1" in
    on)
        systemctl is-active "$BIN_KERNEL_NAME" >&/dev/null || {
            _failcat '代理程序未运行，请执行 clashon 开启代理环境'
            return 1
        }
        _set_system_proxy
        _okcat '已开启系统代理'
        ;;
    off)
        _unset_system_proxy
        _okcat '已关闭系统代理'
        ;;
    status)
        local system_proxy_status=$(sudo "$BIN_YQ" '.system-proxy.enable' "$CLASH_CONFIG_MIXIN" 2>/dev/null)
        [ "$system_proxy_status" = "false" ] && {
            _failcat "系统代理：关闭"
            return 1
        }
        _okcat "系统代理：开启
http_proxy： $http_proxy
socks_proxy：$all_proxy"
        ;;
    *)
        cat <<EOF
用法: clashproxy [on|off|status]
    on      开启系统代理
    off     关闭系统代理
    status  查看系统代理状态
EOF
        ;;
    esac
}

function clashstatus() {
    sudo systemctl status "$BIN_KERNEL_NAME" "$@"
}

function clashui() {
    _get_ui_port
    # 公网ip
    # ifconfig.me
    local query_url='api64.ipify.org'
    local public_ip=$(curl -s --noproxy "*" --connect-timeout 2 $query_url)
    local public_address="http://${public_ip:-公网}:${UI_PORT}/ui"
    # 内网ip
    # ip route get 1.1.1.1 | grep -oP 'src \K\S+'
    local local_ip=$(hostname -I | awk '{print $1}')
    local local_address="http://${local_ip}:${UI_PORT}/ui"
    printf "\n"
    printf "╔═══════════════════════════════════════════════╗\n"
    printf "║                %s                  ║\n" "$(_okcat 'Web 控制台')"
    printf "║═══════════════════════════════════════════════║\n"
    printf "║                                               ║\n"
    printf "║     🔓 注意放行端口：%-5s                    ║\n" "$UI_PORT"
    printf "║     🏠 内网：%-31s  ║\n" "$local_address"
    printf "║     🌏 公网：%-31s  ║\n" "$public_address"
    printf "║     ☁️  公共：%-31s  ║\n" "$URL_CLASH_UI"
    printf "║                                               ║\n"
    printf "╚═══════════════════════════════════════════════╝\n"
    printf "\n"
}

_merge_config_restart() {
    local backup="/tmp/rt.backup"
    sudo cat "$CLASH_CONFIG_RUNTIME" 2>/dev/null | sudo tee $backup >&/dev/null
    sudo "$BIN_YQ" eval-all '. as $item ireduce ({}; . *+ $item) | (.. | select(tag == "!!seq")) |= unique' \
        "$CLASH_CONFIG_MIXIN" "$CLASH_CONFIG_RAW" "$CLASH_CONFIG_MIXIN" | sudo tee "$CLASH_CONFIG_RUNTIME" >&/dev/null
    _valid_config "$CLASH_CONFIG_RUNTIME" || {
        sudo cat $backup | sudo tee "$CLASH_CONFIG_RUNTIME" >&/dev/null
        _error_quit "验证失败：请检查 Mixin 配置"
    }
    clashrestart
}

function clashsecret() {
    case "$#" in
    0)
        _okcat "当前密钥：$(sudo "$BIN_YQ" '.secret // ""' "$CLASH_CONFIG_RUNTIME")"
        ;;
    1)
        sudo "$BIN_YQ" -i ".secret = \"$1\"" "$CLASH_CONFIG_MIXIN" || {
            _failcat "密钥更新失败，请重新输入"
            return 1
        }
        _merge_config_restart
        _okcat "密钥更新成功，已重启生效"
        ;;
    *)
        _failcat "密钥不要包含空格或使用引号包围"
        ;;
    esac
}

_tunstatus() {
    local tun_status=$(sudo "$BIN_YQ" '.tun.enable' "${CLASH_CONFIG_RUNTIME}")
    # shellcheck disable=SC2015
    [ "$tun_status" = 'true' ] && _okcat 'Tun 状态：启用' || _failcat 'Tun 状态：关闭'
}

_tunoff() {
    _tunstatus >/dev/null || return 0
    sudo "$BIN_YQ" -i '.tun.enable = false' "$CLASH_CONFIG_MIXIN"
    _merge_config_restart && _okcat "Tun 模式已关闭"
}

_tunon() {
    _tunstatus 2>/dev/null && return 0
    sudo "$BIN_YQ" -i '.tun.enable = true' "$CLASH_CONFIG_MIXIN"
    _merge_config_restart
    sleep 0.5s
    sudo journalctl -u "$BIN_KERNEL_NAME" --since "1 min ago" | grep -E -m1 'unsupported kernel version|Start TUN listening error' && {
        _tunoff >&/dev/null
        _error_quit '不支持的内核版本'
    }
    _okcat "Tun 模式已开启"
}

function clashtun() {
    case "$1" in
    on)
        _tunon
        ;;
    off)
        _tunoff
        ;;
    *)
        _tunstatus
        ;;
    esac
}

function clashupdate() {
    local url=$(cat "$CLASH_CONFIG_URL")
    local is_auto

    case "$1" in
    auto)
        is_auto=true
        [ -n "$2" ] && url=$2
        ;;
    log)
        sudo tail "${CLASH_UPDATE_LOG}" 2>/dev/null || _failcat "暂无更新日志"
        return 0
        ;;
    *)
        [ -n "$1" ] && url=$1
        ;;
    esac

    # 如果没有提供有效的订阅链接（url为空或者不是http开头），则使用默认配置文件
    [ "${url:0:4}" != "http" ] && {
        _failcat "没有提供有效的订阅链接：使用 ${CLASH_CONFIG_RAW} 进行更新..."
        url="file://$CLASH_CONFIG_RAW"
    }

    # 如果是自动更新模式，则设置定时任务
    [ "$is_auto" = true ] && {
        sudo grep -qs 'clashupdate' "$CLASH_CRON_TAB" || echo "0 0 */2 * * $_SHELL -i -c 'clashupdate $url'" | sudo tee -a "$CLASH_CRON_TAB" >&/dev/null
        _okcat "已设置定时更新订阅" && return 0
    }

    _okcat '👌' "正在下载：原配置已备份..."
    sudo cat "$CLASH_CONFIG_RAW" | sudo tee "$CLASH_CONFIG_RAW_BAK" >&/dev/null

    _rollback() {
        _failcat '🍂' "$1"
        sudo cat "$CLASH_CONFIG_RAW_BAK" | sudo tee "$CLASH_CONFIG_RAW" >&/dev/null
        _failcat '❌' "[$(date +"%Y-%m-%d %H:%M:%S")] 订阅更新失败：$url" 2>&1 | sudo tee -a "${CLASH_UPDATE_LOG}" >&/dev/null
        _error_quit
    }

    _download_config "$CLASH_CONFIG_RAW" "$url" || _rollback "下载失败：已回滚配置"
    _valid_config "$CLASH_CONFIG_RAW" || _rollback "转换失败：已回滚配置，转换日志：$BIN_SUBCONVERTER_LOG"

    _merge_config_restart && _okcat '🍃' '订阅更新成功'
    echo "$url" | sudo tee "$CLASH_CONFIG_URL" >&/dev/null
    _okcat '✅' "[$(date +"%Y-%m-%d %H:%M:%S")] 订阅更新成功：$url" | sudo tee -a "${CLASH_UPDATE_LOG}" >&/dev/null
}

function clashmixin() {
    case "$1" in
    -e)
        sudo vim "$CLASH_CONFIG_MIXIN" && {
            _merge_config_restart && _okcat "配置更新成功，已重启生效"
        }
        ;;
    -r)
        less -f "$CLASH_CONFIG_RUNTIME"
        ;;
    *)
        less -f "$CLASH_CONFIG_MIXIN"
        ;;
    esac
}

function clashctl() {
    case "$1" in
    on)
        clashon
        ;;
    off)
        clashoff
        ;;
    ui)
        clashui
        ;;
    status)
        shift
        clashstatus "$@"
        ;;
    proxy)
        shift
        clashproxy "$@"
        ;;
    tun)
        shift
        clashtun "$@"
        ;;
    mixin)
        shift
        clashmixin "$@"
        ;;
    secret)
        shift
        clashsecret "$@"
        ;;
    update)
        shift
        clashupdate "$@"
        ;;
    autostart)
        shift
        clashautostart "$@"
        ;;
    autoproxy)
        shift
        clashautoproxy "$@"
        ;;
    *)
        shift
        clashhelp "$@"
        ;;
    esac
}

clashhelp() {
    cat <<EOF
    
Usage:
    clashctl COMMAND  [OPTION]

Commands:
    on                      开启代理
    off                     关闭代理
    proxy    [on|off]       系统代理
    ui                      面板地址
    status                  内核状况
    tun      [on|off]       Tun 模式
    mixin    [-e|-r]        Mixin 配置
    secret   [SECRET]       Web 密钥
    update   [auto|log]     更新订阅
    autostart [on|off]      开机自启 (enable|disable)
    autoproxy [on|off]      登录自动加载代理环境

EOF
}


# 自启动管理功能
clashautostart() {
    local action="$1"
    
    case "$action" in
        on|enable)
            if systemctl enable "$BIN_KERNEL_NAME" >/dev/null 2>&1; then
                _okcat '✅' "已启用开机自启动"
                _okcat 'ℹ️' "服务将在下次重启时自动启动"
            else
                _failcat '❌' "启用自启动失败，请检查权限"
                return 1
            fi
            ;;
        off|disable)
            if systemctl disable "$BIN_KERNEL_NAME" >/dev/null 2>&1; then
                _okcat '✅' "已禁用开机自启动"
                _okcat 'ℹ️' "服务将不会在重启时自动启动"
            else
                _failcat '❌' "禁用自启动失败，请检查权限"
                return 1
            fi
            ;;
        status|"")
            local status=$(systemctl is-enabled "$BIN_KERNEL_NAME" 2>/dev/null || echo "disabled")
            case "$status" in
                enabled)
                    _okcat '🚀' "开机自启动：已启用"
                    ;;
                disabled)
                    _okcat '🔒' "开机自启动：已禁用"
                    ;;
                *)
                    _okcat '❓' "开机自启动：状态未知 ($status)"
                    ;;
            esac
            ;;
        *)
            _failcat '❌' "无效参数。用法: clashctl autostart [on|off|status]"
            cat << EOF

自启动管理:
  clashctl autostart on      # 启用开机自启
  clashctl autostart off     # 禁用开机自启
  clashctl autostart status  # 查看自启状态

EOF
            return 1
            ;;
    esac
}

# 自动加载代理环境管理功能
clashautoproxy() {
    local action="$1"
    local auto_proxy_file="/opt/clash/.auto_proxy"
    
    case "$action" in
        on|enable)
            echo "true" | sudo tee "$auto_proxy_file" >/dev/null
            _okcat '✅' "已启用登录自动加载代理环境"
            _okcat 'ℹ️' "下次登录终端时将自动执行 clashon"
            ;;
        off|disable)
            echo "false" | sudo tee "$auto_proxy_file" >/dev/null
            _okcat '✅' "已禁用登录自动加载代理环境"
            _okcat 'ℹ️' "下次登录终端时不会自动加载代理"
            ;;
        status|"")
            if [ -f "$auto_proxy_file" ]; then
                local status=$(cat "$auto_proxy_file" 2>/dev/null || echo "false")
                case "$status" in
                    true)
                        _okcat '🚀' "登录自动加载代理：已启用"
                        ;;
                    false)
                        _okcat '🔒' "登录自动加载代理：已禁用"
                        ;;
                    *)
                        _okcat '❓' "登录自动加载代理：状态未知 ($status)"
                        ;;
                esac
            else
                _okcat '🔒' "登录自动加载代理：已禁用（默认）"
            fi
            ;;
        *)
            _failcat '❌' "无效参数。用法: clashctl autoproxy [on|off|status]"
            cat << EOF

自动加载代理环境管理:
  clashctl autoproxy on      # 启用登录自动加载代理
  clashctl autoproxy off     # 禁用登录自动加载代理
  clashctl autoproxy status  # 查看当前状态

注意：这控制的是登录终端时是否自动执行 clashon（显示"😼 已开启代理环境"）

EOF
            return 1
            ;;
    esac
}

# 快捷命令别名
