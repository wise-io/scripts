---
description: PowerShell script to silently install Windows updates.
---

# Windows Updates

## Overview

{% hint style="info" %}
**Dev Insight:** This script was extremely useful when patching for [CVE-2020-23397](https://msrc.microsoft.com/update-guide/vulnerability/CVE-2023-23397).
{% endhint %}

This script uses the [PSWindowsUpdate](https://www.powershellgallery.com/packages/PSWindowsUpdate) module to apply Windows updates silently, ignoring reboots.

{% embed url="https://www.powershellgallery.com/packages/PSWindowsUpdate" %}

**Prerequisites:** This script has no prerequisites.&#x20;

***

## Script

{% @github-files/github-code-block url="https://github.com/redletterone/PowerShell/blob/main/scripts/UpdateWindows.ps1" %}

## Examples

```powershell
.\UpdateWindows.ps1
```

This example installs the `PSWindowsUpdate` module, checks for all Windows updates and installs them. Reboots are ignored.

***

## Parameters

This script has no parameters.
