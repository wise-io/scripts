---
description: PowerShell script to silently update Microsoft Store applications.
---

# Microsoft Store Applications

## Overview

{% hint style="info" %}
**Dev Insight:** Are you annoyed that Windows Update doesn't update Microsoft Store applications? I was too.
{% endhint %}

This script allows you to set Microsoft Store applications to update automatically and also initiates on-demand update scans.

**Prerequisites:** This script has no prerequisites.&#x20;

***

## Script

{% @github-files/github-code-block url="https://github.com/wise-io/scripts/blob/main/scripts/UpdateMicrosoftStoreApps.ps1" %}

## Examples

### Example 1

```powershell
.\UpdateMicrosoftStoreApps.ps1
```

This example initiates a scan for Microsoft Store application updates and applies them.

### Example 2

```powershell
.\UpdateMicrosoftStoreApps.ps1 -AutoUpdate
```

This example enables automatic updates for Microsoft Store applications. It then initiates a scan for updates and applies them.

***

## Parameters

`-AutoUpdate`

Optional switch parameter that enables automatic updates for Microsoft Store applications.
