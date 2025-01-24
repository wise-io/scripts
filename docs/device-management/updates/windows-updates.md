---
description: PowerShell script to silently install Windows updates.
---

# Windows Updates

## Overview

This script uses the [PSWindowsUpdate](https://www.powershellgallery.com/packages/PSWindowsUpdate) module to apply Windows updates silently, ignoring reboots. It also applies updates to installed Microsoft products.

{% embed url="https://www.powershellgallery.com/packages/PSWindowsUpdate/2.2.1.5" %}

**Prerequisites:** This script has no prerequisites.&#x20;

***

## Script

{% @github-files/github-code-block url="https://github.com/wise-io/scripts/blob/main/scripts/UpdateWindows.ps1" %}

## Examples

```powershell
.\UpdateWindows.ps1
```

This example installs the `PSWindowsUpdate` module, checks for all Windows updates and installs them. Reboots are ignored.

***

## Parameters

While this script has no parameters, the `PSWindowsUpdate` module has many. I have included `Get-Help` output on parameters for reference.

{% hint style="info" %}
**Module Version:** 2.2.0.3
{% endhint %}

{% code overflow="wrap" fullWidth="false" %}
```
-ComputerName <string[]>
    Specify one or more computer names for remote connection. Interactive remote connection works only for checking updates. For download or install cmdlet creates an Invoke-WUJob task.

-SendReport <SwitchParameter>
    Send report email to specific recipients.

    Requires the parameter -PSWUSettings or declare the PSWUSettings.xml file (more preferred) in ModuleBase path.

-PSWUSettings <Hashtable>
    Required parameter for -SendReport.

    Passes the parameters (as hashtable) necessary to send the report: \r\n@{SmtpServer="your.smtp.server";From="sender@email.address" To="recipient@email.address";[Port=25];[Subject="AlternativeSubject"];[Properties="Alternative object properties"];[Style="Table|List"]}

    Send parameters can also be saved to a PSWUSettings.xml file in ModuleBase path: \r\nExport-Clixml @{SmtpServer="your.smtp.server";From="sender@email.address";To="recipient@email.address";[Port=25]}

-SendHistory <SwitchParameter>
    Send install history (Get-WUHistory) report after successful update installation or system startup.

-ScheduleJob <DateTime>
    Specify time when job will start.

-AcceptAll <SwitchParameter>
    Do not ask confirmation for updates. Download or Install all available updates.

-RecurseCycle <int>
    Specify number of cycles for check updates after successful update installation or system startup. First run is always main cycle (-RecurseCycle 1 or none). Second (-RecurseCycle 2) and n (-RecurseCycle n) cycle are recursive.

-Hide <SwitchParameter>
    Get list of updates and hide/unhide approved updates.

-Download <SwitchParameter>
    Get list of updates and download approved updates, but do not install it.

-ForceDownload <SwitchParameter>
    Forces the download of updates that are already installed or that cannot be installed. Works only with -Download.

-Install <SwitchParameter>
    Get list of updates and install approved updates.

-ForceInstall <SwitchParameter>
    A forced installation is an installation in which an update is installed even if the metadata indicates that the update is already installed. Before you use ForceInstall to force an installation, determine whether the update is installed and available. If an update is not installed, a forced installation fails. Works only with -Install.

-AutoReboot <SwitchParameter>
    Do not ask for reboot if it needed.

-IgnoreReboot <SwitchParameter>
    Do not ask for reboot if it needed, but do not reboot automaticaly.

-ScheduleReboot <DateTime>
    Specify time when system will be rebooted.

-ServiceID <string>
    Use specific Service Manager if it's available.

    Examples Of ServiceID: \r\n \r\n -- Windows Update 9482f4b4-e343-43b6-b170-9a65bc822c77 \r\n -- Microsoft Update 7971f918-a847-4430-9279-4a52d1efe18d \r\n -- Windows Store 117cab2d-82b1-4b5a-a08c-4d62dbee7782 \r\n -- Windows Server Update Service 3da21691-e39d-4da6-8a4b-b43877bcb1b7

-WindowsUpdate <SwitchParameter>
    Use Microsoft Update Service Manager - '7971f918-a847-4430-9279-4a52d1efe18d'

-MicrosoftUpdate <SwitchParameter>
    Use Windows Update Service Manager - '9482f4b4-e343-43b6-b170-9a65bc822c77'

-Criteria <string>
    Pre search criteria - native for WUAPI. Set own string that specifies the search criteria.
    https://docs.microsoft.com/pl-pl/windows/desktop/api/wuapi/nf-wuapi-iupdatesearcher-search

-UpdateType <string>
    Pre search criteria - native for WUAPI. Finds updates with a specific type, such as 'Driver' and 'Software'. Default value contains all updates.

-DeploymentAction <string>
    Pre search criteria - native for WUAPI. Finds updates that are deployed for a specific action, such as an installation or uninstallation that the administrator of a server specifies. "DeploymentAction='Installation'" finds updates that are deployed for installation on a destination computer. "DeploymentAction='Uninstallation'" depends on the other query criteria.

    "DeploymentAction='Uninstallation'" finds updates that are deployed for uninstallation on a destination computer. "DeploymentAction='Uninstallation'" depends on the other query criteria.

    If this criterion is not explicitly specified, each group of criteria that is joined to an AND operator implies "DeploymentAction='Installation'".

-IsAssigned <SwitchParameter>
    Pre search criteria - native for WUAPI. Finds updates that are intended for deployment by Automatic Updates. "IsAssigned=1" finds updates that are intended for deployment by Automatic Updates, which depends on the other query criteria.At most, one assigned Windows-based driver update is returned for each local device on a destination computer.

    "IsAssigned=0" finds updates that are not intended to be deployed by Automatic Updates.

-IsPresent <SwitchParameter>
    Pre search criteria - native for WUAPI. When set to 1, finds updates that are present on a computer.

    "IsPresent=1" finds updates that are present on a destination computer.If the update is valid for one or more products, the update is considered present if it is installed for one or more of the products.

    "IsPresent=0" finds updates that are not installed for any product on a destination computer.

-BrowseOnly <SwitchParameter>
    Pre search criteria - native for WUAPI. "BrowseOnly=1" finds updates that are considered optional. "BrowseOnly=0" finds updates that are not considered optional.

-AutoSelectOnWebSites <SwitchParameter>
    Pre search criteria - native for WUAPI. Finds updates where the AutoSelectOnWebSites property has the specified value.

    "AutoSelectOnWebSites=1" finds updates that are flagged to be automatically selected by Windows Update.

    "AutoSelectOnWebSites=0" finds updates that are not flagged for Automatic Updates.

-UpdateID <string[]>
    Pre search criteria - native for WUAPI. Finds updates with a specific UUID (or sets of UUIDs), such as '12345678-9abc-def0-1234-56789abcdef0'.

-NotUpdateID <string[]>
    Pre search criteria - native for WUAPI. Finds updates without a specific UUID (or sets of UUIDs), such as '12345678-9abc-def0-1234-56789abcdef0'.

-RevisionNumber <int>
    Pre search criteria - native for WUAPI. Finds updates with a specific RevisionNumber, such as '100'. This criterion must be combined with the UpdateID param.

-CategoryIDs <string[]>
    Pre search criteria - native for WUAPI. Finds updates that belong to a specified category (or sets of UUIDs), such as '0fa1201d-4330-4fa8-8ae9-b877473b6441'.

-IsInstalled <SwitchParameter>
    Pre search criteria - native for WUAPI. Finds updates that are installed on the destination computer.

-IsHidden <SwitchParameter>
    Pre search criteria - native for WUAPI. Finds updates that are marked as hidden on the destination computer. Default search criteria is only not hidden upadates.

-WithHidden <SwitchParameter>
    Pre search criteria - native for WUAPI. Finds updates that are both hidden and not on the destination computer. Overwrite IsHidden param. Default search criteria is only not hidden upadates.

-ShowPreSearchCriteria <SwitchParameter>
    Show choosen search criteria. Only works for pre search criteria.

-RootCategories <string[]>
    Post search criteria. Finds updates that contain a specified root category name 'Critical Updates', 'Definition Updates', 'Drivers', 'Feature Packs', 'Security Updates', 'Service Packs', 'Tools', 'Update Rollups', 'Updates', 'Upgrades', 'Microsoft'.

-Category <string[]>
    Post search criteria. Finds updates that contain a specified category name (or sets of categories name), such as 'Updates', 'Security Updates', 'Critical Updates', etc...

-KBArticleID <string[]>
    Post search criteria. Finds updates that contain a KBArticleID (or sets of KBArticleIDs), such as 'KB982861'.

-Title <string>
    Post search criteria. Finds updates that match part of title (case sensitive), such as '.NET Framework 4'.

-Severity <string[]>
    Post search criteria. Finds updates that match part of severity, such as 'Important', 'Critical', 'Moderate', etc...

-NotCategory <string[]>
    Post search criteria. Finds updates that not contain a specified category name (or sets of categories name), such as 'Updates', 'Security Updates', 'Critical Updates', etc...

-NotKBArticleID <string[]>
    Post search criteria. Finds updates that not contain a KBArticleID (or sets of KBArticleIDs), such as 'KB982861'.

-NotTitle <string>
    Post search criteria. Finds updates that not match part of title (case sensitive).

-NotSeverity <string[]>
    Post search criteria. Finds updates that not match part of severity.

-IgnoreUserInput <SwitchParameter>
    Post search criteria. Finds updates that the installation or uninstallation of an update can't prompt for user input.

-Silent <SwitchParameter>
    Post search criteria. Finds updates that the installation or uninstallation of an update can't prompt for user input.

    This is an alias of the IgnoreUserInput parameter.

-IgnoreRebootRequired <SwitchParameter>
    Post search criteria. Finds updates that specifies the restart behavior that not occurs when you install or uninstall the update.

-AutoSelectOnly <SwitchParameter>
    Install only the updates that have status AutoSelectOnWebsites on true.

-MaxSize <long>
    Post search criteria. Finds updates that have MaxDownloadSize less or equal. Size is in Bytes.

-MinSize <long>
    Post search criteria. Finds updates that have MaxDownloadSize greater or equal. Size is in Bytes.

-Debuger <SwitchParameter>
    Debuger return original exceptions. For additional debug information use $DebugPreference = "Continue"

<CommonParameters>
    This cmdlet supports the common parameters: Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, WarningVariable, OutBuffer, PipelineVariable, and OutVariable. For more information, see about_CommonParameters (https:/go.microsoft.com/fwlink/?LinkID=113216).
```
{% endcode %}
