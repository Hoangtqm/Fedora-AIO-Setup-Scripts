#!/usr/bin/env bash
# ============================================================
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

hide_cursor() { printf '\033[?25l'; }
show_cursor() { printf '\033[?25h'; }
cleanup()     { show_cursor; tput cnorm; echo ""; }
trap cleanup EXIT INT TERM

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="${SCRIPT_DIR}/Mac-Theme-Install"
DNF="dnf5"
DNF_OPTS="-y --assumeyes"

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
    echo -e "  ${WHITE}${BOLD}AIO Fedora Setup Script${RESET}  ${GRAY}Fedora 41+ | DNF5${RESET}"
    echo -e "  ${GRAY}${RESET}"
    echo -e "  ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
}

# ════════════════════════════════════════════════════════════
#  CHECKBOX MENU —
#  Phím: ↑/↓  j/k  di chuyển
#        SPACE      toggle
#        A          chọn tất cả (trừ disabled)
#        N          bỏ hết
#        ENTER      xác nhận
# ════════════════════════════════════════════════════════════
checkbox_menu() {
    local title="$1"
    local -n _names=$2
    local -n _descs=$3
    local -n _sel=$4
    local -n _dis=$5

    local count=${#_names[@]}
    local cursor=0
    local key

    hide_cursor

    while true; do
        tput cup 7 0

        echo -e "  ${BOLD}${WHITE}${title}${RESET}"
        echo -e "  ${GRAY}[SPACE] Toggle  [A] Tất cả  [N] Bỏ hết  [ENTER] Xác nhận  [↑↓/jk] Di chuyển${RESET}"
        echo ""

        local sel_count=0
        for i in "${!_names[@]}"; do
            [[ "${_sel[$i]}" == "1" ]] && (( sel_count++ ))
        done

        for i in "${!_names[@]}"; do
            local box line_color sep

            if [[ "${_dis[$i]}" == "1" ]]; then
                box="${GRAY}[✗]${RESET}"
                line_color="${GRAY}${DIM}"
                sep="${GRAY}${DIM}"
            elif [[ "${_sel[$i]}" == "1" ]]; then
                box="${GREEN}[✓]${RESET}"
                line_color="${GREEN}"
                sep="${GRAY}${DIM}"
            else
                box="${GRAY}[ ]${RESET}"
                line_color="${GRAY}"
                sep="${GRAY}${DIM}"
            fi

            if [[ $i -eq $cursor ]]; then
                printf '\033[2K'
                echo -e "  ${BG_BLUE}${WHITE}  ❯ ${_names[$i]}  —  ${_descs[$i]}${RESET}   "
            else
                printf '\033[2K'
                echo -e "    ${box} ${line_color}${_names[$i]}${RESET}  ${sep}—  ${_descs[$i]}${RESET}   "
            fi
        done

        echo ""
        printf '\033[2K'
        echo -e "  ${GRAY}Đã chọn: ${WHITE}${BOLD}${sel_count}/${count}${RESET}${GRAY} mục${RESET}   "
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
                    if [[ "${_dis[$cursor]}" != "1" ]]; then
                        [[ "${_sel[$cursor]}" == "1" ]] \
                            && _sel[$cursor]="0" \
                            || _sel[$cursor]="1"
                    fi ;;
                'a'|'A') for i in "${!_names[@]}"; do
                    [[ "${_dis[$i]}" != "1" ]] && _sel[$i]="1"; done ;;
                'n'|'N') for i in "${!_names[@]}"; do
                    [[ "${_dis[$i]}" != "1" ]] && _sel[$i]="0"; done ;;
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
log_div()  { echo -e "  ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"; }

# ════════════════════════════════════════════════════════════
#  CHECKS
# ════════════════════════════════════════════════════════════
check_fedora_version() {
    if ! grep -q "Fedora" /etc/os-release 2>/dev/null; then
        echo -e "  ${RED}✗ Không phát hiện Fedora Linux.${RESET}"; exit 1
    fi
    local ver; ver=$(rpm -E %fedora 2>/dev/null)
    if [[ -z "$ver" || "$ver" -lt 41 ]]; then
        echo -e "  ${RED}✗ Fedora ${ver} không được hỗ trợ — cần Fedora 41+.${RESET}"; exit 1
    fi
    if ! command -v dnf5 &>/dev/null; then
        log_warn "dnf5 chưa có, đang cài..."
        sudo dnf install -y --assumeyes dnf5 dnf5-plugins || exit 1
    fi
    echo -e "  ${GREEN}✓ Fedora ${ver} — DNF5 sẵn sàng${RESET}"
}

check_dependencies() {
    log_step "Kiểm tra dependencies (wget, curl)"
    local missing=()
    command -v wget &>/dev/null || missing+=("wget")
    command -v curl &>/dev/null || missing+=("curl")
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_warn "Thiếu: ${missing[*]} — đang cài..."
        sudo $DNF upgrade --refresh $DNF_OPTS
        sudo $DNF install $DNF_OPTS "${missing[@]}"
        log_ok "Đã cài: ${missing[*]}"
    else
        log_ok "wget và curl đã có sẵn"
    fi
}

detect_desktop_env() {
    if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]] || \
       [[ "$DESKTOP_SESSION" == *"gnome"* ]]      || \
       [[ "$GDMSESSION"      == *"gnome"* ]]      || \
       pgrep -x gnome-shell &>/dev/null            || \
       { command -v gsettings &>/dev/null && \
         gsettings get org.gnome.desktop.interface color-scheme &>/dev/null; }; then
        echo "gnome"; return
    fi
    if [[ "$XDG_CURRENT_DESKTOP" == *"Hyprland"* ]] || \
       [[ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]]        || \
       pgrep -x Hyprland &>/dev/null; then
        echo "hyprland"; return
    fi
    if [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]] || pgrep -x plasmashell &>/dev/null; then
        echo "kde"; return
    fi
    [[ "$XDG_CURRENT_DESKTOP" == *"XFCE"* ]] && echo "xfce" && return
    echo "other"
}

# Auto-enable Flathub nếu chưa có
ensure_flathub() {
    if ! flatpak remotes 2>/dev/null | grep -q "flathub"; then
        log_warn "Flathub chưa được kích hoạt — đang bật tự động..."
        sudo flatpak remote-add --if-not-exists flathub \
            https://flathub.org/repo/flathub.flatpakrepo
        log_ok "Flathub đã kích hoạt"
    fi
}

# ════════════════════════════════════════════════════════════
#  MODULE: HỆ THỐNG & KHO
# ════════════════════════════════════════════════════════════
do_system_update() {
    log_step "Cập nhật hệ thống"
    sudo $DNF upgrade --refresh $DNF_OPTS
    log_ok "Hệ thống đã cập nhật"
}

do_rpm_fusion() {
    log_step "Kích hoạt RPM Fusion"
    local ver; ver=$(rpm -E %fedora)
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
    log_step "Cài Brave Browser"
    sudo $DNF config-manager addrepo \
        --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
    sudo $DNF install $DNF_OPTS brave-browser
    log_ok "Brave Browser đã cài xong"
}

do_chrome() {
    log_step "Cài Google Chrome"
    local tmp; tmp=$(mktemp -d)
    wget -q --show-progress -O "${tmp}/chrome.rpm" \
        https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
    sudo $DNF install $DNF_OPTS --allowerasing "${tmp}/chrome.rpm"
    rm -rf "${tmp}"
    log_ok "Google Chrome đã cài xong"
}

do_vlc_ffmpeg() {
    log_step "Cài VLC + FFmpeg"
    sudo $DNF install $DNF_OPTS --allowerasing vlc ffmpeg ffmpeg-libs
    log_ok "VLC + FFmpeg đã cài xong"
}

do_zoom() {
    log_step "Cài Zoom"
    local tmp; tmp=$(mktemp -d)
    wget -q --show-progress -O "${tmp}/zoom.rpm" \
        https://zoom.us/client/latest/zoom_x86_64.rpm
    sudo $DNF install $DNF_OPTS --allowerasing "${tmp}/zoom.rpm"
    rm -rf "${tmp}"
    log_ok "Zoom đã cài xong"
}

do_discord() {
    log_step "Cài Discord"
    ensure_flathub
    flatpak install --assumeyes --noninteractive flathub com.discordapp.Discord
    log_ok "Discord đã cài xong"
}

do_bluerecorder() {
    log_step "Cài Blue Recorder"
    ensure_flathub
    flatpak install --assumeyes --noninteractive flathub sa.sy.bluerecorder
    log_ok "Blue Recorder đã cài xong"
}

do_fcitx5() {
    log_step "Cài Fcitx5 + Unikey"
    sudo $DNF install $DNF_OPTS \
        fcitx5 fcitx5-autostart fcitx5-gtk fcitx5-gtk4 \
        fcitx5-qt fcitx5-configtool fcitx5-unikey

    mkdir -p "${HOME}/.config/environment.d"
    cat > "${HOME}/.config/environment.d/fcitx5.conf" << 'EOF'
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
INPUT_METHOD=fcitx
EOF

    mkdir -p "${HOME}/.config/autostart"
    local src="/usr/share/applications/org.fcitx.Fcitx5.desktop"
    [[ -f "$src" ]] && cp "$src" "${HOME}/.config/autostart/" \
        && log_ok "Autostart: ~/.config/autostart/org.fcitx.Fcitx5.desktop"

    log_ok "Fcitx5 + Unikey đã cài xong"
    log_warn "Đăng xuất rồi đăng nhập lại để Fcitx5 tự khởi động"
}

do_dev_tools() {
    log_step "Cài Git + Fastfetch"
    sudo $DNF install $DNF_OPTS git fastfetch
    log_ok "Git + Fastfetch đã cài xong"
}

do_onlyoffice() {
    log_step "Cài OnlyOffice Desktop Editors"
    ensure_flathub
    flatpak install --assumeyes --noninteractive flathub org.onlyoffice.desktopeditors
    log_ok "OnlyOffice đã cài xong"
}

do_wps() {
    log_step "Cài WPS Office"
    ensure_flathub
    flatpak install --assumeyes --noninteractive flathub com.wps.Office
    log_ok "WPS Office đã cài xong"
}

do_tlauncher() {
    log_step "Cài TLauncher Minecraft"
    echo -e "  ${YELLOW}⚠ TLauncher yêu cầu đúng Java 17 — Java 18+ sẽ bị lỗi!${RESET}"

    sudo $DNF install $DNF_OPTS curl zip unzip

    if [[ ! -f "${HOME}/.sdkman/bin/sdkman-init.sh" ]]; then
        log_step "  Cài SDKMAN"
        curl -s "https://get.sdkman.io" | bash
    else
        log_ok "SDKMAN đã có sẵn"
    fi

    export SDKMAN_DIR="${HOME}/.sdkman"
    # shellcheck source=/dev/null
    source "${HOME}/.sdkman/bin/sdkman-init.sh"

    local JAVA_VER="17.0.12-tem"
    log_step "  Cài Java ${JAVA_VER} (bắt buộc)"
    if ! sdk list java 2>/dev/null | grep -q "${JAVA_VER}.*installed"; then
        sdk install java "${JAVA_VER}" </dev/null
    else
        log_ok "Java ${JAVA_VER} đã có sẵn"
    fi
    sdk default java "${JAVA_VER}" </dev/null

    # Kiểm tra version thực tế
    local active_ver major_ver
    active_ver=$(java -version 2>&1 | grep -oP '(?<=version ")[^"]+')
    major_ver=$(echo "$active_ver" | cut -d'.' -f1)
    if   [[ "$major_ver" -gt 17 ]]; then
        log_warn "Java hiện tại ${active_ver} > 17 — TLauncher có thể lỗi!"
    elif [[ "$major_ver" -lt 17 ]]; then
        log_warn "Java hiện tại ${active_ver} < 17"
    else
        log_ok "Java ${active_ver} — đúng phiên bản ✓"
    fi

    log_step "  Tải TLauncher.jar"
    mkdir -p "${HOME}/TLauncher.v17"
    local jar="${HOME}/TLauncher.v17/TLauncher.jar"
    if [[ ! -f "$jar" ]]; then
        wget -q --show-progress \
            "https://drive.google.com/uc?export=download&id=1BvI0WmzZbzOjp4b3VPp9KsnRCjZhXVJb" \
            -O "$jar"
        log_ok "Đã tải: ${jar}"
    else
        log_ok "TLauncher.jar đã có sẵn"
    fi

    # Wrapper script — đảm bảo LUÔN chạy Java 17 dù default SDKMAN thay đổi
    local wrapper="${HOME}/TLauncher.v17/tlauncher.sh"
    cat > "$wrapper" << 'WRAPEOF'
#!/usr/bin/env bash
export SDKMAN_DIR="$HOME/.sdkman"
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk use java 17.0.12-tem > /dev/null 2>&1
exec java -jar "$HOME/TLauncher.v17/TLauncher.jar" "$@"
WRAPEOF
    chmod +x "$wrapper"

    mkdir -p "${HOME}/.local/share/applications"
    cat > "${HOME}/.local/share/applications/tlauncher.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=TLauncher
Comment=Minecraft Launcher — Java 17.0.12 Temurin
Exec=${HOME}/TLauncher.v17/tlauncher.sh
Icon=minecraft
Terminal=false
Categories=Game;
StartupNotify=true
EOF
    chmod +x "${HOME}/.local/share/applications/tlauncher.desktop"
    update-desktop-database "${HOME}/.local/share/applications" 2>/dev/null || true

    log_ok "TLauncher đã cài xong!"
    log_warn "Chỉ dùng Java 17 — wrapper script tự đảm bảo điều này"
}

do_hyprland_jakoolit() {
    log_step "Cài Fedora Hyprland — JaKooLit"
    log_warn "Installer sẽ chạy interactive — làm theo hướng dẫn trên màn hình"
    local hypr_dir="${HOME}/Fedora-Hyprland"
    if [[ -d "$hypr_dir" ]]; then
        git -C "$hypr_dir" pull --ff-only
    else
        git clone --depth=1 https://github.com/JaKooLit/Fedora-Hyprland.git "$hypr_dir"
    fi
    cd "$hypr_dir" && chmod +x install.sh && ./install.sh
    cd "${SCRIPT_DIR}"
    log_ok "Hyprland JaKooLit đã hoàn tất"
}

do_hyprland_ml4w_stable() {
    log_step "Cài Fedora Hyprland — ML4W Stable"
    log_warn "Installer sẽ chạy — làm theo hướng dẫn trên màn hình"
    bash <(curl -s https://ml4w.com/os/stable)
    log_ok "ML4W Stable đã hoàn tất"
}

do_hyprland_ml4w_rolling() {
    log_step "Cài Fedora Hyprland — ML4W Rolling"
    log_warn "Phiên bản Rolling có thể không ổn định"
    bash <(curl -s https://ml4w.com/os/rolling)
    log_ok "ML4W Rolling đã hoàn tất"
}

# ════════════════════════════════════════════════════════════
#  MODULE: MACTAHOE THEME
# ════════════════════════════════════════════════════════════
open_demo_images() {
    [[ -z "$DISPLAY$WAYLAND_DISPLAY" ]] && return 1
    command -v loupe &>/dev/null || sudo $DNF install $DNF_OPTS loupe &>/dev/null
    local opened=0
    for i in 1 2 3 4; do
        for ext in png jpg jpeg webp; do
            local f="${THEME_DIR}/demo${i}.${ext}"
            if [[ -f "$f" ]]; then
                loupe "$f" &>/dev/null & disown
                (( opened++ )); break
            fi
        done
    done
    [[ $opened -gt 0 ]]
}

open_guide() {
    local docx="${THEME_DIR}/Setup-Mac-themes.docx"
    local url="https://docs.google.com/document/d/18JCycVsugTkMA7JXGYiuwgSTse80--oI/edit?usp=sharing&ouid=113234984388764662222&rtpof=true&sd=true"
    [[ -z "$DISPLAY$WAYLAND_DISPLAY" ]] && \
        echo -e "  ${GRAY}Link hướng dẫn: ${WHITE}${url}${RESET}" && return

    if [[ -f "$docx" ]]; then
        echo -e "  ${CYAN}📄 Mở hướng dẫn offline (LibreOffice Writer)...${RESET}"
        libreoffice --writer "$docx" &>/dev/null & disown
        log_ok "Đã mở: Setup-Mac-themes.docx"
    else
        log_warn "Không tìm thấy ${docx}"
    fi

    local browser=""
    for b in xdg-open google-chrome brave-browser firefox chromium; do
        command -v "$b" &>/dev/null && browser="$b" && break
    done
    if [[ -n "$browser" ]]; then
        echo -e "  ${CYAN}🌐 Mở hướng dẫn online (Google Docs)...${RESET}"
        "$browser" "$url" &>/dev/null & disown
        log_ok "Đã mở link hướng dẫn online"
    else
        echo -e "  ${GRAY}Link hướng dẫn: ${WHITE}${url}${RESET}"
    fi
}

create_mactahoe_scripts() {
    local mac_dir="${HOME}/AIO-MacTahoe-Themes"
    mkdir -p "${mac_dir}"
    cat > "${mac_dir}/SCRIPTS.sh" << 'SCRIPTEOF'
#!/usr/bin/env bash
# MacTahoe Theme Installer — Standalone (Fedora 41+)
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; WHITE='\033[1;37m'; GRAY='\033[0;90m'
BOLD='\033[1m'; RESET='\033[0m'; DNF="dnf5"

clear
echo -e "${CYAN}"
echo "  ███╗   ███╗ █████╗  ██████╗████████╗ █████╗ ██╗  ██╗ ██████╗ ███████╗"
echo "  ████╗ ████║██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██║  ██║██╔═══██╗██╔════╝"
echo "  ██╔████╔██║███████║██║        ██║   ███████║███████║██║   ██║█████╗  "
echo "  ██║╚██╔╝██║██╔══██║██║        ██║   ██╔══██║██╔══██║██║   ██║██╔══╝  "
echo "  ██║ ╚═╝ ██║██║  ██║╚██████╗   ██║   ██║  ██║██║  ██║╚██████╔╝███████╗"
echo "  ╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝"
echo -e "${RESET}"
set -e
log_step() { echo -e "\n  ${CYAN}${BOLD}▶ ${1}${RESET}"; }
log_ok()   { echo -e "  ${GREEN}✓ ${1}${RESET}"; }

log_step "Cài dependencies"
sudo $DNF install -y --assumeyes \
    gcc make cmake curl perl wget sassc wmctrl gnome-tweaks gtk4-devel libadwaita-devel

BUILD="${HOME}/.local/share/aio-mactahoe-build"
mkdir -p "$BUILD"; cd "$BUILD"

log_step "Icon Theme"
[[ -d MacTahoe-icon-theme ]] && git -C MacTahoe-icon-theme pull --ff-only \
    || git clone --depth=1 https://github.com/vinceliuice/MacTahoe-icon-theme.git
cd MacTahoe-icon-theme && ./install.sh -b && cd "$BUILD"

log_step "GTK Theme"
[[ -d MacTahoe-gtk-theme ]] && git -C MacTahoe-gtk-theme pull --ff-only \
    || git clone --depth=1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git
cd MacTahoe-gtk-theme
./install.sh -n macTahoe -t all -l --shell -i simple -h bigger --round
sudo ./tweaks.sh -g -nd
sudo flatpak override --filesystem=xdg-config/gtk-3.0
sudo flatpak override --filesystem=xdg-config/gtk-4.0

log_step "Wallpapers"
cd wallpaper && sudo ./install-gnome-backgrounds.sh && cd "$BUILD"

log_ok "MacTahoe Theme đã cài xong!"
read -rp "  Reboot ngay? [y/N]: " rb
[[ "$rb" =~ ^[Yy]$ ]] && sudo systemctl reboot || echo -e "  ${GRAY}Nhớ reboot sau!${RESET}"
SCRIPTEOF
    chmod +x "${mac_dir}/SCRIPTS.sh"
    log_ok "Đã tạo: ${mac_dir}/SCRIPTS.sh"
}

do_mactahoe() {
    create_mactahoe_scripts

    # Kiểm tra LibreOffice Writer
    if ! command -v libreoffice &>/dev/null; then
        log_warn "LibreOffice chưa có — đang cài để mở file hướng dẫn..."
        sudo $DNF install $DNF_OPTS libreoffice-writer
        log_ok "LibreOffice Writer đã cài xong"
    fi

    log_step "Cài MacTahoe Theme"
    sudo $DNF install $DNF_OPTS \
        gcc make cmake curl perl wget sassc wmctrl gnome-tweaks gtk4-devel libadwaita-devel

    local BUILD="${HOME}/.local/share/aio-mactahoe-build"
    mkdir -p "$BUILD"; cd "$BUILD"

    log_step "  Icon Theme"
    [[ -d MacTahoe-icon-theme ]] && git -C MacTahoe-icon-theme pull --ff-only \
        || git clone --depth=1 https://github.com/vinceliuice/MacTahoe-icon-theme.git
    cd MacTahoe-icon-theme && ./install.sh -b && cd "$BUILD"

    log_step "  GTK Theme"
    [[ -d MacTahoe-gtk-theme ]] && git -C MacTahoe-gtk-theme pull --ff-only \
        || git clone --depth=1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git
    cd MacTahoe-gtk-theme
    ./install.sh -n macTahoe -t all -l --shell -i simple -h bigger --round
    sudo ./tweaks.sh -g -nd
    sudo flatpak override --filesystem=xdg-config/gtk-3.0
    sudo flatpak override --filesystem=xdg-config/gtk-4.0

    log_step "  Wallpapers"
    cd wallpaper && sudo ./install-gnome-backgrounds.sh && cd "$BUILD"

    log_ok "MacTahoe Theme đã cài xong!"
    echo ""
    log_div
    echo -e "  ${WHITE}${BOLD}📁 ~/AIO-MacTahoe-Themes/SCRIPTS.sh${RESET}"
    echo -e "  ${GRAY}     Chạy lại để cài theme bất cứ lúc nào${RESET}"
    echo ""
    echo -e "  ${YELLOW}${BOLD}Bước tiếp theo:${RESET}"
    echo -e "  ${GRAY}  GNOME Tweaks → Appearance → Shell: macTahoe | Icons: MacTahoe${RESET}"
    log_div
    echo ""
    open_guide
}

prompt_mactahoe_gnome() {
    echo ""
    log_div
    echo -e "  ${CYAN}${BOLD}🍎 Phát hiện GNOME — Bạn có muốn cài giao diện macOS Tahoe không?${RESET}"
    echo ""

    if [[ -d "$THEME_DIR" ]]; then
        echo -e "  ${GREEN}🖼  Đang mở ảnh demo (demo1~4) bằng Loupe...${RESET}"
        if open_demo_images; then
            echo -e "  ${GRAY}  Xem xong quay lại terminal để chọn.${RESET}"
        else
            echo -e "  ${YELLOW}  Không mở được Loupe. Xem tại: ${WHITE}${THEME_DIR}${RESET}"
        fi
    else
        echo -e "  ${YELLOW}  Không tìm thấy thư mục Mac-Theme-Install.${RESET}"
        echo -e "  ${GRAY}  Cần có: ${WHITE}${THEME_DIR}${RESET}"
    fi

    echo ""
    log_div
    echo ""
    echo -ne "  ${BOLD}Cài giao diện macOS Tahoe? [y/N]: ${RESET}"
    read -r ans
    [[ "$ans" =~ ^[Yy]$ ]] && do_mactahoe \
        || echo -e "  ${GRAY}Bỏ qua. Chạy lại script bất cứ lúc nào để cài.${RESET}"
}

# ════════════════════════════════════════════════════════════
#  MAIN
# ════════════════════════════════════════════════════════════
main() {
    show_banner

    [[ $EUID -eq 0 ]] && \
        echo -e "  ${RED}✗ Đừng chạy bằng root! Dùng user thường.${RESET}" && exit 1

    check_fedora_version
    echo ""

    local CURRENT_DE
    CURRENT_DE=$(detect_desktop_env)
    echo -e "  ${CYAN}▶ Desktop Environment: ${WHITE}${BOLD}${CURRENT_DE}${RESET}"
    echo ""

    check_dependencies
    echo ""

    if [[ "$CURRENT_DE" != "gnome" ]]; then
        echo -e "  ${YELLOW}⚠ Không phát hiện GNOME (đang dùng: ${CURRENT_DE})${RESET}"
        echo ""
    fi

    # ════════════════════════════════════════════════════════
    #  BƯỚC 1 — THIẾT LẬP CƠ BẢN
    # ════════════════════════════════════════════════════════
    local base_names=("System Upgrade" "RPM Fusion" "Flathub")
    local base_descs=(
        "dnf5 upgrade --refresh — cập nhật toàn bộ hệ thống"
        "Kích hoạt RPM Fusion Free + Nonfree (cần cho VLC, FFmpeg...)"
        "Thêm kho Flathub để cài app Flatpak"
    )
    local base_sel=("1" "1" "1")
    local base_dis=("0" "0" "0")

    show_banner
    tput cup 7 0
    echo -e "  ${BOLD}${MAGENTA}BƯỚC 1/4 — Thiết lập cơ bản${RESET}"
    echo ""
    checkbox_menu "Chọn:" base_names base_descs base_sel base_dis

    # ════════════════════════════════════════════════════════
    #  BƯỚC 2 — ỨNG DỤNG (1 trang, 1 dòng mỗi item)
    # ════════════════════════════════════════════════════════
    local app_names=(
        "Brave Browser"
        "Google Chrome"
        "VLC + FFmpeg"
        "Zoom"
        "Discord"
        "Blue Recorder"
        "Fcitx5 + Unikey"
        "Git + Fastfetch"
        "OnlyOffice"
        "WPS Office"
        "TLauncher Minecraft"
        "Fedora Hyprland — JaKooLit"
        "Fedora Hyprland — ML4W Stable"
        "Fedora Hyprland — ML4W Rolling"
    )
    local app_descs=(
        "Trình duyệt bảo mật, chặn quảng cáo"
        "Trình duyệt Google Chrome ổn định"
        "Xem phim + encode video (cần RPM Fusion)"
        "Họp online — tải RPM từ zoom.us"
        "Chat gaming — Flatpak (tự enable Flathub)"
        "Quay màn hình đơn giản — Flatpak (tự enable Flathub)"
        "Bộ gõ Unikey, hỗ trợ GTK4/Qt/Wayland/X11"
        "Quản lý source code + hiển thị thông tin hệ thống"
        "Bộ Office miễn phí .docx/.xlsx/.pptx — Flatpak (tự enable Flathub)"
        "Bộ Office nhẹ tương thích MS Office — Flatpak (tự enable Flathub)"
        "SDKMAN + Java 17.0.12 Temurin (bắt buộc) + TLauncher.jar"
        "git clone JaKooLit/Fedora-Hyprland rồi chạy install.sh"
        "bash <(curl -s https://ml4w.com/os/stable)"
        "bash <(curl -s https://ml4w.com/os/rolling) — có thể không ổn định"
    )
    local app_sel=("0" "0" "0" "0" "0" "0" "0" "1" "0" "0" "0" "0" "0" "0")
    local app_dis=("0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0")

    show_banner
    tput cup 7 0
    echo -e "  ${BOLD}${MAGENTA}BƯỚC 2/4 — Chọn ứng dụng${RESET}"
    echo ""
    checkbox_menu "Chọn:" app_names app_descs app_sel app_dis

    # ════════════════════════════════════════════════════════
    #  BƯỚC 3 — XÁC NHẬN
    # ════════════════════════════════════════════════════════
    show_banner
    echo -e "  ${BOLD}${MAGENTA}BƯỚC 3/4 — Xác nhận${RESET}"
    echo ""
    echo -e "  ${BOLD}${WHITE}Danh sách sẽ cài:${RESET}"
    echo ""

    local any=0
    [[ "${base_sel[0]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} System Upgrade"                   && any=1
    [[ "${base_sel[1]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} RPM Fusion"                       && any=1
    [[ "${base_sel[2]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} Flathub"                          && any=1
    [[ "${app_sel[0]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Brave Browser"                    && any=1
    [[ "${app_sel[1]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Google Chrome"                    && any=1
    [[ "${app_sel[2]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} VLC + FFmpeg"                     && any=1
    [[ "${app_sel[3]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Zoom"                             && any=1
    [[ "${app_sel[4]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Discord (Flatpak)"                && any=1
    [[ "${app_sel[5]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Blue Recorder (Flatpak)"          && any=1
    [[ "${app_sel[6]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Fcitx5 + Unikey"                  && any=1
    [[ "${app_sel[7]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Git + Fastfetch"                  && any=1
    [[ "${app_sel[8]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} OnlyOffice (Flatpak)"             && any=1
    [[ "${app_sel[9]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} WPS Office (Flatpak)"             && any=1
    [[ "${app_sel[10]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} TLauncher Minecraft (Java 17)"    && any=1
    [[ "${app_sel[11]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} Hyprland — JaKooLit"              && any=1
    [[ "${app_sel[12]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} Hyprland — ML4W Stable"           && any=1
    [[ "${app_sel[13]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} Hyprland — ML4W Rolling"          && any=1

    echo ""
    echo -e "  ${DIM}${GRAY}(Giao diện macOS Tahoe sẽ được hỏi sau nếu đang dùng GNOME)${RESET}"
    echo ""

    if [[ $any -eq 0 ]]; then
        echo -e "  ${YELLOW}⚠ Chưa chọn gì cả. Thoát.${RESET}"; exit 0
    fi

    echo -ne "  ${BOLD}Xác nhận bắt đầu cài? [Y/n]: ${RESET}"
    read -r confirm
    [[ "$confirm" =~ ^[Nn]$ ]] && echo -e "\n  ${GRAY}Đã huỷ.${RESET}\n" && exit 0

    # ════════════════════════════════════════════════════════
    #  BƯỚC 4 — CÀI ĐẶT
    # ════════════════════════════════════════════════════════
    echo ""
    echo -e "  ${BOLD}${MAGENTA}BƯỚC 4/4 — Đang cài đặt...${RESET}"
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
    [[ "${app_sel[6]}"  == "1" ]] && do_fcitx5
    [[ "${app_sel[7]}"  == "1" ]] && do_dev_tools
    [[ "${app_sel[8]}"  == "1" ]] && do_onlyoffice
    [[ "${app_sel[9]}"  == "1" ]] && do_wps
    [[ "${app_sel[10]}" == "1" ]] && do_tlauncher
    [[ "${app_sel[11]}" == "1" ]] && do_hyprland_jakoolit
    [[ "${app_sel[12]}" == "1" ]] && do_hyprland_ml4w_stable
    [[ "${app_sel[13]}" == "1" ]] && do_hyprland_ml4w_rolling

    log_step "Cập nhật lần cuối"
    sudo $DNF upgrade --refresh $DNF_OPTS
    log_ok "Hoàn tất"

    echo ""
    log_div
    echo -e "  ${GREEN}${BOLD}🎉 Setup xong!${RESET}"

    set +e
    [[ "$CURRENT_DE" == "gnome" ]] && prompt_mactahoe_gnome \
        || echo -e "  ${GRAY}  (Không phải GNOME — bỏ qua đề xuất MacTahoe)${RESET}"
    set -e

    echo ""
    log_div
    echo ""
    echo -ne "  ${BOLD}Reboot ngay? [y/N]: ${RESET}"
    read -r rb
    if [[ "$rb" =~ ^[Yy]$ ]]; then
        echo -e "  ${CYAN}Đang reboot...${RESET}"
        sudo systemctl reboot
    else
        echo -e "  ${GRAY}Nhớ reboot sau để áp dụng toàn bộ thay đổi!${RESET}\n"
    fi
}

main "$@"
