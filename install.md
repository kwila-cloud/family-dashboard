# Installation

## Operating System

Install Raspberry Pi OS using Raspberry Pi Imager. Configure hostname, username, password, wireless LAN, locale, enable SSH, and add SSH public key.

## Automated MagicMirror Installation

Run the installation script:

```bash
sudo ./scripts/install.sh /path/to/config/directory
```

Configuration files are in the `example/` directory: https://github.com/kwila-cloud/family-dashboard

The script installs dependencies, MagicMirror, modules from `modules.json`, and configures autostart.

## Post-Installation

Useful commands:

- Check status: `sudo -u <username> pm2 status`
- View logs: `sudo -u <username> pm2 logs magicmirror`
- Restart: `sudo -u <username> pm2 restart magicmirror`
- Stop: `sudo -u <username> pm2 stop magicmirror`

The service automatically starts on boot.
