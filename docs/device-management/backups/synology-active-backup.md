---
description: >-
  PowerShell script to silently install the latest Synology Active Backup for
  Business agent.
layout:
  title:
    visible: true
  description:
    visible: true
  tableOfContents:
    visible: true
  outline:
    visible: true
  pagination:
    visible: true
---

# Synology Active Backup

## Overview

{% hint style="info" %}
**Dev Insight:** This script can also be used to update or reconfigure the Synology Active Backup for business agent.
{% endhint %}

The software applications available for Synology devices can be pretty powerful. One of my favorites, especially for internal IT, is Active Backup for Business (ABB).

<figure><img src="../../.gitbook/assets/activebackup_1607392921_1.png" alt=""><figcaption></figcaption></figure>

**From their** [**Administrator's Guide**](https://global.synologydownload.com/download/Document/Software/AdminGuide/Package/ActiveBackup/All/enu/Synology\_ABB\_admin\_guide\_Windows\_PC\_PS\_enu.pdf)**:**

> ABB centralizes data protection across a variety of IT environments, including virtual machines, physical servers, file servers, and personal computers. Administrators can deploy their preferred protection plan single-handedly through ABB's centralized admin console.&#x20;
>
> ABB also offers a wide range of backup options and restoration tools, as well as a number of optional technical and safety features.

{% embed url="https://www.synology.com/en-global/dsm/feature/active-backup-business/overview" %}

This script eases the deployment of the backup agent for Windows devices by silently downloading, installing, and configuring the agent on a device.

**Prerequisites:**

1. Setup Active Backup for Business on your Synology NAS.
2. Create a user account to authenticate the agent.
3. Configure your default backup tasks.

***

## Script

{% @github-files/github-code-block url="https://github.com/redletterone/PowerShell/blob/main/scripts/InstallSynologyActiveBackup.ps1" %}

## Examples

```powershell
.\InstallSynologyActiveBackup.ps1 -Address "localhost" -Username "Backups" -Pass "Da ba dee da ba di"
```

This example downloads, installs, and configures the latest version of Synology Active Backup for Business agent.&#x20;



***

## Parameters

`-Address`

**Aliases:** `-Host`, `-Hostname`, `-IP`

Required string paramter that allows passing the hostname or IP address of the Synology device.



`-Username`

**Aliases:** `-User`

Required string parameter that allows you to pass the username required to authenticate with the Synology device.



`-Pass`

**Aliases:** `-Password`

Required string parameter that allows you to pass the password required to authenticate with the Synology device.

