# Magic Mirror 2 Automated Installation Script

## Overview

Create a bash installation script that sets up Magic Mirror 2 on a fresh Raspberry Pi OS install using configuration and modules from a specified directory.

## Requirements

### Script Behavior

- **Input**: Single argument - path to directory containing config and modules (might be cloned from GitHub or pulled from USB drive - location doesn't matter)
- **Execution**: The script should be designed to be ran as `sudo ./scripts/install.sh`
- **Scope**: Handle complete setup from bare OS to running Magic Mirror

### Installation Steps

1. Install Node.js (latest LTS version appropriate for Raspberry Pi)
1. Install emoi icons (see https://docs.magicmirror.builders/configuration/raspberry.html)
1. Install Magic Mirror 2 to standard location (e.g., `$HOME/MagicMirror`)
1. Copy `config.js` from input to Magic Mirror's config directory
1. Copy all modules from input modules subdirectory into Magic Mirror's modules directory
1. Install npm dependencies for all modules
1. Install pm2 globally
1. Create pm2 ecosystem configuration file to start Magic Mirror at boot
1. Save pm2 configuration to startup
1. Enable plymouth bgrt theme: `sudo plymouth-set-default-theme -R bgrt`
1. Verify installation by checking Magic Mirror starts successfully

### Error Handling

- Validate input path exists and contains required files (config.js and modules directory)
- Check for sufficient disk space before installation
- Provide clear error messages if any step fails
- Stop execution on critical errors

### Output

- Clear status messages throughout installation
- Summary of completed steps
- Instructions for verifying Magic Mirror is running

## Technical Details

- Magic Mirror 2 should run under a non-root user
- Use pm2 to manage the process with auto-restart on failure
- Ensure pm2 startup hook is properly configured for boot
- Handle case where Magic Mirror may already be partially installed

## Reference Documentation

Be sure to read all documentation before starting on the implementation.

- Installation Guide: https://docs.magicmirror.builders/getting-started/installation.html
- Configuration Guide: https://docs.magicmirror.builders/configuration/introduction.html
- Autostart Guide: https://docs.magicmirror.builders/configuration/autostart.html
- Modules Docs: https://docs.magicmirror.builders/modules/introduction.html

## Future

- Disable booting to LXDE, instead use custom X startup script (replace pm2 configuration)
