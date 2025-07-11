---
description: PowerShell script to silently install and run Dell Command Update (DCU).
---

# Dell Command Update

## Overview

{% hint style="info" %}
**Dev Insight:** This script was originally written to make sure devices deployed during our MDT process had the latest drivers/firmware from Dell, but it can also be used to update Dell devices already deployed via your RMM of choice.
{% endhint %}

This script downloads and installs the latest version of Dell Command Update (DCU) if not already installed. It will then use `dcu-cli.exe` to download and install all Dell driver/firmware updates, ignoring reboots.

{% embed url="https://www.dell.com/support/product-details/en-us/product/command-update/resources/manuals" %}

**Prerequisites:** This script has no prerequisites.&#x20;

**Notes:**

* Script will abort if a PC manufacturer other than Dell is detected.
* Dell Update, which is incompatible with Dell Command Update, will be removed if detected.
* .NET Desktop Runtime, a prerequisite to Dell Command Update 5.5+, will be updated / installed to the latest LTS release if not already installed.&#x20;
* Dell Command Update is not intended for use with server hardware. Use Dell System Update instead.

***

## Script

{% hint style="info" %}
Script will abort if a system manufacturer other than Dell is detected.
{% endhint %}

{% @github-files/github-code-block url="https://github.com/wise-io/scripts/blob/main/scripts/DellCommandUpdate.ps1" %}

## Examples

```powershell
.\DellCommandUpdate.ps1
```

This example downloads and installs Dell Command Update if it isn't already installed. After installation, Dell Command Update will check for and install any Dell updates.



```
.\DellCommandUpdate.ps1 -Reboot
```

This example downloads and installs Dell Command Update if it isn't already installed. After installation, Dell Command Update will check for and install any Dell updates. Once complete, a message will be displayed, and a reboot will be forced after 60 seconds.

***

## Parameters

`-Reboot`

Switch parameter - if specified, notifies the user and forces a reboot after 60 seconds.
