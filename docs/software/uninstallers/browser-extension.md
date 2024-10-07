---
description: PowerShell script to silently remove a browser extension by ID.
---

# Browser Extension

## Overview

{% hint style="info" %}
**Dev Insight:** This script was created in tandem with the [browser extension installation script](https://scripts.aaronjstevenson.com/software/installers/browser-extension).
{% endhint %}

This script removes a Microsoft Edge or Google Chrome extension for all user / browser profiles on a device.&#x20;

{% embed url="https://learn.microsoft.com/en-us/microsoft-edge/extensions-chromium/developer-guide/alternate-distribution-options" %}

{% embed url="https://developer.chrome.com/docs/extensions/how-to/distribute/install-extensions#registry" %}

**Prerequisites:** This script has no prerequisites.&#x20;

***

## Script

{% hint style="info" %}
**Note:** This script will throw a warning if force install extension policies are detected. The associated registry entries created by those policies will be removed by the script but may be automatically recreated by group policy / Intune. The warning is intended to prompt the technician to check group policy / Intune.
{% endhint %}

{% @github-files/github-code-block url="https://github.com/wise-io/scripts/blob/main/scripts/RemoveExt.ps1" %}

## Examples

### Example 1

```powershell
.\RemoveExt.ps1 -ID 'hokifickgkhplphjiodbggjmoafhignh' 
```

This example removes the [Microsoft Editor: Spelling & Grammar Checker](https://microsoftedge.microsoft.com/addons/detail/microsoft-editor-spellin/hokifickgkhplphjiodbggjmoafhignh) extension in Microsoft Edge for all users and browser profiles.&#x20;

***

## Parameters

### Required Parameters

`-ID`

The ID of the browser extension to be removed.
