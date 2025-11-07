# Installation

## Operating System

Install Raspberry Pi OS using Raspberry Pi Imager. Configure hostname, username, password, wireless LAN, locale, enable SSH, and add SSH public key.

## Automated MagicMirror Installation

Run the installation script:

```bash
sudo ./scripts/install.sh /path/to/config/directory
```

Example configuration files are in the `example/` directory - see [here](https://github.com/kwila-cloud/family-dashboard/example).

To try out the example configuration:

```bash
sudo ./scripts/install.sh example/
```

The script installs dependencies, MagicMirror, modules from `modules.json`, and configures autostart.

## Post-Installation

Useful commands:

- Check status: `pm2 status`
- View logs: `pm2 logs magicmirror`
- Restart: `pm2 restart magicmirror`
- Stop: `pm2 stop magicmirror`

The service automatically starts on boot.
