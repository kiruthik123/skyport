#!/bin/bash

# =========================================================================
# ███████╗██╗  ██╗    ██╗  ██╗ ██████╗ ███████╗████████╗██╗███╗   ██╗ ██████╗ 
# ██╔════╝██║  ██║    ██║  ██║██╔═══██╗██╔════╝╚══██╔══╝██║████╗  ██║██╔════╝ 
# ███████╗███████║    ███████║██║   ██║███████╗   ██║   ██║██╔██╗ ██║██║  ███╗
# ╚════██║██╔══██║    ██╔══██║██║   ██║╚════██║   ██║   ██║██║╚██╗██║██║   ██║
# ███████║██║  ██║    ██║  ██║╚██████╔╝███████║   ██║   ██║██║ ╚████║╚██████╔╝
# ╚══════╝╚═╝  ╚═╝    ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝   ╚═╝╚═╝  ╚═══╝ ╚═════╝ 
# =========================================================================
#                     🚀 KS HOSTING BY KSGAMING 🚀
# =========================================================================

# ==================== ANSI COLOR PALETTE ====================
COLOR_RESET="\033[0m"

# Primary Colors
RED="\033[1;91m"       # 🔴 Bright Red
GREEN="\033[1;92m"     # 🟢 Bright Green
YELLOW="\033[1;93m"    # 🟡 Bright Yellow
BLUE="\033[1;94m"      # 🔵 Bright Blue
MAGENTA="\033[1;95m"   # 🟣 Bright Magenta
CYAN="\033[1;96m"      # 🔵 Bright Cyan
WHITE="\033[1;97m"     # ⚪ Bright White

# Background Colors
BG_BLACK="\033[40m"
BG_BLUE="\033[104m"
BG_GREEN="\033[102m"
BG_RED="\033[101m"

# Text Effects
BOLD="\033[1m"
UNDERLINE="\033[4m"
BLINK="\033[5m"

# Icons
ICON_SUCCESS="✅"
ICON_ERROR="❌"
ICON_WARNING="⚠️"
ICON_INFO="ℹ️"
ICON_ROCKET="🚀"
ICON_SERVER="🖥️"
ICON_GEAR="⚙️"
ICON_DATABASE="🗄️"
ICON_NETWORK="🌐"
ICON_LOCK="🔒"
ICON_KEY="🔑"
ICON_FOLDER="📁"
ICON_DOWNLOAD="📥"
ICON_BUILD="🔨"
ICON_START="▶️"
ICON_STOP="⏹️"
ICON_EXIT="🚪"
ICON_HOURGLASS="⏳"
ICON_CHECK="✔️"
ICON_PARTY="🎉"
ICON_FIRE="🔥"

# ==================== UTILITY FUNCTIONS ====================
print_header() {
    clear
    echo -e "${BG_BLUE}${WHITE}════════════════════════════════════════════════════════════${COLOR_RESET}"
    echo -e "${BG_BLUE}${WHITE}                ${ICON_ROCKET} KS HOSTING CONTROL CENTER ${ICON_ROCKET}           ${COLOR_RESET}"
    echo -e "${BG_BLUE}${WHITE}════════════════════════════════════════════════════════════${COLOR_RESET}\n"
}

print_section() {
    echo -e "\n${CYAN}${ICON_INFO} ${BOLD}$1${COLOR_RESET}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${COLOR_RESET}"
}

print_status() {
    local status=$1
    local message=$2
    case $status in
        "success") echo -e "${GREEN}${ICON_SUCCESS} ${message}${COLOR_RESET}" ;;
        "error") echo -e "${RED}${ICON_ERROR} ${message}${COLOR_RESET}" ;;
        "warning") echo -e "${YELLOW}${ICON_WARNING} ${message}${COLOR_RESET}" ;;
        "info") echo -e "${CYAN}${ICON_INFO} ${message}${COLOR_RESET}" ;;
    esac
}

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⣷⣯⣟⡿⢿⣻⣽⣾'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

progress_bar() {
    local duration=$1
    local width=50
    local increment=$((100 / width))
    local count=0
    printf "${BLUE}["
    while [ $count -lt 100 ]; do
        printf "▰"
        count=$((count + increment))
        sleep $(echo "scale=4; $duration/$width" | bc)
    done
    printf "]${COLOR_RESET}\n"
}

# ==================== DEPENDENCY CHECK ====================
check_dependencies() {
    print_section "System Dependency Verification ${ICON_GEAR}"
    
    local missing=()
    
    echo -e "${WHITE}${ICON_HOURGLASS} Checking required packages...${COLOR_RESET}"
    
    # Check Git
    if command -v git &> /dev/null; then
        echo -e "${GREEN}${ICON_CHECK} Git ${BOLD}$(git --version | awk '{print $3}')${COLOR_RESET}"
    else
        echo -e "${RED}${ICON_ERROR} Git not found${COLOR_RESET}"
        missing+=("git")
    fi
    
    # Check Node.js
    if command -v node &> /dev/null; then
        echo -e "${GREEN}${ICON_CHECK} Node.js ${BOLD}$(node --version)${COLOR_RESET}"
    else
        echo -e "${RED}${ICON_ERROR} Node.js not found${COLOR_RESET}"
        missing+=("nodejs")
    fi
    
    # Check npm
    if command -v npm &> /dev/null; then
        echo -e "${GREEN}${ICON_CHECK} npm ${BOLD}$(npm --version)${COLOR_RESET}"
    else
        echo -e "${RED}${ICON_ERROR} npm not found${COLOR_RESET}"
        missing+=("npm")
    fi
    
    if [ ${#missing[@]} -ne 0 ]; then
        print_status "error" "Missing dependencies detected!"
        echo -e "${YELLOW}${ICON_WARNING} Install missing packages with:${COLOR_RESET}"
        echo -e "${WHITE}  sudo apt-get install ${missing[*]}${COLOR_RESET}"
        return 1
    fi
    
    print_status "success" "All dependencies satisfied! ${ICON_PARTY}"
    return 0
}

# ==================== INSTALLATION FUNCTIONS ====================
install_panel() {
    print_header
    print_section "Airlink Panel Installation ${ICON_SERVER}"
    
    if ! check_dependencies; then
        read -r -p "$(echo -e "${YELLOW}${ICON_WARNING} Continue anyway? (y/N): ${COLOR_RESET}")" -n 1
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && return
    fi
    
    echo -e "${MAGENTA}${ICON_DOWNLOAD} ${BOLD}Step 1: Downloading Panel Source Code${COLOR_RESET}"
    echo -e "${WHITE}└─ Destination: /var/www/panel${COLOR_RESET}"
    
    # Create directory if it doesn't exist
    sudo mkdir -p /var/www/
    cd /var/www/ || { print_status "error" "Failed to access /var/www/"; return 1; }
    
    # Clone repository
    if [ -d "panel" ]; then
        echo -e "${YELLOW}${ICON_WARNING} Panel directory exists. Updating...${COLOR_RESET}"
        cd panel && git pull
    else
        git clone https://github.com/AirlinkLabs/panel.git &
        spinner $!
        cd panel || { print_status "error" "Failed to enter panel directory"; return 1; }
    fi
    
    echo -e "\n${MAGENTA}${ICON_LOCK} ${BOLD}Step 2: Setting Permissions${COLOR_RESET}"
    sudo chown -R www-data:www-data /var/www/panel
    sudo chmod -R 755 /var/www/panel
    print_status "success" "Permissions configured"
    
    echo -e "\n${MAGENTA}${ICON_GEAR} ${BOLD}Step 3: Installing Dependencies${COLOR_RESET}"
    npm install -g typescript &
    spinner $!
    npm install --omit=dev &
    spinner $!
    print_status "success" "Dependencies installed"
    
    echo -e "\n${MAGENTA}${ICON_DATABASE} ${BOLD}Step 4: Database Migration${COLOR_RESET}"
    npm run migrate:dev &
    spinner $!
    print_status "success" "Database migrated"
    
    echo -e "\n${MAGENTA}${ICON_BUILD} ${BOLD}Step 5: Building Application${COLOR_RESET}"
    npm run build-ts &
    spinner $!
    print_status "success" "Build completed"
    
    echo -e "\n${GREEN}${ICON_PARTY} ${BOLD}Panel Installation Complete!${COLOR_RESET}"
    echo -e "${WHITE}└─ Start with: ${CYAN}npm run start${COLOR_RESET}"
    echo -e "${WHITE}└─ Directory: ${YELLOW}/var/www/panel${COLOR_RESET}"
    
    progress_bar 2
}

install_wings() {
    print_header
    print_section "Airlink Wings Installation ${ICON_ROCKET}"
    
    if ! check_dependencies; then
        read -r -p "$(echo -e "${YELLOW}${ICON_WARNING} Continue anyway? (y/N): ${COLOR_RESET}")" -n 1
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && return
    fi
    
    echo -e "${MAGENTA}${ICON_DOWNLOAD} ${BOLD}Step 1: Downloading Wings Source Code${COLOR_RESET}"
    echo -e "${WHITE}└─ Destination: /etc/daemon${COLOR_RESET}"
    
    # Create directory if it doesn't exist
    sudo mkdir -p /etc/
    cd /etc/ || { print_status "error" "Failed to access /etc/"; return 1; }
    
    # Clone repository
    if [ -d "daemon" ]; then
        echo -e "${YELLOW}${ICON_WARNING} Daemon directory exists. Updating...${COLOR_RESET}"
        cd daemon && git pull
    else
        git clone https://github.com/AirlinkLabs/daemon.git &
        spinner $!
        cd daemon || { print_status "error" "Failed to enter daemon directory"; return 1; }
    fi
    
    echo -e "\n${MAGENTA}${ICON_LOCK} ${BOLD}Step 2: Setting Permissions${COLOR_RESET}"
    sudo chown -R www-data:www-data /etc/daemon
    sudo chmod -R 755 /etc/daemon
    print_status "success" "Permissions configured"
    
    echo -e "\n${MAGENTA}${ICON_GEAR} ${BOLD}Step 3: Installing Dependencies${COLOR_RESET}"
    npm install -g typescript &
    spinner $!
    npm install &
    spinner $!
    print_status "success" "Dependencies installed"
    
    echo -e "\n${MAGENTA}${ICON_KEY} ${BOLD}Step 4: Configuration Setup${COLOR_RESET}"
    if [ -f "example.env" ]; then
        cp example.env .env
        echo -e "${YELLOW}${ICON_WARNING} IMPORTANT: Edit configuration file:${COLOR_RESET}"
        echo -e "${WHITE}└─ ${CYAN}nano /etc/daemon/.env${COLOR_RESET}"
        echo -e "${WHITE}└─ Set API keys, ports, and server settings${COLOR_RESET}"
    else
        print_status "warning" "example.env not found, manual configuration required"
    fi
    
    echo -e "\n${MAGENTA}${ICON_BUILD} ${BOLD}Step 5: Building Wings${COLOR_RESET}"
    npm run build &
    spinner $!
    print_status "success" "Build completed"
    
    echo -e "\n${GREEN}${ICON_PARTY} ${BOLD}Wings Installation Complete!${COLOR_RESET}"
    echo -e "${WHITE}└─ Start with: ${CYAN}npm run start${COLOR_RESET}"
    echo -e "${WHITE}└─ Directory: ${YELLOW}/etc/daemon${COLOR_RESET}"
    echo -e "${WHITE}└─ Config: ${YELLOW}/etc/daemon/.env${COLOR_RESET}"
    
    progress_bar 2
}

# ==================== SERVICE MANAGEMENT ====================
start_panel() {
    print_header
    print_section "Starting Airlink Panel ${ICON_START}"
    
    if [ ! -d "/var/www/panel" ]; then
        print_status "error" "Panel not installed!"
        echo -e "${YELLOW}Run option 1 to install first${COLOR_RESET}"
        sleep 3
        return
    fi
    
    cd /var/www/panel || return
    
    echo -e "${GREEN}${ICON_ROCKET} Launching Panel...${COLOR_RESET}"
    echo -e "${YELLOW}${ICON_WARNING} Press ${BOLD}CTRL+C${COLOR_RESET}${YELLOW} to stop${COLOR_RESET}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${COLOR_RESET}"
    
    # Start panel with colored output
    npm run start | while IFS= read -r line; do
        case "$line" in
            *error*|*Error*|*ERROR*)
                echo -e "${RED}$line${COLOR_RESET}"
                ;;
            *warn*|*Warn*|*WARN*)
                echo -e "${YELLOW}$line${COLOR_RESET}"
                ;;
            *success*|*Success*|*SUCCESS*)
                echo -e "${GREEN}$line${COLOR_RESET}"
                ;;
            *info*|*Info*|*INFO*)
                echo -e "${CYAN}$line${COLOR_RESET}"
                ;;
            *)
                echo -e "${WHITE}$line${COLOR_RESET}"
                ;;
        esac
    done
    
    echo -e "\n${YELLOW}${ICON_STOP} Panel service stopped${COLOR_RESET}"
}

start_wings() {
    print_header
    print_section "Starting Airlink Wings ${ICON_START}"
    
    if [ ! -d "/etc/daemon" ]; then
        print_status "error" "Wings not installed!"
        echo -e "${YELLOW}Run option 2 to install first${COLOR_RESET}"
        sleep 3
        return
    fi
    
    cd /etc/daemon || return
    
    echo -e "${GREEN}${ICON_ROCKET} Launching Wings...${COLOR_RESET}"
    echo -e "${YELLOW}${ICON_WARNING} Press ${BOLD}CTRL+C${COLOR_RESET}${YELLOW} to stop${COLOR_RESET}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${COLOR_RESET}"
    
    # Start wings with colored output
    npm run start | while IFS= read -r line; do
        case "$line" in
            *error*|*Error*|*ERROR*)
                echo -e "${RED}$line${COLOR_RESET}"
                ;;
            *warn*|*Warn*|*WARN*)
                echo -e "${YELLOW}$line${COLOR_RESET}"
                ;;
            *success*|*Success*|*SUCCESS*)
                echo -e "${GREEN}$line${COLOR_RESET}"
                ;;
            *info*|*Info*|*INFO*)
                echo -e "${CYAN}$line${COLOR_RESET}"
                ;;
            *request*|*response*|*Request*|*Response*)
                echo -e "${MAGENTA}$line${COLOR_RESET}"
                ;;
            *)
                echo -e "${WHITE}$line${COLOR_RESET}"
                ;;
        esac
    done
    
    echo -e "\n${YELLOW}${ICON_STOP} Wings service stopped${COLOR_RESET}"
}

# ==================== MAIN MENU ====================
show_menu() {
    print_header
    
    echo -e "${WHITE}${BOLD}╔══════════════════════════════════════════════════════════╗${COLOR_RESET}"
    echo -e "${WHITE}${BOLD}║                    ${ICON_FIRE} MAIN MENU ${ICON_FIRE}                     ║${COLOR_RESET}"
    echo -e "${WHITE}${BOLD}╠══════════════════════════════════════════════════════════╣${COLOR_RESET}"
    echo -e "${WHITE}${BOLD}║                                                        ║${COLOR_RESET}"
    echo -e "${WHITE}${BOLD}║  ${CYAN}${ICON_SERVER}  ${BOLD}1. INSTALL AIRLINK PANEL                  ║${COLOR_RESET}"
    echo -e "${WHITE}${BOLD}║  ${CYAN}${ICON_ROCKET}  ${BOLD}2. INSTALL AIRLINK WINGS                  ║${COLOR_RESET}"
    echo -e "${WHITE}${BOLD}║                                                        ║${COLOR_RESET}"
    echo -e "${WHITE}${BOLD}╠══════════════════════════════════════════════════════════╣${COLOR_RESET}"
    echo -e "${WHITE}${BOLD}║            ${YELLOW}${ICON_GEAR} SERVICE MANAGEMENT ${ICON_GEAR}             ║${COLOR_RESET}"
    echo -e "${WHITE}${BOLD}╠══════════════════════════════════════════════════════════╣${COLOR_RESET}"
    echo -e "${WHITE}${BOLD}║                                                        ║${COLOR_RESET}"
    echo -e "${WHITE}${BOLD}║  ${GREEN}${ICON_START}  ${BOLD}3. START PANEL SERVICE                    ║${COLOR_RESET}"
    echo -e "${WHITE}${BOLD}║  ${GREEN}${ICON_START}  ${BOLD}4. START WINGS SERVICE                    ║${COLOR_RESET}"
    echo -e "${WHITE}${BOLD}║                                                        ║${COLOR_RESET}"
    echo -e "${WHITE}${BOLD}╠══════════════════════════════════════════════════════════╣${COLOR_RESET}"
    echo -e "${WHITE}${BOLD}║                                                        ║${COLOR_RESET}"
    echo -e "${WHITE}${BOLD}║  ${RED}${ICON_EXIT}  ${BOLD}0. EXIT INSTALLER                          ║${COLOR_RESET}"
    echo -e "${WHITE}${BOLD}║                                                        ║${COLOR_RESET}"
    echo -e "${WHITE}${BOLD}╚══════════════════════════════════════════════════════════╝${COLOR_RESET}"
    echo -e ""
}

main_menu() {
    while true; do
        show_menu
        
        echo -ne "${MAGENTA}${BLINK}👉${COLOR_RESET} ${BOLD}Select option [0-4]: ${COLOR_RESET}"
        read -r choice
        
        case $choice in
            1)
                install_panel
                echo -e "\n${WHITE}Press ${GREEN}ENTER${WHITE} to continue...${COLOR_RESET}"
                read -r
                ;;
            2)
                install_wings
                echo -e "\n${WHITE}Press ${GREEN}ENTER${WHITE} to continue...${COLOR_RESET}"
                read -r
                ;;
            3)
                start_panel
                echo -e "\n${WHITE}Press ${GREEN}ENTER${WHITE} to continue...${COLOR_RESET}"
                read -r
                ;;
            4)
                start_wings
                echo -e "\n${WHITE}Press ${GREEN}ENTER${WHITE} to continue...${COLOR_RESET}"
                read -r
                ;;
            0)
                print_header
                echo -e "${GREEN}${BOLD}${ICON_PARTY} Thank you for using KS HOSTING! ${ICON_PARTY}${COLOR_RESET}"
                echo -e "${CYAN}${BOLD}           Have a productive day! 👨‍💻${COLOR_RESET}\n"
                echo -e "${BLUE}════════════════════════════════════════════════════════════${COLOR_RESET}"
                exit 0
                ;;
            *)
                echo -e "${RED}${ICON_ERROR} Invalid option! Please select 0-4${COLOR_RESET}"
                sleep 2
                ;;
        esac
    done
}

# ==================== INITIALIZATION ====================
# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo -e "${YELLOW}${ICON_WARNING} Warning: Running as root is not recommended${COLOR_RESET}"
    sleep 1
fi

# Trap for clean exit
trap 'echo -e "\n${RED}${ICON_ERROR} Interrupted! Exiting...${COLOR_RESET}"; exit 1' INT

# Start the application
main_menu
