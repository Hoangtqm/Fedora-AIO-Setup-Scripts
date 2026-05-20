#!/usr/bin/env bash
# ============================================================
#  AIO Fedora Setup Script — Interactive Edition
#  Yêu cầu: Fedora 41+ | DNF5
#  Dành cho cộng đồng Linux Việt Nam 🇻🇳
#
#  Cấu trúc repo (GitHub):
#  Fedora-AIO-Setup-Scripts/
#  ├── scripts.sh              ← file này
#  ├── uninstall.sh
#  └── Mac-Theme-Install/
#      ├── demo1.png
#      ├── demo2.png
#      ├── demo3.png
#      ├── demo4.png
#      └── Setup-Mac-themes.docx
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
cleanup()     { show_cursor; tput cnorm; echo ""; }
trap cleanup EXIT INT TERM

# ── Script dir (dùng xuyên suốt) ────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="${SCRIPT_DIR}/Mac-Theme-Install"

# ── DNF5 wrapper ─────────────────────────────────────────────
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
    echo -e "  ${WHITE}${BOLD}AIO Fedora Setup Script${RESET}  ${GRAY}Interactive Edition — Fedora 41+${RESET}"
    echo -e "  ${GRAY}Dành cho cộng đồng Linux Việt Nam 🇻🇳${RESET}"
    echo ""
    echo -e "  ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
}

# ════════════════════════════════════════════════════════════
#  CHECKBOX MENU ENGINE
#  Phím: ↑/↓ j/k  di chuyển | SPACE toggle | A tất cả
#        N bỏ hết | ENTER xác nhận
# ════════════════════════════════════════════════════════════
checkbox_menu() {
    local title="$1"
    local -n _names=$2
    local -n _descs=$3
    local -n _sel=$4
    local -n _disabled=$5   # mảng "1" = disabled (không cho chọn)

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
            local box line_color sep_color

            if [[ "${_disabled[$i]}" == "1" ]]; then
                box="${GRAY}[✗]${RESET}"
                line_color="${GRAY}${DIM}"
                sep_color="${GRAY}${DIM}"
            elif [[ "${_sel[$i]}" == "1" ]]; then
                box="${GREEN}[✓]${RESET}"
                line_color="${GREEN}"
                sep_color="${GRAY}${DIM}"
            else
                box="${GRAY}[ ]${RESET}"
                line_color="${GRAY}"
                sep_color="${GRAY}${DIM}"
            fi

            if [[ $i -eq $cursor ]]; then
                printf '\033[2K'
                echo -e "  ${BG_BLUE}${WHITE}  ❯ ${_names[$i]}  —  ${_descs[$i]}${RESET}   "
            else
                echo -e "    ${box} ${line_color}${_names[$i]}${RESET}  ${sep_color}—  ${_descs[$i]}${RESET}   "
            fi
        done

        echo ""
        echo -e "  ${GRAY}Đã chọn: ${WHITE}${BOLD}${sel_count}/${count}${RESET} ${GRAY}mục${RESET}   "
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
                    # Không toggle nếu disabled
                    if [[ "${_disabled[$cursor]}" != "1" ]]; then
                        [[ "${_sel[$cursor]}" == "1" ]] \
                            && _sel[$cursor]="0" \
                            || _sel[$cursor]="1"
                    fi
                    ;;
                'a'|'A')
                    for i in "${!_names[@]}"; do
                        [[ "${_disabled[$i]}" != "1" ]] && _sel[$i]="1"
                    done ;;
                'n'|'N')
                    for i in "${!_names[@]}"; do
                        [[ "${_disabled[$i]}" != "1" ]] && _sel[$i]="0"
                    done ;;
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
#  KIỂM TRA DEPENDENCIES CƠ BẢN (wget, curl)
# ════════════════════════════════════════════════════════════
check_dependencies() {
    log_step "Kiểm tra dependencies cơ bản"
    local missing=()

    command -v wget &>/dev/null || missing+=("wget")
    command -v curl &>/dev/null || missing+=("curl")

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_warn "Thiếu: ${missing[*]} — refresh repo rồi cài..."
        sudo $DNF upgrade --refresh $DNF_OPTS
        sudo $DNF install $DNF_OPTS "${missing[@]}"
        log_ok "Đã cài: ${missing[*]}"
    else
        log_ok "wget và curl đã có sẵn"
    fi
}

# ════════════════════════════════════════════════════════════
#  DETECT DESKTOP ENVIRONMENT
# ════════════════════════════════════════════════════════════
detect_desktop_env() {
    # Trả về: gnome | hyprland | kde | xfce | other
    if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]] || \
       [[ "$DESKTOP_SESSION"      == *"gnome"* ]] || \
       [[ "$GDMSESSION"           == *"gnome"* ]] || \
       pgrep -x gnome-shell &>/dev/null || \
       { command -v gsettings &>/dev/null && \
         gsettings get org.gnome.desktop.interface color-scheme &>/dev/null; }; then
        echo "gnome"; return
    fi
    if [[ "$XDG_CURRENT_DESKTOP" == *"Hyprland"* ]] || \
       [[ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]] || \
       pgrep -x Hyprland &>/dev/null; then
        echo "hyprland"; return
    fi
    if [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]] || \
       pgrep -x plasmashell &>/dev/null; then
        echo "kde"; return
    fi
    if [[ "$XDG_CURRENT_DESKTOP" == *"XFCE"* ]]; then
        echo "xfce"; return
    fi
    echo "other"
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
    log_step "Cài đặt Brave Browser"
    sudo $DNF config-manager addrepo \
        --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
    sudo $DNF install $DNF_OPTS brave-browser
    log_ok "Brave Browser đã cài xong"
}

do_chrome() {
    log_step "Cài đặt Google Chrome"
    local tmp; tmp=$(mktemp -d)
    wget -q --show-progress -O "${tmp}/chrome.rpm" \
        https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
    sudo $DNF install $DNF_OPTS --allowerasing "${tmp}/chrome.rpm"
    rm -rf "${tmp}"
    log_ok "Google Chrome đã cài xong"
}

do_vlc_ffmpeg() {
    log_step "Cài đặt VLC + FFmpeg"
    # --allowerasing để swap ffmpeg-free (Fedora default) → ffmpeg đầy đủ (RPM Fusion)
    sudo $DNF install $DNF_OPTS --allowerasing vlc ffmpeg ffmpeg-libs
    log_ok "VLC + FFmpeg đã cài xong"
}

do_zoom() {
    log_step "Cài đặt Zoom"
    local tmp; tmp=$(mktemp -d)
    wget -q --show-progress -O "${tmp}/zoom.rpm" \
        https://zoom.us/client/latest/zoom_x86_64.rpm
    sudo $DNF install $DNF_OPTS --allowerasing "${tmp}/zoom.rpm"
    rm -rf "${tmp}"
    log_ok "Zoom đã cài xong"
}

do_discord() {
    log_step "Cài đặt Discord (Flatpak)"
    flatpak install --assumeyes --noninteractive flathub com.discordapp.Discord
    log_ok "Discord đã cài xong"
}

do_bluerecorder() {
    log_step "Cài đặt Blue Recorder (Flatpak)"
    flatpak install --assumeyes --noninteractive flathub sa.sy.bluerecorder
    log_ok "Blue Recorder đã cài xong"
}

do_gnome_tools() {
    log_step "Cài đặt GNOME Tweaks + Extension Manager"
    sudo $DNF install $DNF_OPTS gnome-tweaks gnome-extensions-app
    flatpak install --assumeyes --noninteractive flathub com.mattjakeman.ExtensionManager
    log_ok "GNOME Tweaks + Extension Manager đã cài xong"
}

do_gnome_extensions() {
    log_step "Cài đặt GNOME Extensions tự động (gext)"

    sudo $DNF install $DNF_OPTS pipx
    pipx ensurepath --force
    pipx install gnome-extensions-cli --system-site-packages --force

    local GEXT="${HOME}/.local/bin/gext"
    if [[ ! -f "$GEXT" ]]; then
        log_warn "Không cài được gext — bỏ qua"
        return 0
    fi

    log_ok "gext đã sẵn sàng"
    log_step "  Đang cài 9 GNOME Extensions cho MacTahoe..."

    local extensions=(
        "blur-my-shell@aunetx"
        "compiz-alike-magic-lamp-effect@hermes83.github.com"
        "compiz-windows-effect@hermes83.github.com"
        "CoverflowAltTab@palatis.blogspot.com"
        "dash2dock-lite@icedman.github.com"
        "desktop-cube@schneegans.github.com"
        "space-bar@luchrioh"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "Vitals@CoreCoding.com"
    )

    local ok=0 fail=0
    for uuid in "${extensions[@]}"; do
        local name="${uuid%%@*}"
        echo -ne "  ${GRAY}→ ${name}...${RESET}"
        if "$GEXT" install "$uuid" &>/dev/null; then
            echo -e "\r  ${GREEN}✓ ${name}${RESET}                         "
            (( ok++ ))
        else
            echo -e "\r  ${YELLOW}⚠ ${name} (lỗi — cài thủ công sau)${RESET}"
            (( fail++ ))
        fi
    done

    echo ""
    log_ok "Extensions: ${ok} thành công, ${fail} lỗi"
    [[ $fail -gt 0 ]] && log_warn "Cài thủ công tại extensions.gnome.org"
    log_warn "Đăng xuất rồi đăng nhập lại để extensions có hiệu lực"
}

do_fcitx5() {
    log_step "Cài đặt Fcitx5 + Unikey (gõ tiếng Việt)"
    sudo $DNF install $DNF_OPTS \
        fcitx5 fcitx5-autostart fcitx5-gtk fcitx5-gtk4 \
        fcitx5-qt fcitx5-configtool fcitx5-unikey

    # Biến môi trường
    mkdir -p "${HOME}/.config/environment.d"
    cat > "${HOME}/.config/environment.d/fcitx5.conf" << 'EOF'
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
INPUT_METHOD=fcitx
EOF
    log_ok "Biến môi trường đã cấu hình"

    # Autostart — copy file .desktop chính thức
    mkdir -p "${HOME}/.config/autostart"
    local desktop_src="/usr/share/applications/org.fcitx.Fcitx5.desktop"
    if [[ -f "$desktop_src" ]]; then
        cp "$desktop_src" "${HOME}/.config/autostart/"
        log_ok "Autostart: ~/.config/autostart/org.fcitx.Fcitx5.desktop"
    else
        log_warn "Không tìm thấy file .desktop gốc — bỏ qua autostart"
    fi

    log_ok "Fcitx5 + Unikey đã cài xong"
    log_warn "Đăng xuất rồi đăng nhập lại để Fcitx5 tự khởi động"
}

do_dev_tools() {
    log_step "Cài đặt Git + Fastfetch"
    sudo $DNF install $DNF_OPTS git fastfetch
    log_ok "Git + Fastfetch đã cài xong"
}

do_onlyoffice() {
    log_step "Cài đặt OnlyOffice Desktop Editors (Flatpak)"
    flatpak install --assumeyes --noninteractive flathub org.onlyoffice.desktopeditors
    log_ok "OnlyOffice đã cài xong"
}

do_wps() {
    log_step "Cài đặt WPS Office (Flatpak)"
    flatpak install --assumeyes --noninteractive flathub com.wps.Office
    log_ok "WPS Office đã cài xong"
}

# ════════════════════════════════════════════════════════════
#  MODULE: HYPRLAND
# ════════════════════════════════════════════════════════════
do_tlauncher() {
    log_step "Cài đặt TLauncher Minecraft"
    echo -e "  ${YELLOW}⚠ TLauncher yêu cầu đúng Java 17 — Java 18+ sẽ bị lỗi!${RESET}"
    echo -e "  ${GRAY}  Script sẽ cài Java 17.0.12 Temurin qua SDKMAN và pin cứng version này.${RESET}"
    echo ""

    # SDKMAN cần curl + zip + unzip
    sudo $DNF install $DNF_OPTS curl zip unzip

    # Cài SDKMAN nếu chưa có
    if [[ ! -f "${HOME}/.sdkman/bin/sdkman-init.sh" ]]; then
        log_step "  Cài SDKMAN"
        curl -s "https://get.sdkman.io" | bash
    else
        log_ok "SDKMAN đã có sẵn"
    fi

    # Load SDKMAN vào shell hiện tại
    export SDKMAN_DIR="${HOME}/.sdkman"
    # shellcheck source=/dev/null
    source "${HOME}/.sdkman/bin/sdkman-init.sh"

    # Cài Java 17.0.12 Temurin — bắt buộc, không dùng version khác
    local JAVA_VER="17.0.12-tem"
    log_step "  Cài Java ${JAVA_VER} (bắt buộc cho TLauncher)"

    if ! sdk list java 2>/dev/null | grep -q "${JAVA_VER}.*installed"; then
        sdk install java "${JAVA_VER}" </dev/null
    else
        log_ok "Java ${JAVA_VER} đã có sẵn"
    fi

    # Set mặc định toàn hệ thống SDKMAN = 17.0.12
    sdk default java "${JAVA_VER}" </dev/null

    # Kiểm tra version thực tế — cảnh báo nếu không phải 17
    local active_ver
    active_ver=$(java -version 2>&1 | grep -oP '(?<=version ")[^"]+')
    local major_ver
    major_ver=$(echo "$active_ver" | cut -d'.' -f1)

    if [[ "$major_ver" -gt 17 ]]; then
        log_warn "Java hiện tại là ${active_ver} (> 17) — TLauncher có thể bị lỗi!"
        log_warn "Kiểm tra lại: sdk use java ${JAVA_VER}"
    elif [[ "$major_ver" -lt 17 ]]; then
        log_warn "Java hiện tại là ${active_ver} (< 17) — có thể không đủ tính năng"
    else
        log_ok "Java ${active_ver} — đúng phiên bản yêu cầu ✓"
    fi

    # Tạo thư mục và tải TLauncher.jar
    log_step "  Tải TLauncher.jar"
    mkdir -p "${HOME}/TLauncher.v17"
    local jar="${HOME}/TLauncher.v17/TLauncher.jar"

    if [[ ! -f "$jar" ]]; then
        wget -q --show-progress \
            "https://drive.google.com/uc?export=download&id=1BvI0WmzZbzOjp4b3VPp9KsnRCjZhXVJb" \
            -O "$jar"
        log_ok "TLauncher.jar đã tải về: ${jar}"
    else
        log_ok "TLauncher.jar đã có sẵn, bỏ qua tải lại"
    fi

    # Tạo wrapper script — đảm bảo LUÔN dùng Java 17 bất kể default ngoài
    local wrapper="${HOME}/TLauncher.v17/tlauncher.sh"
    cat > "$wrapper" << 'WRAPEOF'
#!/usr/bin/env bash
# Wrapper đảm bảo TLauncher luôn chạy với Java 17.0.12 Temurin
export SDKMAN_DIR="$HOME/.sdkman"
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk use java 17.0.12-tem > /dev/null 2>&1
exec java -jar "$HOME/TLauncher.v17/TLauncher.jar" "$@"
WRAPEOF
    chmod +x "$wrapper"
    log_ok "Wrapper script: ${wrapper}"

    # Tạo .desktop entry — dùng wrapper thay vì gọi java trực tiếp
    # Wrapper đảm bảo Java 17 ngay cả khi user đổi default SDKMAN
    log_step "  Tạo shortcut ứng dụng"
    mkdir -p "${HOME}/.local/share/applications"
    cat > "${HOME}/.local/share/applications/tlauncher.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=TLauncher
Comment=Minecraft Launcher — Java 17.0.12 Temurin (bắt buộc)
Exec=${HOME}/TLauncher.v17/tlauncher.sh
Icon=minecraft
Terminal=false
Categories=Game;
StartupNotify=true
EOF
    chmod +x "${HOME}/.local/share/applications/tlauncher.desktop"
    update-desktop-database "${HOME}/.local/share/applications" 2>/dev/null || true

    log_ok "TLauncher đã cài xong!"
    echo ""
    echo -e "  ${WHITE}${BOLD}📌 Lưu ý quan trọng:${RESET}"
    echo -e "  ${YELLOW}  TLauncher chỉ hoạt động với Java 17 — KHÔNG dùng Java 18+${RESET}"
    echo -e "  ${GRAY}  Shortcut App Menu sẽ tự dùng đúng Java 17 qua wrapper script."
    echo -e ""
    echo -e "  Chạy thủ công:${RESET}"
    echo -e "  ${WHITE}    ~/TLauncher.v17/tlauncher.sh${RESET}"
    echo -e "  ${GRAY}  hoặc:${RESET}"
    echo -e "  ${WHITE}    sdk use java 17.0.12-tem && java -jar ~/TLauncher.v17/TLauncher.jar${RESET}"
}

do_hyprland_jakoolit() {
    log_step "Cài đặt Fedora Hyprland — JaKooLit"
    log_warn "Script installer của JaKooLit sẽ chạy interactive — làm theo hướng dẫn trên màn hình"
    echo ""

    local hypr_dir="${HOME}/Fedora-Hyprland"
    if [[ -d "$hypr_dir" ]]; then
        log_warn "Thư mục ${hypr_dir} đã tồn tại — cập nhật..."
        git -C "$hypr_dir" pull --ff-only
    else
        git clone --depth=1 https://github.com/JaKooLit/Fedora-Hyprland.git "$hypr_dir"
    fi

    cd "$hypr_dir"
    chmod +x install.sh
    ./install.sh
    cd "${SCRIPT_DIR}"
    log_ok "Fedora Hyprland JaKooLit đã hoàn tất"
}

do_hyprland_ml4w_stable() {
    log_step "Cài đặt Fedora Hyprland — ML4W Stable"
    log_warn "Script installer của ML4W sẽ chạy — làm theo hướng dẫn trên màn hình"
    echo ""
    bash <(curl -s https://ml4w.com/os/stable)
    log_ok "ML4W Stable đã hoàn tất"
}

do_hyprland_ml4w_rolling() {
    log_step "Cài đặt Fedora Hyprland — ML4W Rolling"
    log_warn "Phiên bản Rolling — có thể không ổn định, làm theo hướng dẫn trên màn hình"
    echo ""
    bash <(curl -s https://ml4w.com/os/rolling)
    log_ok "ML4W Rolling đã hoàn tất"
}

# ════════════════════════════════════════════════════════════
#  MODULE: MACTAHOE THEME
# ════════════════════════════════════════════════════════════

# Tạo ~/AIO-MacTahoe-Themes/SCRIPTS.sh (không tạo .txt nữa)
create_mactahoe_scripts() {
    local mac_dir="${HOME}/AIO-MacTahoe-Themes"
    mkdir -p "${mac_dir}"

    cat > "${mac_dir}/SCRIPTS.sh" << 'SCRIPTEOF'
#!/usr/bin/env bash
# ============================================================
#  MacTahoe Theme Installer — Standalone
#  Yêu cầu: Fedora 41+ | DNF5 | GNOME
# ============================================================
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; WHITE='\033[1;37m'; GRAY='\033[0;90m'
BOLD='\033[1m'; RESET='\033[0m'
DNF="dnf5"

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
echo -e "  ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
set -e

log_step() { echo -e "\n  ${CYAN}${BOLD}▶ ${1}${RESET}"; }
log_ok()   { echo -e "  ${GREEN}✓ ${1}${RESET}"; }

log_step "Cài dependencies"
sudo $DNF install -y --assumeyes \
    gcc make cmake curl perl wget sassc wmctrl \
    gnome-tweaks gtk4-devel libadwaita-devel

BUILD_DIR="${HOME}/.local/share/aio-mactahoe-build"
mkdir -p "${BUILD_DIR}"; cd "${BUILD_DIR}"

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

log_step "Flatpak theme override"
sudo flatpak override --filesystem=xdg-config/gtk-3.0
sudo flatpak override --filesystem=xdg-config/gtk-4.0

log_step "MacTahoe Wallpapers"
cd wallpaper && sudo ./install-gnome-backgrounds.sh && cd "${BUILD_DIR}"

log_ok "MacTahoe Theme đã cài xong!"
echo ""
echo -e "  ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  ${YELLOW}${BOLD}Bước tiếp theo:${RESET}"
echo -e "  ${GRAY}  1. Mở GNOME Tweaks → Appearance → áp dụng theme: macTahoe"
echo -e "     2. Đăng xuất rồi đăng nhập lại${RESET}"
echo ""
read -rp "  Reboot ngay? [y/N]: " rb
[[ "$rb" =~ ^[Yy]$ ]] && sudo systemctl reboot || echo -e "  ${GRAY}Nhớ reboot sau nhé!${RESET}"
SCRIPTEOF

    chmod +x "${mac_dir}/SCRIPTS.sh"
    log_ok "Đã tạo: ${mac_dir}/SCRIPTS.sh"
}

# Kiểm tra LibreOffice Writer — cần để mở file hướng dẫn .docx
check_libreoffice() {
    if ! command -v libreoffice &>/dev/null; then
        log_warn "LibreOffice chưa có — đang cài để mở file hướng dẫn..."
        sudo $DNF install $DNF_OPTS libreoffice-writer
        log_ok "LibreOffice Writer đã cài xong"
    else
        log_ok "LibreOffice đã có sẵn"
    fi
}

# Mở 4 ảnh demo1-4 bằng Loupe (Fedora 41+ default viewer)
open_demo_images() {
    if [[ -z "$DISPLAY" && -z "$WAYLAND_DISPLAY" ]]; then
        return 1
    fi
    if ! command -v loupe &>/dev/null; then
        log_warn "Loupe chưa có, đang cài..."
        sudo $DNF install $DNF_OPTS loupe &>/dev/null
    fi

    local opened=0
    for i in 1 2 3 4; do
        for ext in png jpg jpeg webp; do
            local f="${THEME_DIR}/demo${i}.${ext}"
            if [[ -f "$f" ]]; then
                loupe "$f" &>/dev/null &
                disown
                (( opened++ ))
                break
            fi
        done
    done
    [[ $opened -gt 0 ]] && return 0 || return 1
}

# Mở file hướng dẫn Setup-Mac-themes.docx + link Google Docs
open_guide() {
    local docx="${THEME_DIR}/Setup-Mac-themes.docx"
    local gdocs_url="https://docs.google.com/document/d/18JCycVsugTkMA7JXGYiuwgSTse80--oI/edit?usp=sharing&ouid=113234984388764662222&rtpof=true&sd=true"
    local has_gui=false

    [[ -n "$DISPLAY$WAYLAND_DISPLAY" ]] && has_gui=true

    if [[ "$has_gui" == true ]]; then
        # Mở file .docx offline bằng LibreOffice Writer
        if [[ -f "$docx" ]]; then
            echo -e "  ${CYAN}📄 Mở hướng dẫn offline (LibreOffice Writer)...${RESET}"
            libreoffice --writer "$docx" &>/dev/null &
            disown
            log_ok "Đã mở: Setup-Mac-themes.docx"
        else
            log_warn "Không tìm thấy ${docx}"
        fi

        # Nếu có trình duyệt → mở thêm link Google Docs online
        local browser=""
        for b in xdg-open google-chrome brave-browser firefox chromium; do
            if command -v "$b" &>/dev/null; then
                browser="$b"
                break
            fi
        done

        if [[ -n "$browser" ]]; then
            echo -e "  ${CYAN}🌐 Mở hướng dẫn online (Google Docs)...${RESET}"
            "$browser" "$gdocs_url" &>/dev/null &
            disown
            log_ok "Đã mở link hướng dẫn online trên trình duyệt"
        else
            echo -e "  ${GRAY}  (Không tìm thấy trình duyệt — bỏ qua mở link online)${RESET}"
            echo -e "  ${GRAY}  Link hướng dẫn: ${WHITE}${gdocs_url}${RESET}"
        fi
    else
        log_warn "Không có GUI session — không thể mở file hướng dẫn"
        echo -e "  ${GRAY}  Xem hướng dẫn tại: ${WHITE}${gdocs_url}${RESET}"
    fi
}

do_mactahoe() {
    # 1. Tạo thư mục + SCRIPTS.sh
    log_step "Tạo ~/AIO-MacTahoe-Themes/SCRIPTS.sh"
    create_mactahoe_scripts

    # 2. Check LibreOffice Writer
    log_step "Kiểm tra LibreOffice Writer"
    check_libreoffice

    # 3. Cài theme thực tế
    log_step "Cài đặt MacTahoe Theme (GTK + Icons + Wallpapers)"
    sudo $DNF install $DNF_OPTS \
        gcc make cmake curl perl wget sassc wmctrl \
        gnome-tweaks gtk4-devel libadwaita-devel

    local build_dir="${HOME}/.local/share/aio-mactahoe-build"
    mkdir -p "${build_dir}"; cd "${build_dir}"

    log_step "  MacTahoe Icon Theme"
    if [[ -d "MacTahoe-icon-theme" ]]; then
        git -C MacTahoe-icon-theme pull --ff-only
    else
        git clone --depth=1 https://github.com/vinceliuice/MacTahoe-icon-theme.git
    fi
    cd MacTahoe-icon-theme && ./install.sh -b && cd "${build_dir}"

    log_step "  MacTahoe GTK Theme"
    if [[ -d "MacTahoe-gtk-theme" ]]; then
        git -C MacTahoe-gtk-theme pull --ff-only
    else
        git clone --depth=1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git
    fi
    cd MacTahoe-gtk-theme
    ./install.sh -n macTahoe -t all -l --shell -i simple -h bigger --round
    sudo ./tweaks.sh -g -nd
    sudo flatpak override --filesystem=xdg-config/gtk-3.0
    sudo flatpak override --filesystem=xdg-config/gtk-4.0

    log_step "  MacTahoe Wallpapers"
    cd wallpaper && sudo ./install-gnome-backgrounds.sh && cd "${build_dir}"

    log_ok "MacTahoe Theme đã cài xong!"

    # 4. Thông báo đường dẫn
    echo ""
    log_div
    echo ""
    echo -e "  ${WHITE}${BOLD}📁 ~/AIO-MacTahoe-Themes/${RESET}"
    echo -e "  ${GRAY}     SCRIPTS.sh  → Chạy lại để cài theme bất cứ lúc nào${RESET}"
    echo ""
    echo -e "  ${YELLOW}${BOLD}Bước tiếp theo:${RESET}"
    echo -e "  ${GRAY}  1. Mở GNOME Tweaks → Appearance → áp dụng:"
    echo -e "        Shell Theme : macTahoe  |  Icons : MacTahoe"
    echo -e "     2. Đăng xuất rồi đăng nhập lại${RESET}"
    log_div

    # 5. Mở file hướng dẫn (offline + online)
    echo ""
    open_guide
}

# ════════════════════════════════════════════════════════════
#  PROMPT MACTAHOE (sau khi cài xong, chỉ hỏi nếu là GNOME)
# ════════════════════════════════════════════════════════════
prompt_mactahoe_gnome() {
    echo ""
    log_div
    echo ""
    echo -e "  ${CYAN}${BOLD}🍎 Phát hiện bạn đang dùng GNOME!${RESET}"
    echo ""
    echo -e "  Script có thể cài giao diện ${WHITE}${BOLD}macOS Tahoe${RESET} cho GNOME của bạn,"
    echo -e "  bao gồm: GTK4/3 Theme, Icon Theme và Wallpapers."
    echo ""

    # Mở 4 ảnh demo
    if [[ -d "$THEME_DIR" ]]; then
        echo -e "  ${GREEN}🖼  Đang mở ảnh demo (demo1~4) bằng Loupe...${RESET}"
        echo -e "  ${GRAY}     Thư mục: ${WHITE}${THEME_DIR}${RESET}"
        echo ""
        if open_demo_images; then
            echo -e "  ${GRAY}     ✓ Các ảnh đã mở — xem xong quay lại terminal để chọn.${RESET}"
        else
            echo -e "  ${YELLOW}     Không mở được Loupe (SSH / không có GUI?).${RESET}"
            echo -e "  ${GRAY}     Xem ảnh tại: ${WHITE}${THEME_DIR}${RESET}"
        fi
    else
        echo -e "  ${YELLOW}  ℹ  Không tìm thấy thư mục Mac-Theme-Install.${RESET}"
        echo -e "  ${GRAY}     Cần có: ${WHITE}${THEME_DIR}${RESET}"
    fi

    echo ""
    log_div
    echo ""
    echo -ne "  ${BOLD}Bạn có muốn cài giao diện macOS Tahoe không? [y/N]: ${RESET}"
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

    # ── Detect Desktop Environment ───────────────────────────
    local CURRENT_DE
    CURRENT_DE=$(detect_desktop_env)
    echo -e "  ${CYAN}▶ Desktop Environment: ${WHITE}${BOLD}${CURRENT_DE}${RESET}"
    echo ""

    # ── Kiểm tra wget, curl ───────────────────────────────────
    check_dependencies
    echo ""

    if [[ "$CURRENT_DE" != "gnome" ]]; then
        echo -e "  ${YELLOW}⚠ Không phát hiện GNOME (đang dùng: ${CURRENT_DE})${RESET}"
        echo -e "  ${GRAY}  GNOME Tweaks và GNOME Extensions sẽ bị vô hiệu hoá.${RESET}"
        echo ""
    fi

    # ════════════════════════════════════════════════════════
    #  MENU 1 — THIẾT LẬP CƠ BẢN
    # ════════════════════════════════════════════════════════
    local base_names=(
        "System Upgrade"
        "RPM Fusion"
        "Flathub"
    )
    local base_descs=(
        "dnf5 upgrade --refresh — cập nhật toàn bộ hệ thống (khuyên dùng)"
        "Kích hoạt RPM Fusion Free + Nonfree (cần cho VLC, FFmpeg...)"
        "Thêm kho Flathub để cài app Flatpak"
    )
    local base_sel=("1" "1" "1")
    local base_dis=("0" "0" "0")

    show_banner
    tput cup 8 0
    echo -e "  ${BOLD}${MAGENTA}BƯỚC 1/3 — Thiết lập cơ bản${RESET}\n"
    checkbox_menu "Chọn bước muốn thực hiện:" base_names base_descs base_sel base_dis

    # ════════════════════════════════════════════════════════
    #  MENU 2A — ỨNG DỤNG (trang 1/2)
    # ════════════════════════════════════════════════════════
    local app_names_a=(
        "Brave Browser"
        "Google Chrome"
        "VLC + FFmpeg"
        "Zoom"
        "Discord"
        "Blue Recorder"
        "GNOME Tweaks + Extension Manager"
        "GNOME Extensions  (9 extensions MacTahoe set)"
    )
    local app_descs_a=(
        "Trình duyệt bảo mật, chặn quảng cáo — thêm repo Brave"
        "Trình duyệt Google Chrome ổn định — tải RPM từ Google"
        "Xem phim + encode video — cần RPM Fusion đã bật"
        "Họp online — tải RPM từ zoom.us"
        "Chat gaming — Flatpak (Flathub)"
        "Quay màn hình đơn giản — Flatpak (Flathub)"
        "Tinh chỉnh GNOME + quản lý extensions — chỉ dành cho GNOME"
        "Tự động cài Blur my Shell, Dash2Dock, Desktop Cube, Vitals... — chỉ dành cho GNOME"
    )
    local app_sel_a=("0" "0" "0" "0" "0" "0" "0" "0")
    local app_dis_a=("0" "0" "0" "0" "0" "0" "0" "0")
    if [[ "$CURRENT_DE" != "gnome" ]]; then
        app_dis_a[6]="1"; app_sel_a[6]="0"
        app_dis_a[7]="1"; app_sel_a[7]="0"
    fi

    show_banner
    tput cup 8 0
    echo -e "  ${BOLD}${MAGENTA}BƯỚC 2/3 — Ứng dụng  ${GRAY}(Trang 1/2 — Trình duyệt & GNOME)${RESET}\n"
    checkbox_menu "Chọn ứng dụng muốn cài:" app_names_a app_descs_a app_sel_a app_dis_a

    # ════════════════════════════════════════════════════════
    #  MENU 2B — ỨNG DỤNG (trang 2/2)
    # ════════════════════════════════════════════════════════
    local app_names_b=(
        "Fcitx5 + Unikey  (Gõ tiếng Việt)"
        "Git + Fastfetch"
        "OnlyOffice Desktop Editors"
        "WPS Office"
        "TLauncher Minecraft  (Java 17 Temurin + SDKMAN)"
        "Fedora Hyprland — JaKooLit"
        "Fedora Hyprland — ML4W Stable"
        "Fedora Hyprland — ML4W Rolling"
    )
    local app_descs_b=(
        "Bộ gõ Unikey, hỗ trợ GTK4/Qt/Wayland/X11"
        "Quản lý source code + hiển thị thông tin hệ thống"
        "Bộ Office miễn phí, tương thích .docx/.xlsx/.pptx — Flatpak"
        "Bộ Office nhẹ, giao diện quen thuộc, tương thích MS Office — Flatpak"
        "SDKMAN + Java 17 Temurin + TLauncher.jar + shortcut App Menu"
        "git clone JaKooLit/Fedora-Hyprland + chạy install.sh (interactive)"
        "bash <(curl -s https://ml4w.com/os/stable)"
        "bash <(curl -s https://ml4w.com/os/rolling) — có thể không ổn định"
    )
    local app_sel_b=("0" "1" "0" "0" "0" "0" "0" "0")
    local app_dis_b=("0" "0" "0" "0" "0" "0" "0" "0")

    show_banner
    tput cup 8 0
    echo -e "  ${BOLD}${MAGENTA}BƯỚC 3/3 — Ứng dụng  ${GRAY}(Trang 2/2 — Office, Game & Hyprland)${RESET}\n"
    checkbox_menu "Chọn ứng dụng muốn cài:" app_names_b app_descs_b app_sel_b app_dis_b

    # Gộp 2 trang thành array chung để dùng bên dưới
    local app_sel=(
        "${app_sel_a[0]}" "${app_sel_a[1]}" "${app_sel_a[2]}" "${app_sel_a[3]}"
        "${app_sel_a[4]}" "${app_sel_a[5]}" "${app_sel_a[6]}" "${app_sel_a[7]}"
        "${app_sel_b[0]}" "${app_sel_b[1]}" "${app_sel_b[2]}" "${app_sel_b[3]}"
        "${app_sel_b[4]}" "${app_sel_b[5]}" "${app_sel_b[6]}" "${app_sel_b[7]}"
    )

    # ════════════════════════════════════════════════════════
    #  XÁC NHẬN
    # ════════════════════════════════════════════════════════
    show_banner
    echo -e "  ${BOLD}${WHITE}Xác nhận danh sách cài đặt:${RESET}\n"

    local any=0
    [[ "${base_sel[0]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} System Upgrade"                        && any=1
    [[ "${base_sel[1]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} RPM Fusion"                            && any=1
    [[ "${base_sel[2]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} Flathub"                               && any=1
    [[ "${app_sel[0]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Brave Browser"                         && any=1
    [[ "${app_sel[1]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Google Chrome"                         && any=1
    [[ "${app_sel[2]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} VLC + FFmpeg"                          && any=1
    [[ "${app_sel[3]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Zoom"                                  && any=1
    [[ "${app_sel[4]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Discord (Flatpak)"                     && any=1
    [[ "${app_sel[5]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Blue Recorder (Flatpak)"               && any=1
    [[ "${app_sel[6]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} GNOME Tweaks + Extension Manager"      && any=1
    [[ "${app_sel[7]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} GNOME Extensions (9 extensions)"       && any=1
    [[ "${app_sel[8]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Fcitx5 + Unikey"                       && any=1
    [[ "${app_sel[9]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Git + Fastfetch"                       && any=1
    [[ "${app_sel[10]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} OnlyOffice (Flatpak)"                  && any=1
    [[ "${app_sel[11]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} WPS Office (Flatpak)"                  && any=1
    [[ "${app_sel[12]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} TLauncher Minecraft (Java 17)"            && any=1
    [[ "${app_sel[13]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} Fedora Hyprland — JaKooLit"            && any=1
    [[ "${app_sel[14]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} Fedora Hyprland — ML4W Stable"         && any=1
    [[ "${app_sel[15]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} Fedora Hyprland — ML4W Rolling"        && any=1

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
    [[ "${app_sel[7]}"  == "1" ]] && do_gnome_extensions
    [[ "${app_sel[8]}"  == "1" ]] && do_fcitx5
    [[ "${app_sel[9]}"  == "1" ]] && do_dev_tools
    [[ "${app_sel[10]}" == "1" ]] && do_onlyoffice
    [[ "${app_sel[11]}" == "1" ]] && do_wps
    [[ "${app_sel[12]}" == "1" ]] && do_tlauncher
    [[ "${app_sel[13]}" == "1" ]] && do_hyprland_jakoolit
    [[ "${app_sel[14]}" == "1" ]] && do_hyprland_ml4w_stable
    [[ "${app_sel[15]}" == "1" ]] && do_hyprland_ml4w_rolling

    # Cập nhật lần cuối
    log_step "Cập nhật lần cuối"
    sudo $DNF upgrade --refresh $DNF_OPTS
    log_ok "Hoàn tất"

    echo ""
    log_div
    echo -e "  ${GREEN}${BOLD}🎉 Fedora đã được setup xong! Chúc bạn vọc vui vẻ 🇻🇳${RESET}"

    # ── Auto-detect GNOME → đề xuất MacTahoe ────────────────
    set +e
    if [[ "$CURRENT_DE" == "gnome" ]]; then
        prompt_mactahoe_gnome
    else
        echo ""
        echo -e "  ${GRAY}  (Không phát hiện GNOME — bỏ qua đề xuất MacTahoe Theme)${RESET}"
    fi
    set -e

    # ── Reboot ───────────────────────────────────────────────
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