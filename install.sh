#!/bin/bash
#
# Skyport Panel/Wings Comprehensive Installation Script
# KS Hosting by KSGaming - Professional Deployment Tool
#
# This script installs prerequisites (Docker, Node.js, Git) and offers a menu
# to install either the Panel or the Wings component, including systemd setup.
#
# NOTE: This script assumes a Debian/Ubuntu-based system.
#

# --- Color Definitions ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# --- Configuration Variables ---
PANEL_DIR="/etc/skyport"
WINGS_DIR="/etc/skyportd"
PANEL_REPO="https://github.com/skyport-team/panel"
WINGS_REPO="https://github.com/skyport-team/skyportd"
NODE_VERSION="22.x"

# --- ASCII Art & Branding ---
print_header() {
    clear
    echo -e "${PURPLE}"
    echo '  ╔═══════════════════════════════════════════════════════════════╗'
    echo '  ║                                                               ║'
    echo '  ║    ██╗  ██╗███████╗    ██╗  ██╗ ██████╗ ███████╗████████╗    ║'
    echo '  ║    ██║ ██╔╝██╔════╝    ██║  ██║██╔═══██╗██╔════╝╚══██╔══╝    ║'
    echo '  ║    █████╔╝ ███████╗    ███████║██║   ██║█████╗     ██║       ║'
    echo '  ║    ██╔═██╗ ╚════██║    ██╔══██║██║   ██║██╔══╝     ██║       ║'
    echo '  ║    ██║  ██╗███████║    ██║  ██║╚██████╔╝███████╗   ██║       ║'
    echo '  ║    ╚═╝  ╚═╝╚══════╝    ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝       ║'
    echo '  ║                                                               ║'
    echo '  ║           🚀 ${BOLD}Skyport Professional Installer${NC}${PURPLE} 🚀           ║'
    echo '  ║                 ${BOLD}Powered by KS Hosting${NC}${PURPLE}                    ║'
    echo '  ╚═══════════════════════════════════════════════════════════════╝'
    echo -e "${NC}"
}

# --- Spinner Animation ---
spinner() {
    local pid=$1
    local delay=0.15
    local spinstr='⣾⣽⣻⢿⡿⣟⣯⣷'
    echo -n "   "
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# --- Function Definitions ---

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "❌ ${RED}${BOLD}ERROR: This script must be run as root or with 'sudo'${NC}"
        echo -e "   📝 Use: ${CYAN}sudo bash $0${NC}"
        exit 1
    fi
}

print_step() {
    echo -e "\n${BLUE}${BOLD}📦 Step $1:${NC} ${WHITE}$2${NC}"
}

print_success() {
    echo -e "   ✅ ${GREEN}$1${NC}"
}

print_warning() {
    echo -e "   ⚠️  ${YELLOW}$1${NC}"
}

print_error() {
    echo -e "   ❌ ${RED}$1${NC}"
}

print_info() {
    echo -e "   🔍 ${CYAN}$1${NC}"
}

install_prerequisites() {
    print_step "1" "Installing System Prerequisites"
    
    echo -e "   📊 ${WHITE}Detecting system information...${NC}"
    lsb_release -d | cut -f2
    
    # Update system
    print_info "Updating package repositories..."
    apt-get update > /dev/null 2>&1 &
    spinner $!
    print_success "System updated successfully"
    
    # Install Docker
    print_info "Installing Docker Engine..."
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com -o get-docker.sh > /dev/null 2>&1 &
        spinner $!
        sh get-docker.sh > /dev/null 2>&1 &
        spinner $!
        rm get-docker.sh
        print_success "Docker installed successfully"
    else
        print_success "Docker already installed"
    fi
    
    # Enable Docker
    systemctl enable docker > /dev/null 2>&1
    systemctl start docker > /dev/null 2>&1
    
    # Install Node.js
    print_info "Installing Node.js ${NODE_VERSION}..."
    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION} | bash - > /dev/null 2>&1 &
        spinner $!
        apt-get install -y nodejs > /dev/null 2>&1 &
        spinner $!
        print_success "Node.js installed successfully"
    else
        print_success "Node.js already installed"
    fi
    
    # Install Git
    print_info "Installing Git..."
    apt-get install -y git > /dev/null 2>&1 &
    spinner $!
    print_success "Git installed successfully"
    
    # Install additional dependencies
    print_info "Installing additional packages..."
    apt-get install -y curl wget gnupg lsb-release ca-certificates > /dev/null 2>&1 &
    spinner $!
    print_success "Additional packages installed"
    
    echo -e "\n${GREEN}${BOLD}✨ All prerequisites installed successfully!${NC}"
}

install_panel() {
    print_header
    echo -e "${CYAN}${BOLD}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║                   🖥️  PANEL INSTALLATION                    ║${NC}"
    echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════════════════════╝${NC}\n"
    
    install_prerequisites
    
    print_step "2" "Installing Skyport Panel"
    
    # Check for existing installation
    if [ -d "$PANEL_DIR" ]; then
        print_warning "Panel directory already exists at ${PANEL_DIR}"
        echo -e "${YELLOW}Would you like to:${NC}"
        echo -e "  1) ${CYAN}Backup and reinstall${NC}"
        echo -e "  2) ${RED}Abort installation${NC}"
        read -rp "Choice [1-2]: " choice
        
        if [ "$choice" == "1" ]; then
            backup_dir="${PANEL_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
            print_info "Backing up to ${backup_dir}..."
            cp -r "$PANEL_DIR" "$backup_dir" &
            spinner $!
            print_success "Backup created successfully"
            rm -rf "$PANEL_DIR"
        else
            print_error "Installation aborted"
            return 1
        fi
    fi
    
    # Clone repository
    print_info "Cloning Skyport Panel repository..."
    git clone "$PANEL_REPO" /tmp/panel > /dev/null 2>&1 &
    spinner $!
    mkdir -p "$PANEL_DIR"
    mv /tmp/panel/* "$PANEL_DIR/"
    rm -rf /tmp/panel
    print_success "Repository cloned to ${PANEL_DIR}"
    
    cd "$PANEL_DIR"
    
    # Install dependencies
    print_info "Installing Node.js dependencies..."
    npm install --silent > /dev/null 2>&1 &
    spinner $!
    print_success "Dependencies installed"
    
    # Setup configuration
    print_info "Setting up configuration..."
    if [ -f "example_config.json" ]; then
        cp example_config.json config.json
        print_success "Configuration template created"
    else
        print_warning "No example config found, creating basic config..."
        cat > config.json << EOF
{
    "database": {
        "host": "localhost",
        "port": 3306,
        "user": "skyport",
        "password": "changeme",
        "database": "skyport"
    },
    "panel": {
        "host": "0.0.0.0",
        "port": 8080,
        "ssl": false
    }
}
EOF
        print_success "Basic configuration created"
    fi
    
    # Database setup
    print_info "Setting up database..."
    npm run seed --silent > /dev/null 2>&1 &
    spinner $!
    print_success "Database seeded"
    
    # Create admin user
    print_info "Creating admin user..."
    npm run createUser --silent > /dev/null 2>&1 &
    spinner $!
    print_success "Admin user created"
    
    # Create systemd service
    print_info "Creating systemd service..."
    cat > /etc/systemd/system/skyport-panel.service << EOF
[Unit]
Description=Skyport Panel - Game Server Management
Documentation=https://github.com/skyport-team/panel
After=network.target docker.service
Wants=network.target docker.service

[Service]
Type=simple
User=root
WorkingDirectory=${PANEL_DIR}
Environment=NODE_ENV=production
ExecStart=/usr/bin/npm start
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=skyport-panel
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable skyport-panel.service > /dev/null 2>&1
    print_success "Systemd service created and enabled"
    
    # Show completion message
    print_step "3" "Installation Complete!"
    
    echo -e "${GREEN}${BOLD}"
    echo '  ╔═══════════════════════════════════════════════════════════════╗'
    echo '  ║                    🎉 PANEL INSTALLED! 🎉                    ║'
    echo '  ╠═══════════════════════════════════════════════════════════════╣'
    echo '  ║                                                               ║'
    echo '  ║  📍 Installation Directory: /etc/skyport                      ║'
    echo '  ║  ⚙️  Configuration File:    /etc/skyport/config.json          ║'
    echo '  ║  🚀 Service Name:          skyport-panel                      ║'
    echo '  ║                                                               ║'
    echo '  ║  📋 Next Steps:                                               ║'
    echo '  ║    1. Edit config.json with your database details             ║'
    echo '  ║    2. Start panel: systemctl start skyport-panel              ║'
    echo '  ║    3. Check status: systemctl status skyport-panel            ║'
    echo '  ║    4. View logs: journalctl -u skyport-panel -f               ║'
    echo '  ║                                                               ║'
    echo '  ╚═══════════════════════════════════════════════════════════════╝'
    echo -e "${NC}"
    
    echo -e "\n${CYAN}${BOLD}🌐 Access your panel at:${NC} ${WHITE}http://$(hostname -I | awk '{print $1}'):8080${NC}"
    echo -e "${YELLOW}${BOLD}⚠️  Don't forget to configure your firewall!${NC}\n"
}

install_wings() {
    print_header
    echo -e "${BLUE}${BOLD}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}${BOLD}║                   🚀 WINGS INSTALLATION                      ║${NC}"
    echo -e "${BLUE}${BOLD}╚═══════════════════════════════════════════════════════════════╝${NC}\n"
    
    install_prerequisites
    
    print_step "2" "Installing Skyport Wings"
    
    # Check for existing installation
    if [ -d "$WINGS_DIR" ]; then
        print_warning "Wings directory already exists at ${WINGS_DIR}"
        echo -e "${YELLOW}Would you like to:${NC}"
        echo -e "  1) ${CYAN}Backup and reinstall${NC}"
        echo -e "  2) ${RED}Abort installation${NC}"
        read -rp "Choice [1-2]: " choice
        
        if [ "$choice" == "1" ]; then
            backup_dir="${WINGS_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
            print_info "Backing up to ${backup_dir}..."
            cp -r "$WINGS_DIR" "$backup_dir" &
            spinner $!
            print_success "Backup created successfully"
            rm -rf "$WINGS_DIR"
        else
            print_error "Installation aborted"
            return 1
        fi
    fi
    
    # Clone repository
    print_info "Cloning Skyport Wings repository..."
    git clone "$WINGS_REPO" /tmp/skyportd > /dev/null 2>&1 &
    spinner $!
    mkdir -p "$WINGS_DIR"
    mv /tmp/skyportd/* "$WINGS_DIR/"
    rm -rf /tmp/skyportd
    print_success "Repository cloned to ${WINGS_DIR}"
    
    cd "$WINGS_DIR"
    
    # Install dependencies
    print_info "Installing Node.js dependencies..."
    npm install --silent > /dev/null 2>&1 &
    spinner $!
    print_success "Dependencies installed"
    
    # Setup configuration
    print_info "Setting up configuration..."
    if [ -f "example_config.json" ]; then
        cp example_config.json config.json
        print_success "Configuration template created"
    else
        print_warning "No example config found, creating basic config..."
        cat > config.json << EOF
{
    "panel_url": "http://your-panel-url:8080",
    "panel_token": "your_token_here",
    "node": {
        "name": "$(hostname)",
        "location": "default"
    },
    "docker": {
        "socket": "/var/run/docker.sock"
    }
}
EOF
        print_success "Basic configuration created"
    fi
    
    # Create systemd service
    print_info "Creating systemd service..."
    cat > /etc/systemd/system/skyport-wings.service << EOF
[Unit]
Description=Skyport Wings - Game Server Daemon
Documentation=https://github.com/skyport-team/skyportd
After=network.target docker.service
Requires=docker.service
BindsTo=docker.service

[Service]
Type=simple
User=root
WorkingDirectory=${WINGS_DIR}
Environment=NODE_ENV=production
ExecStart=/usr/bin/node ${WINGS_DIR}/index.js
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=skyport-wings
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable skyport-wings.service > /dev/null 2>&1
    print_success "Systemd service created and enabled"
    
    # Show completion message
    print_step "3" "Installation Complete!"
    
    echo -e "${GREEN}${BOLD}"
    echo '  ╔═══════════════════════════════════════════════════════════════╗'
    echo '  ║                    🎉 WINGS INSTALLED! 🎉                    ║'
    echo '  ╠═══════════════════════════════════════════════════════════════╣'
    echo '  ║                                                               ║'
    echo '  ║  📍 Installation Directory: /etc/skyportd                     ║'
    echo '  ║  ⚙️  Configuration File:    /etc/skyportd/config.json         ║'
    echo '  ║  🚀 Service Name:          skyport-wings                      ║'
    echo '  ║                                                               ║'
    echo '  ║  📋 Next Steps:                                               ║'
    echo '  ║    1. Edit config.json with your Panel URL and token          ║'
    echo '  ║    2. Start wings: systemctl start skyport-wings              ║'
    echo '  ║    3. Check status: systemctl status skyport-wings            ║'
    echo '  ║    4. View logs: journalctl -u skyport-wings -f               ║'
    echo '  ║                                                               ║'
    echo '  ╚═══════════════════════════════════════════════════════════════╝'
    echo -e "${NC}"
    
    echo -e "\n${CYAN}${BOLD}🔗 Remember to add this node to your Panel configuration!${NC}"
    echo -e "${YELLOW}${BOLD}⚠️  Ensure Docker is properly configured for game servers!${NC}\n"
}

show_menu() {
    print_header
    
    echo -e "${WHITE}${BOLD}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}${BOLD}║                   📜 INSTALLATION MENU                       ║${NC}"
    echo -e "${WHITE}${BOLD}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}${BOLD}║                                                               ║${NC}"
    echo -e "${WHITE}${BOLD}║  ${CYAN}1) 🖥️  Install Skyport Panel${NC}${WHITE}${BOLD}                         ║${NC}"
    echo -e "${WHITE}${BOLD}║       ${WHITE}Web interface & API server                      ${WHITE}${BOLD}║${NC}"
    echo -e "${WHITE}${BOLD}║                                                               ║${NC}"
    echo -e "${WHITE}${BOLD}║  ${BLUE}2) 🚀 Install Skyport Wings${NC}${WHITE}${BOLD}                         ║${NC}"
    echo -e "${WHITE}${BOLD}║       ${WHITE}Game server node daemon                         ${WHITE}${BOLD}║${NC}"
    echo -e "${WHITE}${BOLD}║                                                               ║${NC}"
    echo -e "${WHITE}${BOLD}║  ${GREEN}3) 📊 System Information${NC}${WHITE}${BOLD}                          ║${NC}"
    echo -e "${WHITE}${BOLD}║                                                               ║${NC}"
    echo -e "${WHITE}${BOLD}║  ${YELLOW}4) 🛠️  Prerequisites Only${NC}${WHITE}${BOLD}                         ║${NC}"
    echo -e "${WHITE}${BOLD}║                                                               ║${NC}"
    echo -e "${WHITE}${BOLD}║  ${RED}5) 🚪 Exit${NC}${WHITE}${BOLD}                                         ║${NC}"
    echo -e "${WHITE}${BOLD}║                                                               ║${NC}"
    echo -e "${WHITE}${BOLD}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo -e ""
    
    echo -e "${PURPLE}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${PURPLE}│  ${BOLD}System:${NC} $(lsb_release -d | cut -f2) $(uname -m)                    ${PURPLE}│${NC}"
    echo -e "${PURPLE}│  ${BOLD}Hostname:${NC} $(hostname)                                         ${PURPLE}│${NC}"
    echo -e "${PURPLE}│  ${BOLD}IP Address:${NC} $(hostname -I | awk '{print $1}')                            ${PURPLE}│${NC}"
    echo -e "${PURPLE}└─────────────────────────────────────────────────────────────┘${NC}"
    echo -e ""
}

show_system_info() {
    print_header
    echo -e "${CYAN}${BOLD}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║                   📊 SYSTEM INFORMATION                      ║${NC}"
    echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════════════════════╝${NC}\n"
    
    echo -e "${WHITE}${BOLD}System Overview:${NC}"
    echo -e "  ${CYAN}▸${NC} ${WHITE}OS:${NC} $(lsb_release -d | cut -f2)"
    echo -e "  ${CYAN}▸${NC} ${WHITE}Kernel:${NC} $(uname -r)"
    echo -e "  ${CYAN}▸${NC} ${WHITE}Architecture:${NC} $(uname -m)"
    echo -e "  ${CYAN}▸${NC} ${WHITE}Hostname:${NC} $(hostname)"
    echo -e "  ${CYAN}▸${NC} ${WHITE}Uptime:${NC} $(uptime -p | sed 's/up //')"
    
    echo -e "\n${WHITE}${BOLD}Resource Usage:${NC}"
    echo -e "  ${CYAN}▸${NC} ${WHITE}CPU Load:${NC} $(uptime | awk -F'load average:' '{print $2}')"
    echo -e "  ${CYAN}▸${NC} ${WHITE}Memory:${NC} $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
    echo -e "  ${CYAN}▸${NC} ${WHITE}Disk:${NC} $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"
    
    echo -e "\n${WHITE}${BOLD}Required Software:${NC}"
    echo -e "  ${CYAN}▸${NC} ${WHITE}Docker:${NC} $(docker --version 2>/dev/null | cut -d' ' -f3 || echo "Not installed")"
    echo -e "  ${CYAN}▸${NC} ${WHITE}Node.js:${NC} $(node --version 2>/dev/null || echo "Not installed")"
    echo -e "  ${CYAN}▸${NC} ${WHITE}npm:${NC} $(npm --version 2>/dev/null || echo "Not installed")"
    echo -e "  ${CYAN}▸${NC} ${WHITE}Git:${NC} $(git --version 2>/dev/null | cut -d' ' -f3 || echo "Not installed")"
    
    echo -e "\n${WHITE}${BOLD}Network Information:${NC}"
    echo -e "  ${CYAN}▸${NC} ${WHITE}IP Address:${NC} $(hostname -I | awk '{print $1}')"
    echo -e "  ${CYAN}▸${NC} ${WHITE}Public IP:${NC} $(curl -s ifconfig.me || echo "Unavailable")"
    
    echo -e "\n${GREEN}${BOLD}Press Enter to continue...${NC}"
    read -r
}

# --- Main Execution ---
check_root

while true; do
    show_menu
    
    echo -e "${YELLOW}${BOLD}👉 Please select an option (1-5):${NC} "
    echo -ne "${WHITE}${BOLD}➤ ${NC}"
    read -r choice
    
    case $choice in
        1)
            install_panel
            ;;
        2)
            install_wings
            ;;
        3)
            show_system_info
            ;;
        4)
            print_header
            install_prerequisites
            echo -e "\n${GREEN}${BOLD}Press Enter to continue...${NC}"
            read -r
            ;;
        5)
            print_header
            echo -e "${GREEN}${BOLD}"
            echo '  ╔═══════════════════════════════════════════════════════════════╗'
            echo '  ║                    👋 THANK YOU! 👋                         ║'
            echo '  ║               Skyport Installation Complete                 ║'
            echo '  ║          For support, visit: KS Hosting by KSGaming         ║'
            echo '  ╚═══════════════════════════════════════════════════════════════╝'
            echo -e "${NC}"
            exit 0
            ;;
        *)
            echo -e "\n${RED}${BOLD}❌ Invalid option! Please choose between 1-5${NC}"
            sleep 2
            ;;
    esac
done
