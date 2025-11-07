#!/usr/bin/env bash
# This script is designed to be ran interactively on a fresh install of Raspberry Pi OS.
# See install.md for more information.
set -euo pipefail

# Force non-interactive apt operations
# Note: While this script requires interactive shell input (verified below),
# apt package installations must run in non-interactive mode to prevent
# hanging on configuration prompts during automated installation
export DEBIAN_FRONTEND=noninteractive

# Magic Mirror 2 Automated Installation Script
# Must be run via sudo from a regular user account on Raspberry Pi

# Check if running on Raspberry Pi
if [ ! -f /proc/device-tree/model ] || ! grep -qi "raspberry pi" /proc/device-tree/model 2>/dev/null; then
    cat >&2 <<'EOF'
ERROR: This script is designed specifically for Raspberry Pi hardware.
Magic Mirror 2 is optimized for the Raspberry Pi display and hardware.

This installation script has detected that you are not running on a Raspberry Pi.
For installations on other systems, please follow the official Magic Mirror
installation guide: https://docs.magicmirror.builders/getting-started/installation.html
EOF
    exit 1
fi

# Force interactive use only - exit early if not interactive shell
if [ ! -t 0 ] || [ -n "${CI:-}" ] || [ -n "${AUTOMATION:-}" ]; then
    cat >&2 <<'EOF'
ERROR: This script requires an interactive shell and cannot be run in automated environments.
Magic Mirror 2 installation requires manual supervision and user input.

For automated installations, consider using a pre-configured system image or
manual installation following: https://docs.magicmirror.builders/getting-started/installation.html

If you believe this detection is incorrect, ensure you are running this
script directly from a terminal session and not through automation tools.
EOF
    exit 1
fi

# STRICT: Must be run via sudo so we can determine the target non-root user
if [ "$(id -u)" -eq 0 ] && [ -z "${SUDO_USER:-}" ]; then
  cat >&2 <<'EOF'
ERROR: This script must be run via sudo from a regular user account.
Example usage:
  sudo ./scripts/install.sh /path/to/config

Do NOT run directly as root. The script will automatically determine the 
correct user from SUDO_USER and set up permissions, pm2, and MagicMirror 
for that user.
EOF
  exit 1
fi

# Now we know SUDO_USER is set (or we're not root, which we want to avoid)
if [ -n "${SUDO_USER:-}" ]; then
  MM_USER="$SUDO_USER"
else
  echo "ERROR: Script must be run via sudo from a regular user account." >&2
  exit 1
fi

# Resolve target user's home directory
MM_HOME="$(getent passwd "$MM_USER" | cut -d: -f6)"
if [ -z "$MM_HOME" ]; then
  echo "ERROR: Cannot determine home directory for user: $MM_USER" >&2
  exit 1
fi

MM_DIR="$MM_HOME/MagicMirror"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Error handler
error_exit() {
    log_error "$1"
    exit 1
}

log_info "Starting Magic Mirror 2 installation for user: $MM_USER (home: $MM_HOME)"

# Validate input arguments
if [ $# -ne 1 ]; then
    error_exit "Usage: $0 /path/to/config"
fi

SOURCE_DIR="$1"

# Validate source directory
if [ ! -d "$SOURCE_DIR" ]; then
    error_exit "Source directory does not exist: $SOURCE_DIR"
fi

if [ ! -f "$SOURCE_DIR/config.js" ]; then
    error_exit "config.js not found in source directory: $SOURCE_DIR"
fi

if [ ! -f "$SOURCE_DIR/modules.json" ]; then
    error_exit "modules.json not found in source directory: $SOURCE_DIR"
fi

log_success "Source directory validation passed"

# Check available disk space (require at least 2GB)
AVAILABLE_KB=$(df --output=avail -k "$MM_HOME" | tail -1)
AVAILABLE_MB=$((AVAILABLE_KB / 1024))
if [ $AVAILABLE_MB -lt 2048 ]; then
    error_exit "Insufficient disk space. Available: ${AVAILABLE_MB}MB, Required: 2048MB"
fi
log_success "Disk space check passed (${AVAILABLE_MB}MB available)"

# Update system packages
log_info "Updating system packages..."
apt update -qq || error_exit "Failed to update package lists"
log_success "System packages updated"

# Install required system packages
log_info "Installing system prerequisites..."
apt install -y -q curl git build-essential libasound2-plugins xserver-xorg x11-xserver-utils xinit wget jq || error_exit "Failed to install system prerequisites"
log_success "System prerequisites installed"

# Install Node.js LTS
log_info "Installing Node.js LTS..."
if command -v node >/dev/null 2>&1; then
    log_warning "Node.js already installed: $(node --version)"
else
    # Download NodeSource setup script for inspection
    TEMP_SCRIPT=$(mktemp)
    log_info "Downloading NodeSource setup script..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x -o "$TEMP_SCRIPT" || error_exit "Failed to download NodeSource setup script"

    # Execute the downloaded script (already running as root via sudo)
    log_info "Executing NodeSource setup script..."
    bash "$TEMP_SCRIPT" || error_exit "Failed to setup NodeSource repository"

    # Clean up temporary file
    rm -f "$TEMP_SCRIPT"

    apt install -y nodejs || error_exit "Failed to install Node.js"
    log_success "Node.js $(node --version) installed"
fi

# Install npm if not present
if ! command -v npm >/dev/null 2>&1; then
    apt install -y -q npm || error_exit "Failed to install npm"
    log_success "npm installed"
fi

# Install emoi icons
log_info "Installing emoji fonts..."
apt install -y -q fonts-noto-color-emoji || log_warning "Failed to install emoji fonts (continuing anyway)"
log_success "Emoji fonts installation completed"

# Install Magic Mirror 2
if [ -d "$MM_DIR" ]; then
    log_warning "Magic Mirror directory already exists: $MM_DIR"
    read -p "Do you want to backup and reinstall? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo -u "$MM_USER" mv "$MM_DIR" "${MM_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Backed up existing installation"
    else
        log_warning "Continuing with existing installation"
    fi
else
    # Ensure PATH includes npm global bin
    echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$MM_HOME/.bashrc"
fi

if [ ! -d "$MM_DIR" ]; then
    log_info "Cloning Magic Mirror repository..."
    sudo -u "$MM_USER" git clone https://github.com/MichMich/MagicMirror.git "$MM_DIR" || error_exit "Failed to clone Magic Mirror repository"
    log_success "Magic Mirror repository cloned"
fi

log_info "Installing Magic Mirror dependencies..."
sudo -u "$MM_USER" bash -lc "cd '$MM_DIR' && npm install --production" || error_exit "Failed to install Magic Mirror dependencies"
log_success "Magic Mirror dependencies installed"

# Copy configuration
log_info "Copying configuration files..."
cp "$SOURCE_DIR/config.js" "$MM_DIR/config/config.js" || error_exit "Failed to copy config.js"
chown "$MM_USER:$MM_USER" "$MM_DIR/config/config.js" || error_exit "Failed to set config.js ownership"
log_success "Configuration files copied"

# Copy modules
log_info "Setting up modules directory..."
if [ -d "$MM_DIR/modules" ]; then
    rm -rf "$MM_DIR/modules" || error_exit "Failed to remove existing modules directory"
fi
sudo -u "$MM_USER" mkdir -p "$MM_DIR/modules" || error_exit "Failed to create modules directory"
chown -R "$MM_USER:$MM_USER" "$MM_DIR/modules" || error_exit "Failed to set modules ownership"
log_success "Modules directory created"

# Install modules from modules.json
if [ -f "$SOURCE_DIR/modules.json" ]; then
    log_info "Installing modules from modules.json..."
    MODULE_COUNT=0
    
    # Use jq to get module names and URLs
    mapfile -t module_names < <(jq -r 'keys[]' "$SOURCE_DIR/modules.json")
    
    for module_name in "${module_names[@]}"; do
        if [ -n "$module_name" ]; then
            log_info "Installing module: $module_name"
            git_url=$(jq -r ".\"$module_name\"" "$SOURCE_DIR/modules.json")
            
            if [ -n "$git_url" ] && [ "$git_url" != "null" ]; then
                MODULE_DIR="$MM_DIR/modules/$module_name"
                
                cd "$MM_DIR/modules" || error_exit "Failed to change to modules directory"
                sudo -u "$MM_USER" git clone --depth=1 "$git_url" "$module_name" || log_warning "Failed to clone $module_name"
                
                if [ -d "$MODULE_DIR" ] && [ -f "$MODULE_DIR/package.json" ]; then
                    cd "$MODULE_DIR" || error_exit "Failed to change to module directory"
                    sudo -u "$MM_USER" npm ci --omit=dev || log_warning "Failed to install dependencies for $module_name"
                    MODULE_COUNT=$((MODULE_COUNT + 1))
                fi
            fi
        fi
    done
    log_success "Installed $MODULE_COUNT modules from modules.json"
else
    log_warning "modules.json not found, skipping module installation"
fi

# Install pm2 globally for target user
log_info "Installing PM2 process manager..."
if ! sudo -u "$MM_USER" command -v pm2 >/dev/null 2>&1; then
    # Configure npm to use user-local directory for global packages
    sudo -u "$MM_USER" npm config set prefix "$MM_HOME/.npm-global" || error_exit "Failed to configure npm prefix"
    
    # Install PM2 using the configured prefix
    sudo -u "$MM_USER" npm install -g pm2 || error_exit "Failed to install PM2"
    
    # Ensure PM2 is in PATH for the target user
    sudo -u "$MM_USER" bash -lc 'export PATH="$HOME/.npm-global/bin:$PATH" && pm2 --version' || error_exit "PM2 not accessible to target user"
    log_success "PM2 installed for user $MM_USER"
else
    log_warning "PM2 already installed for user $MM_USER: $(sudo -u "$MM_USER" pm2 --version)"
fi

# Create PM2 ecosystem configuration
log_info "Creating PM2 ecosystem configuration..."
cat > "$MM_DIR/ecosystem.config.js" <<EOF
module.exports = {
  apps: [{
    name: 'magicmirror',
    script: 'npm',
    args: 'start',
    cwd: '$MM_DIR',
    env: {
      NODE_ENV: 'production',
      PATH: '/usr/local/bin:/usr/bin:/bin',
      PM2_DISPLAY_NAME: 'MagicMirror'
    },
    restart_delay: 4000,
    max_restarts: 10,
    min_uptime: '10s',
    max_memory_restart: '512M',
    error_file: '$MM_DIR/logs/pm2-error.log',
    out_file: '$MM_DIR/logs/pm2-out.log',
    log_file: '$MM_DIR/logs/pm2-combined.log',
    time: true
  }]
};
EOF

sudo chown "$MM_USER:$MM_USER" "$MM_DIR/ecosystem.config.js" || error_exit "Failed to set ecosystem config ownership"

# Create logs directory
sudo -u "$MM_USER" mkdir -p "$MM_DIR/logs" || error_exit "Failed to create logs directory"

log_success "PM2 ecosystem configuration created"

# Start Magic Mirror with PM2
log_info "Starting Magic Mirror with PM2..."
sudo -u "$MM_USER" bash -lc "cd '$MM_DIR' && export PATH='$HOME/.npm-global/bin:$PATH' && pm2 start '$MM_DIR/ecosystem.config.js'" || error_exit "Failed to start Magic Mirror with PM2"
sudo -u "$MM_USER" bash -lc "export PATH='$HOME/.npm-global/bin:$PATH' && pm2 save" || log_warning "Failed to save PM2 process list"
log_success "Magic Mirror started with PM2"

# Configure PM2 startup
log_info "Configuring PM2 startup..."
# Use explicit pm2 startup command to avoid unsafe eval
PM2_STARTUP_OUTPUT=$(pm2 startup systemd -u "$MM_USER" --hp "$MM_HOME" 2>&1 || true)
if echo "$PM2_STARTUP_OUTPUT" | grep -q "successfully"; then
    log_success "PM2 startup configuration completed"
else
    log_warning "PM2 startup configuration may have issues: $PM2_STARTUP_OUTPUT"
fi

# Enable Plymouth bgrt theme
log_info "Enabling Plymouth bgrt theme..."
if sudo plymouth-set-default-theme -l | grep -q bgrt; then
    sudo plymouth-set-default-theme -R bgrt || log_warning "Failed to set Plymouth bgrt theme"
    log_success "Plymouth bgrt theme enabled"
else
    log_warning "bgrt theme not available, skipping Plymouth configuration"
fi

# Verify installation
log_info "Verifying installation..."

# Check if PM2 process is running
if sudo -u "$MM_USER" pm2 list | grep -q "magicmirror.*online"; then
    log_success "Magic Mirror process is running"
else
    log_error "Magic Mirror process is not running"
    sudo -u "$MM_USER" pm2 logs magicmirror --lines 10
    exit 1
fi

# Show final status
log_info "Installation Summary:"
echo "  User: $MM_USER"
echo "  Magic Mirror Directory: $MM_DIR"
echo "  PM2 Process: magicmirror"
echo "  Log Files: $MM_DIR/logs/"
echo ""

# Display useful commands
log_info "Useful commands:"
echo "  Check status:    pm2 status"
echo "  View logs:       pm2 logs magicmirror"
echo "  Restart:         pm2 restart magicmirror"
echo "  Stop:            pm2 stop magicmirror"
echo "  View logs file:  tail -f $MM_DIR/logs/pm2-combined.log"
echo ""

log_success "Magic Mirror 2 installation completed successfully!"
log_info "The Magic Mirror service should start automatically on system boot."
log_info "You can check the status with: pm2 status"
