#!/bin/bash
set -e
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

if [[ $EUID -eq 0 ]]; then
    TARGET_DIR="/usr/local/bin"
else
    TARGET_DIR="$HOME/bin"
    mkdir -p "$TARGET_DIR"
    if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
        echo 'export PATH="$PATH:$HOME/bin"' >> "$HOME/.bashrc"
        export PATH="$PATH:$HOME/bin"
        echo -e "${GREEN}已将 $HOME/bin 加入 PATH，重开终端生效。${RESET}"
    fi
fi

install_nixore() {
    wget -q -O "$TARGET_DIR/nixore" https://raw.githubusercontent.com/nixore-run/manager-script/main/install.sh
    chmod +x "$TARGET_DIR/nixore"
    echo -e "${GREEN}安装完成！以后输入 nixore 即可启动菜单。${RESET}"
}

install_dependencies() {
    echo -e "${GREEN}正在安装必要依赖...${RESET}"
    if command -v apt >/dev/null 2>&1; then
        apt update -y && apt install -y curl wget unzip
    elif command -v yum >/dev/null 2>&1; then
        yum install -y curl wget unzip
    else
        echo -e "${RED}不支持的系统，需手动安装 curl wget unzip${RESET}"
    fi
}

reinstall_system() {
    clear
    # 检测是否是 LXC 环境
    if grep -qaE 'lxc|container' /proc/1/environ 2>/dev/null || grep -qaE 'lxc|container' /proc/1/cgroup 2>/dev/null; then
        echo -e "${YELLOW}⚠️ 检测到当前环境为 LXC 容器，不支持重装系统！${RESET}"
        echo -e "${GRAY}此功能仅适用于独立服务器或完整虚拟机环境。${RESET}"
        echo
        return
    fi
    echo -e "${GREEN}=== 选择要安装的系统版本 ===${RESET}"
    echo "1) Debian 12"
    echo "2) Debian 11"
    echo "3) Debian 10"
    echo "4) Ubuntu 24.10"
    echo "5) Ubuntu 24.04"
    echo "6) Ubuntu 22.04"
    echo "7) Ubuntu 20.04"
    echo "8) Debian 12(备用推荐)"
    echo "9) Debian 11(备用推荐)"
    echo "10) almalinux 9"
    echo "11) almalinux 8"
    echo "12) almalinux 8(备用推荐)"
    echo "13) Debian 13"
    echo "b) 返回"
    read -p "请选择: " os_choice
    case "$os_choice" in
        1) curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && sudo bash reinstall.sh debian 12 ;;
        2) curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && sudo bash reinstall.sh debian 11 ;;
        3) curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && sudo bash reinstall.sh debian 10 ;;
        4) curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && sudo bash reinstall.sh ubuntu 24.10 ;;
        5) curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && sudo bash reinstall.sh ubuntu 24.04 ;;
        6) curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && sudo bash reinstall.sh ubuntu 22.04 ;;
        7) curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && sudo bash reinstall.sh ubuntu 20.04 ;;
        8) curl -sS -O https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh && bash InstallNET.sh -debian 12 -pwd 'nixore123456' ;;
        9) curl -sS -O https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh && bash InstallNET.sh -debian 11 -pwd 'nixore123456' ;;
        10) curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && sudo bash reinstall.sh almalinux 9 ;;
        11) curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && sudo bash reinstall.sh almalinux 8 ;;
        12) curl -sS -O https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh && bash InstallNET.sh -almalinux 8 -pwd 'nixore123456' ;;
        13) curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && sudo bash reinstall.sh debian 13 ;;
        b) exit 0 ;;
        *) echo -e "${RED}无效选项！${RESET}"; sleep 2; exit 1 ;;
    esac
    exit 0
}

enable_bbr() {
    # 检测是否是 LXC 环境
    if grep -qaE 'lxc|container' /proc/1/environ 2>/dev/null || grep -qaE 'lxc|container' /proc/1/cgroup 2>/dev/null; then
        echo -e "${YELLOW}⚠️ 检测到当前环境为 LXC 容器，不支持该BBR + TCP 优化！${RESET}"
        echo -e "${GRAY}此功能仅适用于独立服务器或完整虚拟机环境。${RESET}"
        echo
        return
    fi
    echo -e "${GREEN}正在开启 BBR 并覆盖写入优化参数...${RESET}"

    # 先备份原始配置
    cp /etc/sysctl.conf /etc/sysctl.conf.bak

    # 覆盖写入优化内容
    cat > /etc/sysctl.conf <<EOF
# ===== Nixore BBR + TCP 优化参数 =====
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.rmem_default = 8388608
net.core.wmem_default = 8388608
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864

net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_frto = 2

net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1

net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_tw_reuse = 1

net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.core.netdev_max_backlog = 250000

net.ipv4.tcp_syn_retries = 3
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_retries1 = 3
net.ipv4.tcp_retries2 = 8

net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_ecn = 0

fs.file-max = 16777216
vm.swappiness = 10
# ===== End Nixore =====
EOF

    # 立即生效
    sysctl -p

    echo -e "${GREEN}BBR 和 TCP 网络参数已覆盖写入并生效！${RESET}"
    sleep 2
    exit 0
}

install_hipf() {
    clear
    echo -e "${GREEN}正在安装 HiaPortFusion (HAProxy+GOST聚合转发脚本)...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/hiapb/HiaPortFusion/main/install.sh)
    exit 0
}

install_realm() {
    clear
    echo -e "${GREEN}正在安装 Realm TCP+UDP万能转发脚本...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/hiapb/hia-realm/main/install.sh)
    exit 0
}

install_gost() {
    clear
    echo -e "${GREEN}正在安装 GOST TCP+UDP 转发管理脚本...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/hiapb/hia-gost/main/install.sh)
    sleep 2
    exit 0
}

check_ports() {
    echo -e "${GREEN}正在启动 服务器http/https端口检测...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/hiapb/check-web-ports/main/install.sh)
    exit 0
}

repair_apt_sources() {
    echo -e "${GREEN}🔧 正在修复 APT 源 404 问题，请稍候...${RESET}"
    sleep 1

    # 清理缓存与临时文件
    apt-get clean -y >/dev/null 2>&1

    # 尝试修复源并更新索引
    apt-get update --fix-missing -y

    # 自动修复依赖关系问题
    apt-get install -f -y

    # 可选：安全升级而非全量升级，避免破坏系统依赖
    apt-get dist-upgrade -y

    echo -e "${GREEN}✅ APT 源修复完成！${RESET}"
    sleep 2
}

nuro_frp() {
    echo -e "${GREEN}正在启动 Nuro · FRP 一键部署&管理菜单...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/nuro-hia/nuro-frp/main/install.sh)
    sleep 2
    exit 0
}

nuro_realm_tunnel() {
    echo -e "${GREEN}正在启动 Nuro · REALM(隧道) 一键部署&管理菜单...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/nuro-hia/realm/main/tunnel.sh)
    sleep 2
    exit 0
}

install_xui() {
    clear
    echo -e "${GREEN}正在安装 X-UI 面板...${RESET}"
    bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)
    sleep 2
    exit 0
}

install_3-xui(){
    clear
    echo -e "${GREEN}正在安装 3X-UI 面板...${RESET}"
    bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
    sleep 2
    exit 0
}

install_aapanel() {
    clear
    echo -e "${GREEN}正在安装国际版宝塔（aapanel）...${RESET}"
    wget -O install.sh http://www.aapanel.com/script/install-ubuntu_6.0_en.sh && bash install.sh aapanel
    sleep 2
    exit 0
}

dlam_tunnel(){
    clear
    echo -e "${GREEN}正在安装多啦A梦面板...${RESET}"
    curl -L https://raw.githubusercontent.com/bqlpfy/flux-panel/refs/heads/main/panel_install.sh -o panel_install.sh && chmod +x panel_install.sh && ./panel_install.sh
    sleep 2
    exit 0
}

 manage_dlamnode(){
    clear
    echo -e "${GREEN}多啦A梦节点端管理...${RESET}"
    curl -L https://raw.githubusercontent.com/bqlpfy/flux-panel/refs/heads/main/install.sh -o install.sh && chmod +x install.sh && ./install.sh
    sleep 2
    exit 0
 }

 manage_clean(){
    clear
    echo -e "${GREEN}🧹一键深度清理...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/hiapb/debian-safe/main/clean.sh)
    sleep 2
    exit 0
 }
 

install_docker(){
    clear
    echo -e "${GREEN}正在安装 Docker...${RESET}"
    curl -fsSL https://get.docker.com | bash -s docker
    sleep 2
    exit 0
}

install_1panel() {
    clear
    echo -e "${GREEN}正在安装 1Panel...${RESET}"
    curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh && bash quick_start.sh
    sleep 2
    exit 0
}

install_V2bX() {
    clear
    echo -e "${GREEN}正在安装 V2bX...${RESET}"
    wget -N https://raw.githubusercontent.com/wyx2685/V2bX-script/master/install.sh && bash install.sh
    sleep 2
    exit 0
}

install_XrayR() {
    clear
    echo -e "${GREEN}正在安装 XrayR...${RESET}"
    wget -N https://raw.githubusercontent.com/XrayR-project/XrayR-release/master/install.sh && bash install.sh
    sleep 2
    exit 0
}

install_openlist(){
    clear
    echo -e "${GREEN}正在安装 OpenList...${RESET}"
    curl -fsSL https://res.oplist.org/script/v4.sh > install-openlist-v4.sh && sudo bash install-openlist-v4.sh
    sleep 2
    exit 0
}

install_aurora() {
    clear
    echo -e "${GREEN}正在安装极光面板...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/Aurora-Admin-Panel/deploy/main/install.sh)
    sleep 2
    exit 0
}

install_xd() {
    clear
    echo -e "${GREEN}正在安装咸蛋面板...${RESET}"
    bash <(wget --no-check-certificate -qO- 'https://sh.xdmb.xyz/xiandan/xd.sh')
    sleep 2
    exit 0
}

check_ip_quality() {
    clear
    echo -e "${GREEN}正在进行 IP 质量检测...${RESET}"
    bash <(curl -sL IP.Check.Place)
    echo -e "${GREEN}IP 质量检测完成！${RESET}"
    sleep 2
    exit 0
}

nodequality_tool() {
    clear
    echo -e "${GREEN}正在进行 NodeQuality 测评...${RESET}"
    bash <(curl -sL https://run.NodeQuality.com)
    sleep 2
    exit 0
}

uninstall_nixore() {
    echo -e "${RED}正在卸载 Nixore 管理脚本...${RESET}"
    rm -f "$TARGET_DIR/nixore"
    echo -e "${GREEN}Nixore 管理脚本已卸载！${RESET}"
    exit 0
}

show_menu() {
    clear
    echo -e "${GREEN}=== Nixore 一键管理脚本 ===${RESET}"
    echo "----------------------------------"
    echo "1) 重装系统"
    echo "2) 修复 APT 源"
    echo "3) 开启 BBR 并优化 TCP 设置"
    echo "4) 安装 3X-UI 面板"
    echo "5) 安装 X-UI 面板"
    echo "6) 安装 V2bX"
    echo "7) 安装 XrayR"
    echo "8) 安装 Docker"
    echo "9) 安装 国际版宝塔 (aapanel)"
    echo "10) 安装 1Panel 面板"
    echo "11) 安装 极光面板"
    echo "12) 安装 咸蛋面板"
    echo "13) 哆啦A梦面板部署"
    echo "14) 多啦A梦节点端管理"
    echo "15) 安装 Realm TCP+UDP 转发"
    echo "16) 安装 GOST TCP+UDP 转发"
    echo "17) 安装 HiaPortFusion (HAProxy+GOST聚合转发)"
    echo "18) Nuro · REALM(隧道) 一键部署&管理"
    echo "19) Nuro · FRP 一键部署&管理"
    echo "20) 安装 OpenList"
    echo "21) 🧹一键深度清理"
    echo "22) IP 质量检测"
    echo "23) 服务器 http/https端口检测"
    echo "24) NodeQuality 测评工具"
    echo "0) 卸载 Nixore 管理脚本"
    echo "q) 退出"
    echo "----------------------------------"
    read -p "请选择操作: " choice
    case "$choice" in
        1)  reinstall_system ;;
        2)  repair_apt_sources ;;
        3)  enable_bbr ;;
        4)  install_3-xui ;;
        5)  install_xui ;;
        6)  install_V2bX ;;
        7)  install_XrayR ;;
        8)  install_docker ;;
        9)  install_aapanel ;;
        10) install_1panel ;;
        11) install_aurora ;;
        12) install_xd ;;
        13) dlam_tunnel ;;
        14) manage_dlamnode ;;
        15) install_realm ;;
        16) install_gost ;;
        17) install_hipf ;;
        18) nuro_realm_tunnel ;;
        19) nuro_frp ;;
        20) install_openlist ;;
        21) manage_clean ;;
        22) check_ip_quality ;;
        23) check_ports ;;
        24) nodequality_tool ;;
        0)  uninstall_nixore ;;
        q)  exit 0 ;;
        *)  echo -e "${RED}无效选项！${RESET}"; sleep 2; exit 1 ;;
    esac
}

if [[ "$0" != "$TARGET_DIR/nixore" ]]; then
    install_nixore
    echo -e "${GREEN}立即为你启动菜单面板...${RESET}"
    sleep 1
    exec "$TARGET_DIR/nixore"
    exit 0
else
    show_menu
fi
