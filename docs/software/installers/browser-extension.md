---
description: PowerShell script to silently install a browser extension by ID.
---

# Browser Extension

## Overview

{% hint style="info" %}
**Dev Insight:** While group policy and Intune configuration profiles are the ideal way to distribute browser extensions, I needed a way to easily distribute extensions in environments without Active Directory / Intune.&#x20;
{% endhint %}

This script creates the necessary registry entries for Microsoft Edge or Google Chrome to install the provided extension globally for all users of a device. \
\
By default, the extension installation is not "forced". Each user will be able to disable or uninstall the extension for their browser profile. To prevent this, the `-Force` parameter can be used.

{% embed url="https://learn.microsoft.com/en-us/microsoft-edge/extensions-chromium/developer-guide/alternate-distribution-options" %}

{% embed url="https://developer.chrome.com/docs/extensions/how-to/distribute/install-extensions#registry" %}

**Prerequisites:** This script has no prerequisites.&#x20;

***

## Script

{% hint style="info" %}
**Note:** Browser specific versions of this script can be found in the [GitHub repo](https://github.com/wise-io/scripts/tree/main/scripts).
{% endhint %}

{% @github-files/github-code-block url="https://github.com/wise-io/scripts/blob/main/scripts/InstallBrowserExtension.ps1" %}

## Examples

### Example 1

```powershell
.\InstallBrowserExtension.ps1 -ID 'hokifickgkhplphjiodbggjmoafhignh' -Edge 
```

This example installs the [Microsoft Editor: Spelling & Grammar Checker](https://microsoftedge.microsoft.com/addons/detail/microsoft-editor-spellin/hokifickgkhplphjiodbggjmoafhignh) extension in Microsoft Edge for all users. When installed, users will be prompted to enable the extension.

### Example 2

```powershell
.\InstallBrowserExtension.ps1 -ID 'ghbmnnjooekpmoecnnnilnnbdlolhkhi' -Chrome -Force 
```

This example force installs the [Google Docs Offline](https://chromewebstore.google.com/detail/google-docs-offline/ghbmnnjooekpmoecnnnilnnbdlolhkhi) extension in Google Chrome for all users. Users will not be able to disable or uninstall the extension.

***

## Parameters

### Required Parameters

`-ID`

The ID of the browser extension to be installed.



`-Chrome`

Used to specify that the extension ID provided is a Google Chrome browser extension. Either this or the `-Edge` parameter must be used.&#x20;



`-Edge`

Used to specify that the extension ID provided is a Microsoft Edge browser extension. Either this or the `-Chrome` parameter must be used.



### Optional Parameters

`-Force`

When used, the provided extension will be added to the force installed extension list for the designated browser. Users will not be able to disable or uninstall the extension.
