---
description: PowerShell script to silently install Bluebeam Revu (v21+).
---

# Bluebeam Revu

## Overview

{% hint style="info" %}
**Dev Insight:** While this script is intended for new installs of Bluebeam Revu, it can also be used to update existing Bluebeam Revu installations to the latest version.
{% endhint %}

This script downloads and installs the latest version of Bluebeam Revu.&#x20;

**Prerequisites:** This script has no prerequisites.&#x20;

**Notes:**

* This script will not license Bluebeam. A licensed user will need to login after installation.
* Script will abort if a perpetually licensed (legacy) version of Bluebeam Revu is detected.
* Script will abort if Bluebeam Revu is currently running to avoid potential data loss.

***

## Script

{% @github-files/github-code-block url="https://github.com/redletterone/PowerShell/blob/main/scripts/InstallBluebeamRevu.ps1" %}

## Examples

```powershell
.\InstallBluebeamRevu.ps1
```

This example downloads and installs the latest version of Bluebeam Revu.

***

## Parameters

This script has no parameters.

***

## Links

{% embed url="https://www.bluebeam.com/" %}
