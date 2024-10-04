---
description: PowerShell script to cleanly install Microsoft Office.
---

# Microsoft Office

## Overview

This script uses the Office Deployment Tool (ODT) to perform a clean install of Microsoft Office with a configuration xml file. For convenience, it includes a built-in xml file that will install **Microsoft Office 365 Apps for Business** if a configuration file is not specified.

{% embed url="https://learn.microsoft.com/en-us/deployoffice/overview-office-deployment-tool" %}

**Prerequisites:**

1. If necessary, create a configuration xml at [https://config.office.com](https://config.office.com).
2. Store the configuration xml in a location that will be accessible to the script at runtime.
3. Notate the path of the configuration xml.

**Notes:**

* When using the built-in configuration xml, the 64-bit version of Microsoft Office 365 will be installed, unless a 32-bit OS is detected or the `-x86` switch is used.
* This script will uninstall the Microsoft Office Hub Microsoft Store application.

***

## Script

{% hint style="danger" %}
Script will remove existing installations of Microsoft Office when used with the default configuration file.
{% endhint %}

{% @github-files/github-code-block url="https://github.com/wise-io/scripts/blob/main/scripts/InstallOffice.ps1" %}

## Examples

### Example 1

```powershell
.\InstallOffice.ps1
```

This example installs Microsoft Office 365 Apps for Business using the built-in XML configuration file. All existing versions of Microsoft Office will be removed, including the Microsoft Office Hub Microsoft Store application.

### Example 2

```powershell
.\InstallOffice.ps1 -x86
```

This example installs the 32-bit version of Microsoft Office 365 Apps for Business using the built-in XML configuration file. All existing versions of Microsoft Office will be removed, including the Microsoft Office Hub Microsoft Store application.

### Example 3

```powershell
.\InstallOffice.ps1 -Config "C:\temp\office-config.xml"
```

This example utilizes the provided XML configuration file to determine which Microsoft Office products to install or remove.

***

## Parameters

`-Config`

Optional string parameter that allows you to provide a file path to an office configuration xml. This XML will be used to determine what Microsoft Office products to install or remove.



`-x86`

**Aliases:** `-32`, `-32bit`

Optional switch parameter that allows the installation of the 32-bit version of Microsoft Office 365, even on 64-bit systems.&#x20;

**Note:** This parameter cannot be used with `-Config`.
