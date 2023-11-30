---
description: >-
  PowerShell script to silently install the latest Synology Active Backup for
  Business agent.
---

# Synology Active Backup

## Overview

{% hint style="info" %}
**Dev Insight:** This script can also be used to update or reconfigure the Synology Active Backup for business agent.
{% endhint %}

Synology NAS devices offer a built-in option for device backups known as Active Backup for Business. It can be used to manage backup tasks for physical and virtual environments from a centralized dashboard to keep data and services always available.

This script eases the deployment of the backup agent for Windows devices by silently downloading, installing, and configuring the agent on a device.

{% embed url="https://www.synology.com/en-global/dsm/feature/active-backup-business/overview" %}

**Prerequisites:**

1. Setup Active Backup for Business on your Synology NAS.
2. Create a user account to authenticate the agent.
3. Configure your default backup tasks.

***

## Script

{% @github-files/github-code-block url="https://github.com/redletterone/PowerShell/blob/main/scripts/InstallSynologyActiveBackup.ps1" %}

## Examples

### Example 1

```powershell
.\InstallSynologyActiveBackup.ps1 -Address "localhost" -Username "Backups" -Pass "Da ba dee da ba di"
```

This example downloads, installs, and configures the latest version of Synology Active Backup for Business agent.&#x20;



***

## Parameters

### Required Parameters

`-Address`

**Aliases:** `-Host`, `-Hostname`, `-IP`

The hostname or IP address of the Synology Active Backup for Business server.



`-Username`

**Aliases:** `-User`

The username used to authenticate with the Synology Active Backup for Business server.



`-Pass`

**Aliases:** `-Password`

The password used to authenticate with the Synology Active Backup for Business server.

