#!/bin/bash
# arch-setup-personalized.sh - 为你的真实机器定制的 Arch Linux 一键配置脚本
# 作者: qin
# 适用: AMD Ryzen 5 5500U / Niri + Waybar / btrfs

set -euo pipefail

# 🎨 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 📝 日志函数
log()   { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
info()  { echo -e "${BLUE}[NOTE]${NC} $1"; }

# ✅ 检查 root
if [[ $EUID -ne 0 ]]; then
    error "此脚本需要 root 权限运行: sudo $0"
    exit 1
fi

# 检测当前用户
REAL_USER="${SUDO_USER:-$(who am i | awk '{print $1}')}"
REAL_USER="${REAL_USER:-root}"
HOME_DIR="/home/${REAL_USER}"
if [[ "$REAL_USER" == "root" ]]; then
    HOME_DIR="/root"
fi
log "检测到用户: ${REAL_USER} (家目录: ${HOME_DIR})"

# 确认是否继续
read -r -p "确认开始配置? [y/N] " ans
[[ "$ans" == "y" || "$ans" == "Y" ]] || { info "已取消"; exit 0; }

# ⏱️ 计时
START_TIME=$(date +%s)

# 🚀 第一步：系统更新与基础工具
log "更新系统与密钥环..."
pacman -Sy --noconfirm archlinux-keyring || true
pacman -Syu --noconfirm --needed \
    bash bash-completion \
    git vim curl wget unzip zip p7zip \
    btrfs-progs \
    linux-zen-headers amd-ucode \
    networkmanager wpa_supplicant \
    bluez bluez-utils \
    pipewire pipewire-alsa pipewire-pulse pipewire-jack \
    xdg-user-dirs xdg-utils \
    man-db man-pages \
    sudo

# 🐧 第二步：用户权限配置
log "配置用户权限..."
usermod -aG wheel,audio,video,storage,input "${REAL_USER}" || true
if ! grep -q "^%wheel ALL=(ALL:ALL) ALL" /etc/sudoers; then
    echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers.d/99-wheel
    chmod 440 /etc/sudoers.d/99-wheel
    log "✅ wheel 组已获得 sudo 权限"
fi

# 🖥️ 第三步：桌面环境 (Niri + Waybar)
log "安装桌面环境..."
pacman -S --noconfirm --needed \
    niri \
    waybar \
    foot \
    kitty \
    qt5-base qt5-wayland qt6-base qt6-wayland \
    xwayland \
    libinput \
    mesa vulkan-radeon libva-mesa-driver \
    xdg-desktop-portal xdg-desktop-portal-gnome \
    polkit polkit-kde-agent \
    swaybg grim slurp wl-clipboard \
    mako

# 复制 niri 配置
log "配置 Niri..."
mkdir -p "${HOME_DIR}/.config/niri"
if [[ -f "${HOME_DIR}/.config/niri/config.kdl" ]]; then
    info "✅ 已存在 niri 配置，保留"
else
    niri msg action do-nothing 2>/dev/null || true
fi

# 复制 waybar 配置
mkdir -p "${HOME_DIR}/.config/waybar"
if [[ ! -f "${HOME_DIR}/.config/waybar/config.jsonc" ]]; then
    cat > "${HOME_DIR}/.config/waybar/config.jsonc" << 'EOF'
{
    "layer": "top",
    "position": "top",
    "modules-left": ["niri/workspaces"],
    "modules-center": ["clock"],
    "modules-right": ["network", "cpu", "memory", "battery", "tray"],
    "clock": { "format": "{:%Y-%m-%d %H:%M}" },
    "network": { "format-wifi": " {essid}", "format-ethernet": " {ifname}" },
    "cpu": { "format": " {usage}%" },
    "memory": { "format": " {}%" },
    "battery": { "format": " {capacity}%" }
}
EOF
    log "✅ waybar 默认配置已生成"
fi

# 🐱 第四步：输入法 Fcitx5
log "安装配置 Fcitx5..."
pacman -S --noconfirm --needed \
    fcitx5 fcitx5-chinese-addons fcitx5-configtool \
    fcitx5-gtk fcitx5-qt \
    fcitx5-material-color

mkdir -p "${HOME_DIR}/.config/fcitx5"
cat > /etc/environment << EOF
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
GLFW_IM_MODULE=fcitx
EOF
log "✅ fcitx5 环境变量已写入 /etc/environment"

# 🐳 第五步：虚拟化
log "设置虚拟化..."
pacman -S --noconfirm --needed libvirt virt-manager qemu-desktop dnsmasq
systemctl enable libvirtd.service
log "✅ libvirtd 已启用"

# 👾 第六步：游戏与多媒体
log "安装游戏与多媒体..."
pacman -S --noconfirm --needed \
    steam \
    wine winetricks \
    obs-studio \
    mpv vlc ffmpeg \
    gamemode lib32-gamemode \
    mangohud lib32-mangohud

# 📱 第七步：WayDroid
if ! command -v waydroid &>/dev/null; then
    log "安装 WayDroid..."
    pacman -S --noconfirm --needed waydroid
    waydroid init -s GAPPS || true
fi
waydroid prop set persist.waydroid.fake_wifi 1 || true
waydroid prop set persist.waydroid.fake_touch 1 || true
log "✅ WayDroid 假触控/假WiFi 已设置"

# 📁 第八步：文件管理与系统工具
log "安装文件管理与监控工具..."
pacman -S --noconfirm --needed \
    thunar gvfs file-roller tumbler ffmpegthumbnailer \
    btop htop fastfetch \
    acpi lm_sensors smartmontools iotop nethogs \
    dnsutils iputils net-tools openssh rsync \
    gzip bzip2 xz zstd \
    neofetch

# 🌐 第九步：网络与主机名
log "配置网络..."
hostnamectl set-hostname arch-pc || true
systemctl enable NetworkManager.service
systemctl enable sshd.service || true
if [[ ! -f "${HOME_DIR}/.ssh/id_ed25519" ]]; then
    mkdir -p "${HOME_DIR}/.ssh"
    ssh-keygen -t ed25519 -f "${HOME_DIR}/.ssh/id_ed25519" -N "" || true
    chown -R "${REAL_USER}:${REAL_USER}" "${HOME_DIR}/.ssh"
    log "✅ SSH 密钥已生成"
fi

# 📊 第十步：系统优化
log "优化系统..."
# swappiness
if ! grep -q "vm.swappiness" /etc/sysctl.d/99-custom.conf 2>/dev/null; then
    echo "vm.swappiness=30" >> /etc/sysctl.d/99-custom.conf
fi
# AMD GPU 配置
mkdir -p /etc/X11/xorg.conf.d
cat > /etc/X11/xorg.conf.d/20-amdgpu.conf << 'EOF'
Section "Device"
    Identifier "AMD"
    Driver "modesetting"
    Option "TearFree" "true"
log "✅ 系统优化已应用"

# 🧊 第十一点五步：Ryzen 温控墙 (CPU 功耗/温度限制)
log "配置 Ryzen 5 5500U 温控墙..."
# 安装 ryzenadj
if ! command -v ryzenadj &>/dev/null; then
    pacman -S --noconfirm --needed ryzenadj || warn "ryzenadj 安装失败，跳过温控墙配置"
fi
# 创建温控墙脚本
cat > /usr/local/bin/ryzenadj-optimization.sh << 'EOF'
#!/bin/bash
# Ryzen 5 5500U 优化脚本
# 设置温度上限为90°C，调整功耗墙

# 设置温度限制
ryzenadj --tctl-temp=90

# 设置功耗墙 (单位: mW)
ryzenadj --stapm-limit=25000 --fast-limit=35000 --slow-limit=25000

# 关闭WiFi省电模式
iw wlan0 set power_save off 2>/dev/null || true
EOF
chmod +x /usr/local/bin/ryzenadj-optimization.sh

# 创建 systemd 服务，开机自动应用
cat > /etc/systemd/system/ryzenadj-optimization.service << 'EOF'
[Unit]
Description=Ryzen 5 5500U 温控墙优化
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/ryzenadj-optimization.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable ryzenadj-optimization.service
log "✅ Ryzen 温控墙已配置并设为开机自启"

# 🖼️ 第十一步：壁纸设置
    log "检测到壁纸目录 ~/wallpapers"
    WALLPAPER=$(find "${HOME_DIR}/wallpapers" -type f \( -name "*.jpg" -o -name "*.png" \) | shuf -n 1)
    if [[ -n "$WALLPAPER" ]]; then
        # 写入 niri 壁纸配置（如使用 swaybg）
        mkdir -p "${HOME_DIR}/.config"
        cat > "${HOME_DIR}/.config/swaybg.sh" << EOF
#!/bin/bash
while true; do
    swaybg -i "\$(find "${HOME_DIR}/wallpapers" -type f \( -name "*.jpg" -o -name "*.png" \) | shuf -n 1)" &
    sleep 3600
done
EOF
        chmod +x "${HOME_DIR}/.config/swaybg.sh"
        log "✅ 壁纸轮换脚本已生成 (每小时轮换)"
    fi
else
    warn "未找到 ~/wallpapers 目录，跳过壁纸配置"
fi

# 🎉 完成
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
log "🎉 配置完成！用时 ${ELAPSED} 秒"
info "建议重启系统: sudo reboot"
info ""
info "本次配置包含:"
info "  ✅ Niri + Waybar 桌面"
info "  ✅ Fcitx5 中文输入法"
info "  ✅ Steam + Wine + 游戏优化 (gamemode/mangohud)"
info "  ✅ WayDroid 安卓模拟器"
info "  ✅ libvirt 虚拟化"
info "  ✅ OBS / mpv / VLC 多媒体"
info "  ✅ btop/fastfetch 监控工具"
info "  ✅ SSH + NetworkManager 网络服务"
info "  ✅ 壁纸轮换"

exit 0
