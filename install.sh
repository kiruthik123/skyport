#!/bin/bash
#
# 🚀 Skyport Panel & Wings Installation Script
# 🔧 Comprehensive installer for Skyport Game Server Management
# 📦 Supports Panel (Control Panel) and Wings (Game Node) components
#
# ⚠️  NOTE: Designed for Debian/Ubuntu-based systems
# ⚠️  WARNING: This script must be run as root
#

# =============================================================================
# 🎨 CONFIGURATION - Customize these variables if needed
# =============================================================================
PANEL_DIR="/etc/skyport"
WINGS_DIR="/etc/skyportd"
PANEL_REPO="https://github.com/skyport-team/panel"
WINGS_REPO="https://github.com/skyport-team/skyportd"
NODE_VERSION="22.x"
LOG_FILE="/tmp/skyport-install-$(date +%Y%m%d-%H%M%S).log"

# =============================================================================
# 🎨 COLOR AND FORMATTING
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'
DIM='\033[2m'

HR="================================================================================"
MINI_HR="--------------------------------------------------------------------------------"

# =============================================================================
# 📊 LOGGING FUNCTIONS
# =============================================================================
log_message() {
    echo -e "${2}${1}${NC}" | tee -a "$LOG_FILE"
}

log_info() {
    log_message "🔹 $1" "$CYAN"
}

log_success() {
    log_message "✅ $1" "$GREEN"
}

log_warning() {
    log_message "⚠️  $1" "$YELLOW"
}

log_error() {
    log_message "❌ $1" "$RED"
}

log_header() {
    echo -e "\n${MAGENTA}${BOLD}$HR${NC}" | tee -a "$LOG_FILE"
    echo -e "${MAGENTA}${BOLD}    $1${NC}" | tee -a "$LOG_FILE"
    echo -e "${MAGENTA}${BOLD}$HR${NC}\n" | tee -a "$LOG_FILE"
}

log_step() {
    echo -e "\n${BLUE}${BOLD}📋 $1${NC}" | tee -a "$LOG_FILE"
    echo -e "${DIM}$MINI_HR${NC}" | tee -a "$LOG_FILE"
}

# =============================================================================
# 🔐 PRIVILEGE CHECK
# =============================================================================
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script requires root privileges. Please run with 'sudo'"
        log_info "Usage: sudo bash $0"
        exit 1
    fi
}

# =============================================================================
# 🛠️ SYSTEM CHECKS
# =============================================================================
check_system() {
    log_step "Checking System Compatibility"
    
    # Check OS
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        log_info "Detected OS: $PRETTY_NAME"
        
        if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
            log_warning "This script is designed for Ubuntu/Debian. Proceed with caution."
            read -rp "Continue anyway? (y/N): " -n 1 -r
            echo
            [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
        fi
    else
        log_error "Cannot determine OS. Unsupported system."
        exit 1
    fi
    
    # Check memory
    local mem_kb
    mem_kb=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}')
    if [[ -n "$mem_kb" ]]; then
        local mem_gb=$((mem_kb / 1024 / 1024))
        if [[ $mem_gb -lt 2 ]]; then
            log_warning "Low memory detected (${mem_gb}GB). Minimum 2GB recommended."
        else
            log_success "System memory: ${mem_gb}GB"
        fi
    fi
    
    # Check disk space
    local disk_free
    disk_free=$(df / | tail -1 | awk '{print $4}')
    if [[ -n "$disk_free" ]]; then
        local disk_free_gb=$((disk_free / 1024 / 1024))
        if [[ $disk_free_gb -lt 5 ]]; then
            log_warning "Low disk space (${disk_free_gb}GB free). Minimum 5GB recommended."
        else
            log_success "Disk space: ${disk_free_gb}GB free"
        fi
    fi
}

# =============================================================================
# 📦 PREREQUISITE INSTALLATION
# =============================================================================
install_prerequisites() {
    log_step "Installing System Prerequisites"
    
    # Update package list
    log_info "Updating package repositories..."
    if ! apt-get update -qq >> "$LOG_FILE" 2>&1; then
        log_error "Failed to update package list"
        exit 1
    fi
    
    # Install base dependencies
    log_info "Installing base dependencies..."
    local base_packages="curl wget git gnupg lsb-release ca-certificates"
    if ! apt-get install -y -qq $base_packages >> "$LOG_FILE" 2>&1; then
        log_error "Failed to install base packages"
        exit 1
    fi
    
    # Install Docker
    log_info "Installing Docker..."
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com -o /tmp/get-docker.sh >> "$LOG_FILE" 2>&1
        if ! sh /tmp/get-docker.sh >> "$LOG_FILE" 2>&1; then
            log_error "Docker installation failed"
            exit 1
        fi
        rm -f /tmp/get-docker.sh
        log_success "Docker installed successfully"
    else
        log_info "Docker already installed (version: $(docker --version | cut -d' ' -f3))"
    fi
    
    # Start and enable Docker
    if ! systemctl is-active --quiet docker; then
        log_info "Starting Docker service..."
        systemctl start docker >> "$LOG_FILE" 2>&1
        systemctl enable docker >> "$LOG_FILE" 2>&1
    fi
    
    # Install Node.js
    log_info "Installing Node.js v${NODE_VERSION}..."
    if ! command -v node &> /dev/null; then
        mkdir -p /etc/apt/keyrings
        curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
            | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg >> "$LOG_FILE" 2>&1
        
        echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_VERSION} nodistro main" \
            | tee /etc/apt/sources.list.d/nodesource.list > /dev/null
        
        apt-get update -qq >> "$LOG_FILE" 2>&1
        
        if ! apt-get install -y -qq nodejs >> "$LOG_FILE" 2>&1; then
            log_error "Node.js installation failed"
            exit 1
        fi
        log_success "Node.js $(node --version) installed"
    else
        log_info "Node.js already installed (version: $(node --version))"
    fi
    
    # Verify installations
    log_info "Verifying installations..."
    if command -v docker &> /dev/null && command -v node &> /dev/null && command -v git &> /dev/null; then
        log_success "All prerequisites installed successfully"
    else
        log_error "Some prerequisites failed to install"
        exit 1
    fi
}

# =============================================================================
# 💻 PANEL INSTALLATION
# =============================================================================
install_panel() {
    log_header "INSTALLING SKYPORT PANEL"
    
    check_system
    install_prerequisites
    
    # Check for existing installation
    if [[ -d "$PANEL_DIR" ]]; then
        log_warning "Panel directory '${PANEL_DIR}' already exists"
        read -rp "Overwrite existing installation? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Panel installation cancelled"
            return 1
        fi
        log_info "Removing existing installation..."
        rm -rf "$PANEL_DIR"
    fi
    
    # Clone repository
    log_step "Downloading Skyport Panel"
    log_info "Cloning from: $PANEL_REPO"
    if ! git clone --depth 1 "$PANEL_REPO" "$PANEL_DIR" >> "$LOG_FILE" 2>&1; then
        log_error "Failed to clone Panel repository"
        return 1
    fi
    cd "$PANEL_DIR" || { log_error "Cannot access Panel directory"; return 1; }
    
    # Install dependencies
    log_step "Installing Dependencies"
    log_info "Running: npm install"
    if ! npm install --quiet --no-progress >> "$LOG_FILE" 2>&1; then
        log_error "npm install failed"
        return 1
    fi
    log_success "Dependencies installed"
    
    # Configuration
    log_step "Configuring Panel"
    if [[ -f "example_config.json" ]]; then
        cp example_config.json config.json
        log_info "Created config.json from example"
    else
        log_warning "No example config found. Creating minimal config..."
        cat > config.json << EOF
{
    "database": {
        "host": "localhost",
        "port": 3306,
        "name": "skyport",
        "user": "skyport_user",
        "password": "change_this_password"
    },
    "panel": {
        "host": "0.0.0.0",
        "port": 8080,
        "ssl": false
    }
}
EOF
    fi
    
    # Database setup
    log_step "Setting Up Database"
    log_info "Seeding database..."
    if ! npm run seed >> "$LOG_FILE" 2>&1; then
        log_warning "Database seeding may have failed. Check database configuration."
    fi
    
    # Create admin user
    log_step "Creating Admin Account"
    log_info "Run the following command after installation to create admin user:"
    echo -e "${YELLOW}    cd ${PANEL_DIR} && npm run createUser${NC}"
    
    # Create systemd service
    log_step "Creating System Service"
    cat > /etc/systemd/system/skyport-panel.service << EOF
[Unit]
Description=Skyport Panel - Game Server Control Panel
Documentation=https://github.com/skyport-team/panel
After=network.target docker.service
Wants=network-online.target docker.service
Requires=docker.socket

[Service]
Type=simple
User=root
WorkingDirectory=${PANEL_DIR}
ExecStart=/usr/bin/npm start
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=skyport-panel
Environment=NODE_ENV=production

# Security
NoNewPrivileges=true
ProtectSystem=strict
PrivateTmp=true
PrivateDevices=true
ProtectHome=true
ReadWritePaths=${PANEL_DIR}

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload and enable service
    systemctl daemon-reload >> "$LOG_FILE" 2>&1
    systemctl enable skyport-panel.service >> "$LOG_FILE" 2>&1
    
    # Final instructions
    log_header "PANEL INSTALLATION COMPLETE"
    cat << EOF
${GREEN}✅ Skyport Panel has been successfully installed!${NC}

📁 ${CYAN}Installation Directory:${NC} ${PANEL_DIR}
⚙️  ${CYAN}Configuration File:${NC}    ${PANEL_DIR}/config.json
🎛️  ${CYAN}Systemd Service:${NC}       skyport-panel.service

${YELLOW}🔧 NEXT STEPS:${NC}
1. Edit the configuration file:
   ${DIM}sudo nano ${PANEL_DIR}/config.json${NC}

2. Configure your database settings

3. Create an admin user:
   ${DIM}cd ${PANEL_DIR} && npm run createUser${NC}

4. Start the Panel:
   ${DIM}sudo systemctl start skyport-panel${NC}

5. Check status:
   ${DIM}sudo systemctl status skyport-panel${NC}

6. View logs:
   ${DIM}sudo journalctl -u skyport-panel -f${NC}

${BLUE}🌐 Default URL:${NC} http://your-server-ip:8080
${BLUE}📋 Log File:${NC} ${LOG_FILE}
EOF
}

# =============================================================================
# 🚀 WINGS INSTALLATION
# =============================================================================
install_wings() {
    log_header "INSTALLING SKYPORT WINGS"
    
    check_system
    install_prerequisites
    
    # Check for existing installation
    if [[ -d "$WINGS_DIR" ]]; then
        log_warning "Wings directory '${WINGS_DIR}' already exists"
        read -rp "Overwrite existing installation? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Wings installation cancelled"
            return 1
        fi
        log_info "Removing existing installation..."
        rm -rf "$WINGS_DIR"
    fi
    
    # Clone repository
    log_step "Downloading Skyport Wings"
    log_info "Cloning from: $WINGS_REPO"
    if ! git clone --depth 1 "$WINGS_REPO" "$WINGS_DIR" >> "$LOG_FILE" 2>&1; then
        log_error "Failed to clone Wings repository"
        return 1
    fi
    cd "$WINGS_DIR" || { log_error "Cannot access Wings directory"; return 1; }
    
    # Install dependencies
    log_step "Installing Dependencies"
    log_info "Running: npm install"
    if ! npm install --quiet --no-progress >> "$LOG_FILE" 2>&1; then
        log_error "npm install failed"
        return 1
    fi
    log_success "Dependencies installed"
    
    # Configuration
    log_step "Configuring Wings"
    if [[ -f "example_config.json" ]]; then
        cp example_config.json config.json
        log_info "Created config.json from example"
    else
        log_warning "No example config found. Creating minimal config..."
        cat > config.json << EOF
{
    "panel_url": "https://your-panel-domain.com",
    "node_token": "your_node_token_here",
    "node": {
        "name": "$(hostname)",
        "location": "default",
        "port": 8080
    }
}
EOF
    fi
    
    # Create systemd service
    log_step "Creating System Service"
    cat > /etc/systemd/system/skyport-wings.service << EOF
[Unit]
Description=Skyport Wings - Game Server Node
Documentation=https://github.com/skyport-team/skyportd
After=network.target docker.service
Wants=network-online.target
Requires=docker.socket

[Service]
Type=simple
User=root
WorkingDirectory=${WINGS_DIR}
ExecStart=/usr/bin/node index.js
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=skyport-wings
Environment=NODE_ENV=production

# Security
NoNewPrivileges=true
ProtectSystem=strict
PrivateTmp=true
PrivateDevices=true
ProtectHome=true
ReadWritePaths=${WINGS_DIR}

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload and enable service
    systemctl daemon-reload >> "$LOG_FILE" 2>&1
    systemctl enable skyport-wings.service >> "$LOG_FILE" 2>&1
    
    # Final instructions
    log_header "WINGS INSTALLATION COMPLETE"
    cat << EOF
${GREEN}✅ Skyport Wings has been successfully installed!${NC}

📁 ${CYAN}Installation Directory:${NC} ${WINGS_DIR}
⚙️  ${CYAN}Configuration File:${NC}    ${WINGS_DIR}/config.json
🎛️  ${CYAN}Systemd Service:${NC}       skyport-wings.service

${YELLOW}🔧 NEXT STEPS:${NC}
1. Edit the configuration file:
   ${DIM}sudo nano ${WINGS_DIR}/config.json${NC}

2. Set your Panel URL and Node Token
   (Get token from your Skyport Panel)

3. Start Wings:
   ${DIM}sudo systemctl start skyport-wings${NC}

4. Check status:
   ${DIM}sudo systemctl status skyport-wings${NC}

5. View logs:
   ${DIM}sudo journalctl -u skyport-wings -f${NC}

${BLUE}🔗 Panel Connection:${NC} Ensure Wings can reach your Panel URL
${BLUE}📋 Log File:${NC} ${LOG_FILE}
EOF
}

# =============================================================================
# 🏗️ SHOW MENU
# =============================================================================
show_menu() {
    clear
    echo -e "${MAGENTA}${BOLD}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║     ███████╗██╗  ██╗██╗   ██╗██████╗  ██████╗ ██████╗ ████████╗             ║
║     ██╔════╝██║ ██╔╝╚██╗ ██╔╝██╔══██╗██╔═══██╗██╔══██╗╚══██╔══╝             ║
║     ███████╗█████╔╝  ╚████╔╝ ██████╔╝██║   ██║██████╔╝   ██║                ║
║     ╚════██║██╔═██╗   ╚██╔╝  ██╔═══╝ ██║   ██║██╔══██╗   ██║                ║
║     ███████║██║  ██╗   ██║   ██║     ╚██████╔╝██║  ██║   ██║                ║
║     ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝      ╚═════╝ ╚═╝  ╚═╝   ╚═╝                ║
║                                                                              ║
║               🚀 Professional Game Server Management 🎮                      ║
║                      by KS Hosting / KSGaming                               ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo -e "${CYAN}${BOLD}Installation Menu${NC}"
    echo -e "${MINI_HR}"
    echo -e "${BOLD}1) 💻 Install Skyport Panel${NC}"
    echo -e "   ${DIM}Complete control panel with web interface${NC}"
    echo
    echo -e "${BOLD}2) 🚀 Install Skyport Wings${NC}"
    echo -e "   ${DIM}Game server node daemon${NC}"
    echo
    echo -e "${BOLD}3) 📊 System Requirements${NC}"
    echo -e "   ${DIM}Check system compatibility${NC}"
    echo
    echo -e "${BOLD}4) 📋 View Installation Log${NC}"
    echo -e "   ${DIM}Check detailed installation log${NC}"
    echo
    echo -e "${BOLD}5) 🚪 Exit${NC}"
    echo -e "${MINI_HR}"
}

# =============================================================================
# 📋 VIEW LOG
# =============================================================================
view_log() {
    log_header "INSTALLATION LOG"
    if [[ -f "$LOG_FILE" ]]; then
        echo -e "${DIM}Showing last 50 lines of log. Full log: ${LOG_FILE}${NC}\n"
        tail -50 "$LOG_FILE"
    else
        log_info "No log file found yet"
    fi
    
    read -rp "Press Enter to continue..."
}

# =============================================================================
# 🏁 MAIN EXECUTION
# =============================================================================
main() {
    # Initialize log
    echo "=== Skyport Installation Started $(date) ===" > "$LOG_FILE"
    echo "User: $(whoami)" >> "$LOG_FILE"
    echo "System: $(uname -a)" >> "$LOG_FILE"
    
    # Check root
    check_root
    
    # Main loop
    while true; do
        show_menu
        echo
        read -rp "$(echo -e "${CYAN}👉 Select option [1-5]: ${NC}")" choice
        
        case $choice in
            1)
                install_panel
                echo
                read -rp "$(echo -e "${YELLOW}⏎ Press Enter to return to menu...${NC}")" _
                ;;
            2)
                install_wings
                echo
                read -rp "$(echo -e "${YELLOW}⏎ Press Enter to return to menu...${NC}")" _
                ;;
            3)
                log_header "SYSTEM REQUIREMENTS"
                check_system
                echo
                read -rp "$(echo -e "${YELLOW}⏎ Press Enter to continue...${NC}")" _
                ;;
            4)
                view_log
                ;;
            5)
                log_header "THANK YOU"
                echo -e "${GREEN}Thank you for choosing Skyport!${NC}\n"
                echo -e "${DIM}Installation log: ${LOG_FILE}${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid selection. Please choose 1-5${NC}"
                sleep 1
                ;;
        esac
    done
}

# =============================================================================
# 🚀 START SCRIPT
# =============================================================================

# Handle script interrupts
trap 'echo -e "\n${RED}⚠️ Installation interrupted!${NC}"; exit 1' INT TERM

# Run main function
main
