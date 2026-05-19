#!/usr/bin/env bash
# ============================================================
#  AIO Fedora Setup Script — Interactive Edition
#  Yêu cầu: Fedora 41+ | DNF5 | GNOME
#  Dành cho cộng đồng Linux Việt Nam 🇻🇳
#
#  Cấu trúc repo (GitHub):
#  AIO-Fedora-setup-Scripts/
#  ├── scripts.sh              ← file này
#  └── demo/
#      └── MacTahoe-Theme-Demo.png
# ============================================================

# ── Colors ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'
BG_BLUE='\033[44m'

# ── Cursor ──────────────────────────────────────────────────
hide_cursor() { printf '\033[?25l'; }
show_cursor() { printf '\033[?25h'; }

cleanup() { show_cursor; tput cnorm; echo ""; }
trap cleanup EXIT INT TERM

# ════════════════════════════════════════════════════════════
#  BANNER
# ════════════════════════════════════════════════════════════
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "  ███████╗███████╗██████╗  ██████╗ ██████╗  █████╗ "
    echo "  ██╔════╝██╔════╝██╔══██╗██╔═══██╗██╔══██╗██╔══██╗"
    echo "  █████╗  █████╗  ██║  ██║██║   ██║██████╔╝███████║"
    echo "  ██╔══╝  ██╔══╝  ██║  ██║██║   ██║██╔══██╗██╔══██║"
    echo "  ██║     ███████╗██████╔╝╚██████╔╝██║  ██║██║  ██║"
    echo "  ╚═╝     ╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝"
    echo -e "${RESET}"
    echo -e "  ${WHITE}${BOLD}AIO Fedora Setup Script${RESET}  ${GRAY}Interactive Edition — Fedora 41+${RESET}"
    echo -e "  ${GRAY}Dành cho cộng đồng Linux Việt Nam 🇻🇳${RESET}"
    echo ""
    echo -e "  ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
}

# ════════════════════════════════════════════════════════════
#  CHECKBOX MENU ENGINE
#  Phím: ↑/↓ hoặc j/k  di chuyển
#        SPACE           toggle
#        A               chọn tất cả
#        N               bỏ hết
#        ENTER           xác nhận
# ════════════════════════════════════════════════════════════
checkbox_menu() {
    local title="$1"
    local -n _names=$2
    local -n _descs=$3
    local -n _sel=$4

    local count=${#_names[@]}
    local cursor=0
    local key

    hide_cursor

    while true; do
        tput cup 8 0

        echo -e "  ${BOLD}${WHITE}${title}${RESET}"
        echo ""
        echo -e "  ${GRAY}[SPACE] Toggle  [A] Tất cả  [N] Bỏ hết  [ENTER] Xác nhận${RESET}"
        echo -e "  ${GRAY}[↑/↓]  hoặc  [j/k]  Di chuyển${RESET}"
        echo ""

        local sel_count=0
        for i in "${!_names[@]}"; do
            [[ "${_sel[$i]}" == "1" ]] && (( sel_count++ ))
        done

        for i in "${!_names[@]}"; do
            local box
            [[ "${_sel[$i]}" == "1" ]] && box="${GREEN}[✓]${RESET}" || box="${GRAY}[ ]${RESET}"

            if [[ $i -eq $cursor ]]; then
                printf '\033[2K'
                echo -e "  ${BG_BLUE}${WHITE}  ❯ ${_names[$i]}${RESET}"
                echo -e "      ${CYAN}${DIM}↳ ${_descs[$i]}${RESET}   "
            else
                if [[ "${_sel[$i]}" == "1" ]]; then
                    echo -e "    ${box} ${GREEN}${_names[$i]}${RESET}"
                else
                    echo -e "    ${box} ${GRAY}${_names[$i]}${RESET}"
                fi
                echo -e "      ${GRAY}${DIM}↳ ${_descs[$i]}${RESET}   "
            fi
        done

        echo ""
        echo -e "  ${GRAY}Đã chọn: ${WHITE}${BOLD}${sel_count}/${count}${RESET} ${GRAY}gói${RESET}   "
        echo ""

        IFS= read -rsn1 key
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 -t 0.1 key
            case "$key" in
                '[A') (( cursor > 0 ))       && (( cursor-- )) ;;
                '[B') (( cursor < count-1 )) && (( cursor++ )) ;;
            esac
        else
            case "$key" in
                'k') (( cursor > 0 ))       && (( cursor-- )) ;;
                'j') (( cursor < count-1 )) && (( cursor++ )) ;;
                ' ')
                    [[ "${_sel[$cursor]}" == "1" ]] \
                        && _sel[$cursor]="0" \
                        || _sel[$cursor]="1"
                    ;;
                'a'|'A') for i in "${!_names[@]}"; do _sel[$i]="1"; done ;;
                'n'|'N') for i in "${!_names[@]}"; do _sel[$i]="0"; done ;;
                '') show_cursor; return 0 ;;
            esac
        fi
    done
}

# ════════════════════════════════════════════════════════════
#  LOG HELPERS
# ════════════════════════════════════════════════════════════
log_step() { echo -e "\n  ${CYAN}${BOLD}▶ ${1}${RESET}"; }
log_ok()   { echo -e "  ${GREEN}✓ ${1}${RESET}"; }
log_warn() { echo -e "  ${YELLOW}⚠ ${1}${RESET}"; }
log_err()  { echo -e "  ${RED}✗ ${1}${RESET}"; }
log_div()  { echo -e "  ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"; }

# ════════════════════════════════════════════════════════════
#  KIỂM TRA FEDORA 41+ VÀ DNF5
# ════════════════════════════════════════════════════════════
# DNF5 wrapper — dùng xuyên suốt toàn bộ script
DNF="dnf5"
DNF_OPTS="-y --assumeyes"   # tắt hoàn toàn hỏi xác nhận DNF5

check_fedora_version() {
    if ! grep -q "Fedora" /etc/os-release 2>/dev/null; then
        echo -e "  ${RED}✗ Không phát hiện Fedora Linux.${RESET}"
        echo -e "  ${GRAY}  Script này chỉ hỗ trợ Fedora 41 trở lên.${RESET}"
        exit 1
    fi

    local ver
    ver=$(rpm -E %fedora 2>/dev/null)
    if [[ -z "$ver" || "$ver" -lt 41 ]]; then
        echo -e "  ${RED}✗ Fedora ${ver} không được hỗ trợ.${RESET}"
        echo -e "  ${GRAY}  Script yêu cầu Fedora 41+ (DNF5 mặc định).${RESET}"
        exit 1
    fi

    # Đảm bảo dnf5 binary có mặt
    if ! command -v dnf5 &>/dev/null; then
        log_warn "Binary dnf5 chưa có trong PATH, thử cài..."
        sudo dnf install -y --assumeyes dnf5 dnf5-plugins || {
            echo -e "  ${RED}✗ Không thể cài DNF5. Vui lòng nâng cấp hệ thống.${RESET}"
            exit 1
        }
    fi

    echo -e "  ${GREEN}✓ Fedora ${ver} — DNF5 sẵn sàng${RESET}"
}

# ════════════════════════════════════════════════════════════
#  MODULE: HỆ THỐNG & KHO
# ════════════════════════════════════════════════════════════

do_system_update() {
    log_step "Cập nhật hệ thống (dnf5 upgrade)"
    sudo $DNF upgrade --refresh $DNF_OPTS
    log_ok "Hệ thống đã cập nhật"
}

do_rpm_fusion() {
    log_step "Kích hoạt RPM Fusion"
    local ver
    ver=$(rpm -E %fedora)
    sudo $DNF install $DNF_OPTS \
        "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${ver}.noarch.rpm" \
        "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${ver}.noarch.rpm"
    log_ok "RPM Fusion Free + Nonfree đã kích hoạt"
}

do_flathub() {
    log_step "Kích hoạt Flathub"
    sudo flatpak remote-add --if-not-exists flathub \
        https://flathub.org/repo/flathub.flatpakrepo
    log_ok "Flathub đã kích hoạt"
}

# ════════════════════════════════════════════════════════════
#  MODULE: ỨNG DỤNG
# ════════════════════════════════════════════════════════════

do_brave() {
    log_step "Cài đặt Brave Browser"
    # DNF5: config-manager là plugin trong dnf5-plugins
    sudo $DNF config-manager addrepo \
        --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
    sudo $DNF install $DNF_OPTS brave-browser
    log_ok "Brave Browser đã cài xong"
}

do_chrome() {
    log_step "Cài đặt Google Chrome"
    local tmp
    tmp=$(mktemp -d)
    wget -q --show-progress -O "${tmp}/chrome.rpm" \
        https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
    # --allowerasing vì Chrome tự thêm repo riêng và có thể conflict
    sudo $DNF install $DNF_OPTS --allowerasing "${tmp}/chrome.rpm"
    rm -rf "${tmp}"
    log_ok "Google Chrome đã cài xong"
}

do_vlc_ffmpeg() {
    log_step "Cài đặt VLC + FFmpeg"
    # Fedora cài sẵn ffmpeg-free (bản bị cắt codec) conflict với
    # ffmpeg đầy đủ từ RPM Fusion. Cần swap bằng --allowerasing
    # để DNF5 tự gỡ ffmpeg-free/ffmpeg-free-libs trước khi cài.
    sudo $DNF install $DNF_OPTS --allowerasing \
        vlc \
        ffmpeg \
        ffmpeg-libs
    log_ok "VLC + FFmpeg đã cài xong"
}

do_zoom() {
    log_step "Cài đặt Zoom"
    local tmp
    tmp=$(mktemp -d)
    wget -q --show-progress -O "${tmp}/zoom.rpm" \
        https://zoom.us/client/latest/zoom_x86_64.rpm
    sudo $DNF install $DNF_OPTS --allowerasing "${tmp}/zoom.rpm"
    rm -rf "${tmp}"
    log_ok "Zoom đã cài xong"
}

do_discord() {
    log_step "Cài đặt Discord (Flatpak — Flathub)"
    flatpak install --assumeyes --noninteractive flathub com.discordapp.Discord
    log_ok "Discord đã cài xong"
}

do_bluerecorder() {
    log_step "Cài đặt Blue Recorder (Flatpak — Flathub)"
    flatpak install --assumeyes --noninteractive flathub sa.sy.bluerecorder
    log_ok "Blue Recorder đã cài xong"
}

do_gnome_tools() {
    log_step "Cài đặt GNOME Tweaks + Extension Manager"
    sudo $DNF install $DNF_OPTS gnome-tweaks gnome-extensions-app
    flatpak install --assumeyes --noninteractive flathub com.mattjakeman.ExtensionManager
    log_ok "GNOME Tweaks + Extension Manager đã cài xong"
}

do_fcitx5() {
    log_step "Cài đặt Fcitx5 + Unikey (gõ tiếng Việt)"
    # fcitx5-gtk2 đã bị khai tử trên Fedora 41+ — chỉ cần gtk4 và qt
    sudo $DNF install $DNF_OPTS \
        fcitx5 \
        fcitx5-autostart \
        fcitx5-gtk \
        fcitx5-gtk4 \
        fcitx5-qt \
        fcitx5-configtool \
        fcitx5-unikey

    # ── 1. Biến môi trường (Wayland + X11) ──────────────────
    mkdir -p "${HOME}/.config/environment.d"
    cat > "${HOME}/.config/environment.d/fcitx5.conf" << 'EOF'
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
INPUT_METHOD=fcitx
EOF
    log_ok "Biến môi trường đã cấu hình"

    # ── 2. Autostart — copy file .desktop gốc của fcitx5 ────
    # Dùng file chính thức từ /usr/share/applications/ thay vì
    # tự tạo để tránh lỗi thiếu trường hoặc sai cú pháp
    mkdir -p "${HOME}/.config/autostart"
    local desktop_src="/usr/share/applications/org.fcitx.Fcitx5.desktop"
    if [[ -f "$desktop_src" ]]; then
        cp "$desktop_src" "${HOME}/.config/autostart/"
        log_ok "Autostart đã cấu hình: ~/.config/autostart/org.fcitx.Fcitx5.desktop"
    else
        log_warn "Không tìm thấy $desktop_src — bỏ qua bước autostart"
    fi

    log_ok "Fcitx5 + Unikey đã cài và cấu hình autostart xong"
    log_warn "Đăng xuất rồi đăng nhập lại để Fcitx5 tự khởi động"
}
do_dev_tools() {
    log_step "Cài đặt Git + Fastfetch"
    sudo $DNF install $DNF_OPTS git fastfetch
    log_ok "Git + Fastfetch đã cài xong"
}

do_onlyoffice() {
    log_step "Cài đặt OnlyOffice Desktop Editors (Flatpak — Flathub)"
    flatpak install --assumeyes --noninteractive flathub org.onlyoffice.desktopeditors
    log_ok "OnlyOffice Desktop Editors đã cài xong"
}

do_wps() {
    log_step "Cài đặt WPS Office (Flatpak — Flathub)"
    flatpak install --assumeyes --noninteractive flathub com.wps.Office
    log_ok "WPS Office đã cài xong"
}

# ════════════════════════════════════════════════════════════
#  MODULE: MACTAHOE THEME
# ════════════════════════════════════════════════════════════

# Thư mục chứa script cài theme và danh sách extensions
MACTAHOE_DIR="${HOME}/AIO-MacTahoe-Themes"

create_mactahoe_folder() {
    mkdir -p "${MACTAHOE_DIR}"

    # ── EXTENSION.txt ────────────────────────────────────────
    cat > "${MACTAHOE_DIR}/EXTENSION.txt" << 'EOF'
================================================================
  GNOME Extensions cần cài cho giao diện macOS Tahoe
  Cài qua: Extension Manager (Flatpak) hoặc extensions.gnome.org
================================================================

  1. Blur my Shell
     → Làm mờ panel, overview, dash
     → https://extensions.gnome.org/extension/3193/blur-my-shell/

  2. Compiz Alike Magic Lamp Effect
     → Hiệu ứng thu nhỏ cửa sổ kiểu macOS
     → https://extensions.gnome.org/extension/3740/compiz-alike-magic-lamp-effect/

  3. Compiz Windows Effect
     → Hiệu ứng rung cửa sổ khi kéo
     → https://extensions.gnome.org/extension/3210/compiz-windows-effect/

  4. Coverflow Alt-Tab
     → Alt-Tab kiểu Cover Flow
     → https://extensions.gnome.org/extension/97/coverflow-alt-tab/

  5. Dash2Dock Animated
     → Dock kiểu macOS có animation
     → https://extensions.gnome.org/extension/4648/dash2dock-lite/

  6. Desktop Cube
     → Xoay desktop kiểu cube 3D
     → https://extensions.gnome.org/extension/4648/desktop-cube/

  7. Space Bar
     → Hiển thị workspaces trên top bar kiểu macOS Spaces
     → https://extensions.gnome.org/extension/5090/space-bar/

  8. User Themes
     → Bắt buộc! Cho phép áp dụng Shell Theme tùy chỉnh
     → https://extensions.gnome.org/extension/19/user-themes/

  9. Vitals
     → Hiển thị CPU/RAM/nhiệt độ trên top bar
     → https://extensions.gnome.org/extension/1460/vitals/

================================================================
  Sau khi cài extensions → mở GNOME Tweaks để áp dụng:
    • Appearance > Shell Theme  : macTahoe
    • Appearance > Icons        : MacTahoe
    • Appearance > Legacy Apps  : macTahoe
================================================================
EOF

    # ── SCRIPTS.sh ───────────────────────────────────────────
    cat > "${MACTAHOE_DIR}/SCRIPTS.sh" << 'SCRIPTEOF'
#!/usr/bin/env bash
# ============================================================
#  MacTahoe Theme Installer
#  Yêu cầu: Fedora 41+ | DNF5 | GNOME
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
BOLD='\033[1m'
RESET='\033[0m'

DNF="dnf5"
DNF_OPTS="-y --assumeyes"   # tắt hoàn toàn hỏi xác nhận DNF5

clear

echo -e "${CYAN}"
echo "  ███╗   ███╗ █████╗  ██████╗████████╗ █████╗ ██╗  ██╗ ██████╗ ███████╗"
echo "  ████╗ ████║██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██║  ██║██╔═══██╗██╔════╝"
echo "  ██╔████╔██║███████║██║        ██║   ███████║███████║██║   ██║█████╗  "
echo "  ██║╚██╔╝██║██╔══██║██║        ██║   ██╔══██║██╔══██║██║   ██║██╔══╝  "
echo "  ██║ ╚═╝ ██║██║  ██║╚██████╗   ██║   ██║  ██║██║  ██║╚██████╔╝███████╗"
echo "  ╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝"
echo -e "${RESET}"
echo -e "  ${WHITE}${BOLD}MacTahoe Theme Installer${RESET}  ${GRAY}Fedora 41+ | DNF5${RESET}"
echo ""
echo -e "  ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

set -e

log_step() { echo -e "\n  ${CYAN}${BOLD}▶ ${1}${RESET}"; }
log_ok()   { echo -e "  ${GREEN}✓ ${1}${RESET}"; }
log_warn() { echo -e "  ${YELLOW}⚠ ${1}${RESET}"; }

log_step "Cài dependencies"
sudo dnf5 install -y --assumeyes \
    gcc make cmake curl perl wget \
    sassc \
    wmctrl \
    gnome-tweaks \
    gtk4-devel \
    libadwaita-devel

BUILD_DIR="${HOME}/.local/share/aio-mactahoe-build"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

log_step "MacTahoe Icon Theme"
if [[ -d "MacTahoe-icon-theme" ]]; then
    git -C MacTahoe-icon-theme pull --ff-only
else
    git clone --depth=1 https://github.com/vinceliuice/MacTahoe-icon-theme.git
fi
cd MacTahoe-icon-theme && ./install.sh -b && cd "${BUILD_DIR}"

log_step "MacTahoe GTK Theme"
if [[ -d "MacTahoe-gtk-theme" ]]; then
    git -C MacTahoe-gtk-theme pull --ff-only
else
    git clone --depth=1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git
fi
cd MacTahoe-gtk-theme
./install.sh -n macTahoe -t all -l --shell -i simple -h bigger --round
sudo ./tweaks.sh -g -nd

log_step "Cho phép Flatpak apps dùng theme"
sudo flatpak override --filesystem=xdg-config/gtk-3.0
sudo flatpak override --filesystem=xdg-config/gtk-4.0

log_step "MacTahoe Wallpapers"
cd wallpaper && sudo ./install-gnome-backgrounds.sh
cd "${BUILD_DIR}"

log_ok "MacTahoe Theme đã cài xong!"

echo ""
echo -e "  ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  ${YELLOW}${BOLD}Bước tiếp theo:${RESET}"
echo -e "  ${GRAY}  1. Cài GNOME Extensions (xem file EXTENSION.txt)"
echo -e "     2. Mở GNOME Tweaks → áp dụng Shell/Icon Theme: macTahoe"
echo -e "     3. Reboot hoặc đăng xuất để áp dụng toàn bộ${RESET}"
echo ""

read -rp "  Reboot ngay bây giờ? [y/N]: " rb
if [[ "$rb" =~ ^[Yy]$ ]]; then
    sudo systemctl reboot
else
    echo -e "  ${GRAY}Nhớ reboot sau nhé!${RESET}"
fi
SCRIPTEOF

    chmod +x "${MACTAHOE_DIR}/SCRIPTS.sh"
}

do_mactahoe() {
    log_step "Tạo thư mục AIO-MacTahoe-Themes"
    create_mactahoe_folder
    log_ok "Đã tạo thư mục: ${MACTAHOE_DIR}"

    log_step "Cài đặt MacTahoe Theme (GTK + Icons + Wallpapers)"

    sudo $DNF install $DNF_OPTS \
        gcc make cmake curl perl wget \
        sassc \
        wmctrl \
        gnome-tweaks \
        gtk4-devel \
        libadwaita-devel

    local build_dir="${HOME}/.local/share/aio-mactahoe-build"
    mkdir -p "${build_dir}"
    cd "${build_dir}"

    # ── Icon Theme ───────────────────────────────────────────
    log_step "  MacTahoe Icon Theme"
    if [[ -d "MacTahoe-icon-theme" ]]; then
        git -C MacTahoe-icon-theme pull --ff-only
    else
        git clone --depth=1 https://github.com/vinceliuice/MacTahoe-icon-theme.git
    fi
    cd MacTahoe-icon-theme && ./install.sh -b && cd "${build_dir}"

    # ── GTK Theme ────────────────────────────────────────────
    log_step "  MacTahoe GTK Theme"
    if [[ -d "MacTahoe-gtk-theme" ]]; then
        git -C MacTahoe-gtk-theme pull --ff-only
    else
        git clone --depth=1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git
    fi
    cd MacTahoe-gtk-theme
    ./install.sh -n macTahoe -t all -l --shell -i simple -h bigger --round
    sudo ./tweaks.sh -g -nd

    # Cho phép Flatpak apps dùng theme
    sudo flatpak override --filesystem=xdg-config/gtk-3.0
    sudo flatpak override --filesystem=xdg-config/gtk-4.0

    # ── Wallpapers ───────────────────────────────────────────
    log_step "  MacTahoe Wallpapers"
    cd wallpaper && sudo ./install-gnome-backgrounds.sh
    cd "${build_dir}"

    log_ok "MacTahoe Theme đã cài xong!"

    # ── Thông báo đường dẫn ─────────────────────────────────
    echo ""
    echo -e "  ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
    echo -e "  ${WHITE}${BOLD}📁 Thư mục AIO-MacTahoe-Themes đã được tạo:${RESET}"
    echo ""
    echo -e "     ${CYAN}${BOLD}${MACTAHOE_DIR}${RESET}"
    echo ""
    echo -e "  ${GRAY}  Trong thư mục có 2 file:${RESET}"
    echo ""
    echo -e "     ${GREEN}SCRIPTS.sh${RESET}    ${GRAY}→ Script cài lại theme bất cứ lúc nào${RESET}"
    echo -e "     ${GREEN}EXTENSION.txt${RESET} ${GRAY}→ Danh sách GNOME Extensions cần cài kèm link${RESET}"
    echo ""
    echo -e "  ${YELLOW}${BOLD}Bước tiếp theo:${RESET}"
    echo -e "  ${GRAY}  1. Vào thư mục trên để xem danh sách extensions:"
    echo -e "       cd ${MACTAHOE_DIR}"
    echo -e "       cat EXTENSION.txt"
    echo ""
    echo -e "     2. Cài từng extension qua Extension Manager hoặc extensions.gnome.org"
    echo ""
    echo -e "     3. Mở GNOME Tweaks → Appearance → áp dụng:"
    echo -e "          Shell Theme  : macTahoe"
    echo -e "          Icons        : MacTahoe"
    echo -e "          Legacy Apps  : macTahoe${RESET}"
    echo ""
    echo -e "  ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

# ════════════════════════════════════════════════════════════
#  GNOME DETECT + MỞ ẢNH DEMO QUA LOUPE (Fedora 41+ default)
# ════════════════════════════════════════════════════════════

find_demo_image() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # Cấu trúc repo chính thức: demo/MacTahoe-Theme-Demo.png
    local primary="${script_dir}/demo/MacTahoe-Theme-Demo.png"
    [[ -f "$primary" ]] && echo "$primary" && return 0

    # Fallback: hỗ trợ thêm đuôi khác trong demo/
    local base="${script_dir}/demo/MacTahoe-Theme-Demo"
    for ext in jpg jpeg webp; do
        [[ -f "${base}.${ext}" ]] && echo "${base}.${ext}" && return 0
    done

    return 1
}

# Chỉ dùng Loupe — image viewer mặc định của GNOME / Fedora 41+
# Package: loupe  |  Binary: loupe
open_with_loupe() {
    local img="$1"

    # Cần có GUI session (Wayland hoặc X11)
    if [[ -z "$DISPLAY" && -z "$WAYLAND_DISPLAY" ]]; then
        return 1
    fi

    # Loupe đã có sẵn trên Fedora 41 Workstation
    if command -v loupe &>/dev/null; then
        loupe "$img" &>/dev/null &
        disown
        return 0
    fi

    # Trường hợp loupe bị gỡ/chưa cài — cài lại qua DNF5
    log_warn "Loupe chưa có, đang cài (dnf5 install loupe)..."
    if sudo $DNF install $DNF_OPTS loupe &>/dev/null; then
        loupe "$img" &>/dev/null &
        disown
        return 0
    fi

    return 1
}

detect_gnome() {
    # 1. Biến môi trường — nhanh nhất, đáng tin cậy nhất
    if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]] || \
       [[ "$DESKTOP_SESSION"      == *"gnome"* ]] || \
       [[ "$GDMSESSION"           == *"gnome"* ]]; then
        return 0
    fi
    # 2. gnome-shell process đang chạy
    if pgrep -x gnome-shell &>/dev/null; then
        return 0
    fi
    # 3. gsettings phản hồi schema GNOME (Fedora 41 dùng color-scheme)
    if command -v gsettings &>/dev/null; then
        if gsettings get org.gnome.desktop.interface color-scheme &>/dev/null; then
            return 0
        fi
    fi
    return 1
}

prompt_mactahoe_gnome() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    echo ""
    log_div
    echo ""
    echo -e "  ${CYAN}${BOLD}🍎 Phát hiện bạn đang dùng GNOME!${RESET}"
    echo ""
    echo -e "  Script có thể cài giao diện ${WHITE}${BOLD}macOS Tahoe${RESET} cho GNOME của bạn,"
    echo -e "  bao gồm: GTK4/3 Theme, Icon Theme, và Wallpapers."
    echo ""

    # ── Mở ảnh demo qua Loupe ───────────────────────────────
    local demo_img
    if demo_img=$(find_demo_image); then
        echo -e "  ${GREEN}🖼  Đang mở ảnh demo bằng ${BOLD}Loupe${RESET}${GREEN} để bạn xem trước...${RESET}"
        echo -e "  ${GRAY}   File: ${WHITE}$(basename "$demo_img")${RESET}"
        echo ""

        if open_with_loupe "$demo_img"; then
            echo -e "  ${GRAY}   ✓ Ảnh đã mở trong Loupe.${RESET}"
            echo -e "  ${GRAY}     Xem xong rồi quay lại terminal này để chọn.${RESET}"
        else
            # Không mở được GUI (vd: chạy qua SSH không có display)
            echo -e "  ${YELLOW}   Không thể mở Loupe — có thể không có GUI session (SSH?).${RESET}"
            echo -e "  ${GRAY}   Xem ảnh demo tại: ${WHITE}${demo_img}${RESET}"
        fi
    else
        # File ảnh chưa có trong thư mục script
        echo -e "  ${YELLOW}  ℹ  Không tìm thấy ảnh demo trong thư mục script.${RESET}"
        echo ""
        echo -e "  ${GRAY}  Để xem trước giao diện, đặt ảnh demo vào cùng thư mục:${RESET}"
        echo -e "  ${GRAY}    Thư mục : ${WHITE}${script_dir}${RESET}"
        echo -e "  ${GRAY}    Tên file: ${WHITE}Mac_TaHoe_Theme_demo.png${RESET}"
        echo -e "  ${GRAY}              (hoặc .jpg / .jpeg / .webp)${RESET}"
    fi

    echo ""
    echo -e "  ${GRAY}─────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -ne "  ${BOLD}Bạn có muốn cài giao diện macOS Tahoe cho GNOME không? [y/N]: ${RESET}"
    read -r theme_ans
    echo ""

    if [[ "$theme_ans" =~ ^[Yy]$ ]]; then
        do_mactahoe
    else
        echo -e "  ${GRAY}Bỏ qua. Chạy lại script bất cứ lúc nào để cài theme.${RESET}"
    fi
}

# ════════════════════════════════════════════════════════════
#  MAIN
# ════════════════════════════════════════════════════════════
main() {
    show_banner

    # ── Không chạy bằng root ─────────────────────────────────
    if [[ $EUID -eq 0 ]]; then
        echo -e "  ${RED}✗ Đừng chạy script này bằng root!${RESET}"
        echo -e "  ${GRAY}  Dùng user thường — script sẽ tự gọi sudo khi cần.${RESET}"
        exit 1
    fi

    # ── Kiểm tra Fedora 41+ + DNF5 ──────────────────────────
    check_fedora_version
    echo ""

    # ════════════════════════════════════════════════════════
    #  MENU 1 — THIẾT LẬP CƠ BẢN
    # ════════════════════════════════════════════════════════
    local base_names=(
        "System Upgrade"
        "RPM Fusion"
        "Flathub"
    )
    local base_descs=(
        "dnf5 upgrade --refresh  — cập nhật toàn bộ hệ thống (khuyên dùng)"
        "Kích hoạt RPM Fusion Free + Nonfree (cần cho VLC, FFmpeg...)"
        "Thêm kho Flathub để cài app Flatpak"
    )
    local base_sel=("1" "1" "1")

    show_banner
    tput cup 8 0
    echo -e "  ${BOLD}${MAGENTA}BƯỚC 1/2 — Thiết lập cơ bản${RESET}\n"
    checkbox_menu "Chọn bước muốn thực hiện:" base_names base_descs base_sel

    # ════════════════════════════════════════════════════════
    #  MENU 2 — ỨNG DỤNG
    # ════════════════════════════════════════════════════════
    local app_names=(
        "Brave Browser"
        "Google Chrome"
        "VLC + FFmpeg"
        "Zoom"
        "Discord"
        "Blue Recorder"
        "GNOME Tweaks + Extension Manager"
        "Fcitx5 + Unikey  (Gõ tiếng Việt)"
        "Git + Fastfetch"
        "OnlyOffice Desktop Editors"
        "WPS Office"
    )
    local app_descs=(
        "Trình duyệt bảo mật, chặn quảng cáo — thêm repo Brave"
        "Trình duyệt Google Chrome ổn định — tải RPM từ Google"
        "Xem phim + encode video — cần RPM Fusion đã bật"
        "Họp online — tải RPM từ zoom.us"
        "Chat gaming — cài qua Flatpak (Flathub)"
        "Quay màn hình đơn giản — cài qua Flatpak (Flathub)"
        "Tinh chỉnh GNOME + quản lý extensions — Flatpak Extension Manager"
        "Bộ gõ tiếng Việt Unikey, hỗ trợ GTK4/Qt/Wayland/X11"
        "Quản lý source code + hiển thị thông tin hệ thống"
        "Bộ Office miễn phí, tương thích .docx/.xlsx/.pptx — Flatpak (Flathub)"
        "Bộ Office nhẹ, giao diện quen thuộc, tương thích MS Office — Flatpak (Flathub)"
    )
    local app_sel=("0" "0" "0" "0" "0" "0" "0" "0" "1" "0" "0")

    show_banner
    tput cup 8 0
    echo -e "  ${BOLD}${MAGENTA}BƯỚC 2/2 — Ứng dụng${RESET}\n"
    checkbox_menu "Chọn ứng dụng muốn cài:" app_names app_descs app_sel

    # ════════════════════════════════════════════════════════
    #  XÁC NHẬN TRƯỚC KHI CÀI
    # ════════════════════════════════════════════════════════
    show_banner
    echo -e "  ${BOLD}${WHITE}Xác nhận danh sách cài đặt:${RESET}\n"

    local any=0
    [[ "${base_sel[0]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} System Upgrade"              && any=1
    [[ "${base_sel[1]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} RPM Fusion"                  && any=1
    [[ "${base_sel[2]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} Flathub"                     && any=1
    [[ "${app_sel[0]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Brave Browser"               && any=1
    [[ "${app_sel[1]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Google Chrome"               && any=1
    [[ "${app_sel[2]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} VLC + FFmpeg"                && any=1
    [[ "${app_sel[3]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Zoom"                        && any=1
    [[ "${app_sel[4]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Discord (Flatpak)"           && any=1
    [[ "${app_sel[5]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Blue Recorder (Flatpak)"     && any=1
    [[ "${app_sel[6]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} GNOME Tweaks + Extensions"   && any=1
    [[ "${app_sel[7]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Fcitx5 + Unikey"             && any=1
    [[ "${app_sel[8]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Git + Fastfetch"             && any=1
    [[ "${app_sel[9]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} OnlyOffice Desktop Editors (Flatpak)" && any=1
    [[ "${app_sel[10]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} WPS Office (Flatpak)"                 && any=1

    echo ""
    echo -e "  ${DIM}${GRAY}(Giao diện macOS Tahoe sẽ được đề xuất sau nếu máy đang dùng GNOME)${RESET}"
    echo ""

    if [[ $any -eq 0 ]]; then
        echo -e "  ${YELLOW}⚠ Bạn chưa chọn gì cả. Thoát.${RESET}\n"
        exit 0
    fi

    echo -ne "  ${BOLD}Bắt đầu cài đặt? [Y/n]: ${RESET}"
    read -r confirm
    [[ "$confirm" =~ ^[Nn]$ ]] && echo -e "\n  ${GRAY}Đã huỷ.${RESET}\n" && exit 0

    # ════════════════════════════════════════════════════════
    #  THỰC HIỆN CÀI ĐẶT
    # ════════════════════════════════════════════════════════
    echo ""
    log_div

    set -e

    [[ "${base_sel[0]}" == "1" ]] && do_system_update
    [[ "${base_sel[1]}" == "1" ]] && do_rpm_fusion
    [[ "${base_sel[2]}" == "1" ]] && do_flathub

    [[ "${app_sel[0]}"  == "1" ]] && do_brave
    [[ "${app_sel[1]}"  == "1" ]] && do_chrome
    [[ "${app_sel[2]}"  == "1" ]] && do_vlc_ffmpeg
    [[ "${app_sel[3]}"  == "1" ]] && do_zoom
    [[ "${app_sel[4]}"  == "1" ]] && do_discord
    [[ "${app_sel[5]}"  == "1" ]] && do_bluerecorder
    [[ "${app_sel[6]}"  == "1" ]] && do_gnome_tools
    [[ "${app_sel[7]}"  == "1" ]] && do_fcitx5
    [[ "${app_sel[8]}"  == "1" ]] && do_dev_tools
    [[ "${app_sel[9]}"  == "1" ]] && do_onlyoffice
    [[ "${app_sel[10]}" == "1" ]] && do_wps

    # Cập nhật lần cuối
    log_step "Cập nhật lần cuối"
    sudo $DNF upgrade --refresh $DNF_OPTS
    log_ok "Hoàn tất"

    echo ""
    log_div
    echo -e "  ${GREEN}${BOLD}🎉 Fedora đã được setup xong! Chúc bạn vọc vui vẻ 🇻🇳${RESET}"

    # ════════════════════════════════════════════════════════
    #  AUTO-DETECT GNOME → ĐỀ XUẤT MACTAHOE
    # ════════════════════════════════════════════════════════
    set +e
    if detect_gnome; then
        prompt_mactahoe_gnome
    else
        echo ""
        echo -e "  ${GRAY}  (Không phát hiện GNOME — bỏ qua đề xuất MacTahoe Theme)${RESET}"
    fi
    set -e

    # ════════════════════════════════════════════════════════
    #  REBOOT
    # ════════════════════════════════════════════════════════
    echo ""
    log_div
    echo ""
    echo -ne "  ${BOLD}Reboot ngay bây giờ? [y/N]: ${RESET}"
    read -r reboot_choice
    if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
        echo -e "  ${CYAN}Đang reboot...${RESET}\n"
        sudo systemctl reboot
    else
        echo -e "  ${GRAY}Nhớ reboot sau để áp dụng toàn bộ thay đổi nhé!${RESET}\n"
    fi
}

main "$@"
