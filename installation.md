# Installation

## Operating System

Install raspberry pi imager, then select device and storage. Select the latest full version of Raspberry Pi OS.

### Settings

Edit the following settings:

- hostname
- username
- password
- wireless LAN
- locale
- enable SSH
- add SSH public key

## Install MagicMirror

> [!NOTE]
> We are working on custom install script.
> See here: https://github.com/kwila-cloud/family-dashboard/pull/1

Follow the steps here:

https://docs.magicmirror.builders/getting-started/installation.html

### Install Node

The `nodejs` in the official repos is too old for Magic Mirro.

Instead, we need at least the most recent LTS version.

From https://gist.github.com/stonehippo/f4ef8446226101e8bed3e07a58ea512a#install-with-apt-using-nodesource-binary-distribution

```sh
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - &&\
sudo apt-get install -y nodejs
```

## Setup Autostart

See https://docs.magicmirror.builders/configuration/autostart.html#using-pm2

## Install Calendar Module

The built-in calendar module doesn't show a traditional monthly calendar.
We can use this third-party module.

https://github.com/MMM-CalendarExt2/MMM-CalendarExt2?tab=readme-ov-file#installation
