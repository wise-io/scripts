---
description: PowerShell script to silently install multiple versions of QuickBooks desktop.
---

# QuickBooks Desktop

## Overview

{% hint style="info" %}
**Dev Insight:** After tediously installing 6 versions of QuickBooks back-to-back on a single device, I wrote this script. It quickly paid for itself in the amount of labor saved. If only QuickBooks updates could be scripted as easily!
{% endhint %}

This script uses the provided Product Numbers to download and install multiple versions of QuickBooks desktop in a single pass. It is most useful for deployment of new devices for accountants, who often have requirements to maintain multiple versions of QuickBooks desktop.

{% embed url="https://downloads.quickbooks.com/app/qbdt/products" %}
Download QuickBooks Desktop
{% endembed %}

**Prerequisites:**

1. Collect the Product & License Numbers for the versions of QuickBooks you will be installing.
2. Ensure the script supports the desired versions. _If the script does not support your desired versions, you will need to add them ahead of time._
3. **Optional:** Download the installers and place them in a directory that will be accessible to the script at runtime.

**Notes:**

* Script will abort if run as SYSTEM; it must be run as an administrative user.
* While this script can install multiple versions of QuickBooks Desktop in a single pass, installed versions will use a single license key. If you need to install various QuickBooks versions with different license keys side-by-side, you will need to run the script for each key.
* The required PDF components (Microsoft XPS Document Writer) will be enabled, if not already.
* View uncommented lines in the `$QBVersions` array in the script for currently supported versions.

***

## Script

{% hint style="danger" %}
Script will abort if run as SYSTEM; it must be run as an administrative user.
{% endhint %}

{% @github-files/github-code-block url="https://github.com/redletterone/PowerShell/blob/main/scripts/InstallQuickBooks.ps1" %}

## Examples

### Example 1

```powershell
.\InstallQuickBooks.ps1 -ID 401228,917681
```

This example uses only the required parameter, `ProductNumbers` (alias `ID`) to download and install QuickBooks Pro 2022 & QuickBooks Pro 2023. Notably, it uses a default license key of '0000-0000-0000-000'. The correct license key will need to be manually added before QuickBooks is used.

### Example 2

```powershell
.\InstallQuickBooks.ps1 -Cache '\\SERVER\QuickBooks Installers' -License 1234-5678-9101-234 -ID 401-228,917-681 -ToolHub
```

This example, in addition to the required `ProductNumbers` (alias `ID`) parameter, uses the available optional parameters to install QuickBooks Pro 2022 & QuickBooks Pro 2023.

The `Cache` parameter is used to provide a path to pre-downloaded QuickBooks Desktop installers.

The `LicenseNumber` (alias `License`) parameter is used to supply the correct License Number for QuickBooks. The same license number will be used for all supplied Product Numbers. If multiple license numbers are required, the script will need to be run for each License Number.

The `ToolHub` parameter is used to install [QuickBooks ToolHub](https://quickbooks.intuit.com/learn-support/en-us/help-article/login-password/fix-common-problems-errors-quickbooks-desktop-tool/L3Yab5gNN\_US\_en\_US) alongside the selected versions of QuickBooks Desktop.

***

## Parameters

### Required Parameters

`-ProductNumbers`

**Aliases:** `-ID`, `-Product`, `-Products`, `-ProductNumber`

Array parameter that accepts multiple QuickBooks Product Numbers with or without dashes. Supplied Product Numbers will be compared with the `$QBVersions` array to determine which versions of QuickBooks to install.

### Optional Parameters

`-Cache`

String parameter that allows you to provide a directory file path to pre-downloaded QuickBooks installers. If this parameter is not used or the path is invalid/inaccessible, the QuickBooks installers will be downloaded directly from Intuit.&#x20;

**Note:** This parameter assumes that the file names in the cache directory match the file names for the installers downloaded from Intuit.



`-LicenseNumber`

**Aliases:** `-License`

String parameter that allows you to supply the QuickBooks License Number (with or without dashes) for the versions of QuickBooks the script is installing. If this parameter is not used, a license number of 0000-0000-0000-000 will be used. The correct license can be added to QuickBooks after installation via **Help < Manage My License < Change My License** in QuickBooks Desktop.



`-ToolHub`

Switch parameter that can be used to install the [QuickBooks Tool Hub](https://quickbooks.intuit.com/learn-support/en-us/help-article/login-password/fix-common-problems-errors-quickbooks-desktop-tool/L3Yab5gNN\_US\_en\_US) application alongside QuickBooks.
