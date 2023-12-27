---
description: PowerShell script to silently install and run Dell Command Update (DCU).
---

# Dell Command Update

## Overview

{% hint style="info" %}
**Dev Insight:** This script was originally written to make sure devices deployed during our MDT process had the latest drivers/firmware from Dell, but it can also be used to update Dell devices already deployed via your RMM of choice.
{% endhint %}

This script downloads and installs the latest version of Dell Command Update (DCU) if not already installed. It will then use `dcu-cli.exe` to download and install all Dell driver/firmware updates, ignoring reboots.

{% embed url="https://www.dell.com/support/manuals/en-us/command-update/dellcommandupdate_rg" %}

**Prerequisites:** This script has no prerequisites.&#x20;

**Notes:**

* Script will abort if a PC manufacturer other than Dell is detected.
* Incompatible products, such as Dell Update, will be removed if detected.
* Dell Command Update will not work for Dell servers.

***

## Script

{% hint style="info" %}
Script will abort if a PC manufacturer other than Dell is detected.
{% endhint %}

{% @github-files/github-code-block %}

## Examples

```powershell
.\UpdateDell.ps1
```

This example downloads and installs Dell Command Update if it isn't already installed. After installation, Dell Command Update will check for and install any Dell updates.

***

## Parameters

This script has no parameters.
