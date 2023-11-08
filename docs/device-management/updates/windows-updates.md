---
description: PowerShell script to silently install Windows updates.
---

# Windows Updates

## Overview

{% hint style="info" %}
**Dev Insight:** This script was extremely useful when patching for [CVE-2020-23397](https://msrc.microsoft.com/update-guide/vulnerability/CVE-2023-23397).
{% endhint %}

This script uses the [PSWindowsUpdate](https://www.powershellgallery.com/packages/PSWindowsUpdate) module to apply Windows updates silently, ignoring reboots. It also applies updates to installed Microsoft products.

{% embed url="https://www.powershellgallery.com/packages/PSWindowsUpdate" %}

**Prerequisites:** This script has no prerequisites.&#x20;

***

## Script

{% @github-files/github-code-block url="https://github.com/redletterone/PowerShell/blob/main/scripts/UpdateWindows.ps1" fullWidth="false" %}

## Examples

```powershell
.\UpdateWindows.ps1
```

This example installs the `PSWindowsUpdate` module, checks for all Windows updates and installs them. Reboots are ignored.

***

## Parameters

While this script has no parameters, the `PSWindowsUpdate` module has many. I have included `Get-Help` output for reference.

{% hint style="info" %}
**Module Version:** 2.2.0.3
{% endhint %}

{% code overflow="wrap" fullWidth="false" %}
```powershell
PS C:\Users\aaron> Get-Help Get-WindowsUpdate -Detailed

NAME
    Get-WindowsUpdate

SYNOPSIS
    Get list of available updates meeting the criteria.


SYNTAX
    Get-WindowsUpdate [-AcceptAll <SwitchParameter>] [-AutoReboot <SwitchParameter>] [-AutoSelectOnly
    <SwitchParameter>] [-AutoSelectOnWebSites <SwitchParameter>] [-BrowseOnly <SwitchParameter>] [-Category
    <string[]>] [-CategoryIDs <string[]>] [-ComputerName <string[]>] [-Criteria <string>] [-Debuger <SwitchParameter>]
    [-DeploymentAction <string>] [-Download <SwitchParameter>] [-ForceDownload <SwitchParameter>] [-ForceInstall
    <SwitchParameter>] [-Hide <SwitchParameter>] [-IgnoreReboot <SwitchParameter>] [-IgnoreRebootRequired
    <SwitchParameter>] [-IgnoreUserInput <SwitchParameter>] [-Install <SwitchParameter>] [-IsAssigned
    <SwitchParameter>] [-IsHidden <SwitchParameter>] [-IsInstalled <SwitchParameter>] [-IsPresent <SwitchParameter>]
    [-KBArticleID <string[]>] [-MaxSize <long>] [-MinSize <long>] [-NotCategory <string[]>] [-NotKBArticleID
    <string[]>] [-NotSeverity <string[]>] [-NotTitle <string>] [-NotUpdateID <string[]>] [-PSWUSettings <Hashtable>]
    [-RecurseCycle <int>] [-RevisionNumber <int>] [-RootCategories <string[]>] [-ScheduleJob <DateTime>]
    [-ScheduleReboot <DateTime>] [-SendHistory <SwitchParameter>] [-SendReport <SwitchParameter>] [-ServiceID
    <string>] [-Severity <string[]>] [-ShowPreSearchCriteria <SwitchParameter>] [-Title <string>] [-UpdateID
    <string[]>] [-UpdateType <string>] [-WithHidden <SwitchParameter>] [<CommonParameters>]

    Get-WindowsUpdate [-AcceptAll <SwitchParameter>] [-AutoReboot <SwitchParameter>] [-AutoSelectOnly
    <SwitchParameter>] [-AutoSelectOnWebSites <SwitchParameter>] [-BrowseOnly <SwitchParameter>] [-Category
    <string[]>] [-CategoryIDs <string[]>] [-ComputerName <string[]>] [-Criteria <string>] [-Debuger <SwitchParameter>]
    [-DeploymentAction <string>] [-Download <SwitchParameter>] [-ForceDownload <SwitchParameter>] [-ForceInstall
    <SwitchParameter>] [-Hide <SwitchParameter>] [-IgnoreReboot <SwitchParameter>] [-IgnoreRebootRequired
    <SwitchParameter>] [-IgnoreUserInput <SwitchParameter>] [-Install <SwitchParameter>] [-IsAssigned
    <SwitchParameter>] [-IsHidden <SwitchParameter>] [-IsInstalled <SwitchParameter>] [-IsPresent <SwitchParameter>]
    [-KBArticleID <string[]>] [-MaxSize <long>] [-MinSize <long>] [-NotCategory <string[]>] [-NotKBArticleID
    <string[]>] [-NotSeverity <string[]>] [-NotTitle <string>] [-NotUpdateID <string[]>] [-PSWUSettings <Hashtable>]
    [-RecurseCycle <int>] [-RevisionNumber <int>] [-RootCategories <string[]>] [-ScheduleJob <DateTime>]
    [-ScheduleReboot <DateTime>] [-SendHistory <SwitchParameter>] [-SendReport <SwitchParameter>] [-Severity
    <string[]>] [-ShowPreSearchCriteria <SwitchParameter>] [-Title <string>] [-UpdateID <string[]>] [-UpdateType
    <string>] [-WindowsUpdate <SwitchParameter>] [-WithHidden <SwitchParameter>] [<CommonParameters>]

    Get-WindowsUpdate [-AcceptAll <SwitchParameter>] [-AutoReboot <SwitchParameter>] [-AutoSelectOnly
    <SwitchParameter>] [-AutoSelectOnWebSites <SwitchParameter>] [-BrowseOnly <SwitchParameter>] [-Category
    <string[]>] [-CategoryIDs <string[]>] [-ComputerName <string[]>] [-Criteria <string>] [-Debuger <SwitchParameter>]
    [-DeploymentAction <string>] [-Download <SwitchParameter>] [-ForceDownload <SwitchParameter>] [-ForceInstall
    <SwitchParameter>] [-Hide <SwitchParameter>] [-IgnoreReboot <SwitchParameter>] [-IgnoreRebootRequired
    <SwitchParameter>] [-IgnoreUserInput <SwitchParameter>] [-Install <SwitchParameter>] [-IsAssigned
    <SwitchParameter>] [-IsHidden <SwitchParameter>] [-IsInstalled <SwitchParameter>] [-IsPresent <SwitchParameter>]
    [-KBArticleID <string[]>] [-MaxSize <long>] [-MicrosoftUpdate <SwitchParameter>] [-MinSize <long>] [-NotCategory
    <string[]>] [-NotKBArticleID <string[]>] [-NotSeverity <string[]>] [-NotTitle <string>] [-NotUpdateID <string[]>]
    [-PSWUSettings <Hashtable>] [-RecurseCycle <int>] [-RevisionNumber <int>] [-RootCategories <string[]>]
    [-ScheduleJob <DateTime>] [-ScheduleReboot <DateTime>] [-SendHistory <SwitchParameter>] [-SendReport
    <SwitchParameter>] [-Severity <string[]>] [-ShowPreSearchCriteria <SwitchParameter>] [-Title <string>] [-UpdateID
    <string[]>] [-UpdateType <string>] [-WithHidden <SwitchParameter>] [<CommonParameters>]


DESCRIPTION
    Use Get-WindowsUpdate (aka Get-WUList) cmdlet to get list of available or installed updates meeting specific
    criteria.

    Use Download-WindowsUpdate alias to get list of updates and download it. Equivalent Get-WindowsUpdate -Download.

    Use Install-WindowsUpdate (aka Get-WUInstall) alias to get list of updates and install it. Equivalent
    Get-WindowsUpdate -Install.

    Use Hide-WindowsUpdate alias to get list of updates and hide it. Equivalent Get-WindowsUpdate -Hide.

    Use Show-WindowsUpdate (aka UnHide-WindowsUpdate) alias to get list of updates and unhide it. Equivalent
    Get-WindowsUpdate -Hide:$false.

    There are two types of filtering update: Pre search criteria, Post search criteria.

    - Pre search works on server side, like example: (IsInstalled = 0 and IsHidden = 0 and CategoryIds contains
    '0fa1201d-4330-4fa8-8ae9-b877473b6441' )

    - Post search work on client side after get the pre-filtered list of updates, like example $KBArticleID -match
    $Update.KBArticleIDs

    Status info list:\r\n[A|R]DIMHUB\r\nA-IsAccetped\r\nR-IsRejected\r\n D-IsDownloaded\r\n F-DownloadFailed\r\n
    ?-IsInvoked\r\n I-IsInstalled\r\n F-InstallFailed\r\n ?-IsInvoked\r\n R-RebootRequired\r\n M-IsMandatory\r\n
    H-IsHidden\r\n U-IsUninstallable\r\n B-IsBeta


PARAMETERS
    -ComputerName <string[]>
        Specify one or more computer names for remote connection. Interactive remote connection works only for
        checking updates. For download or install cmdlet creates an Invoke-WUJob task.

    -SendReport <SwitchParameter>
        Send report email to specific recipients.

        Requires the parameter -PSWUSettings or declare the PSWUSettings.xml file (more preferred) in ModuleBase path.

    -PSWUSettings <Hashtable>
        Required parameter for -SendReport.

        Passes the parameters (as hashtable) necessary to send the report: \r\n@{SmtpServer="your.smtp.server";From="se
        nder@email.address";To="recipient@email.address";[Port=25];[Subject="Alternative
        Subject"];[Properties="Alternative object properties"];[Style="Table|List"]}

        Send parameters can also be saved to a PSWUSettings.xml file in ModuleBase path: \r\nExport-Clixml
        @{SmtpServer="your.smtp.server";From="sender@email.address";To="recipient@email.address";[Port=25]}"

    -SendHistory <SwitchParameter>
        Send install history (Get-WUHistory) report after successful update installation or system startup.

    -ScheduleJob <DateTime>
        Specify time when job will start.

    -AcceptAll <SwitchParameter>
        Do not ask confirmation for updates. Download or Install all available updates.

    -RecurseCycle <int>
        Specify number of cycles for check updates after successful update installation or system startup. First run
        is always main cycle (-RecurseCycle 1 or none). Second (-RecurseCycle 2) and n (-RecurseCycle n) cycle are
        recursive.

    -Hide <SwitchParameter>
        Get list of updates and hide/unhide approved updates.

    -Download <SwitchParameter>
        Get list of updates and download approved updates, but do not install it.

    -ForceDownload <SwitchParameter>
        Forces the download of updates that are already installed or that cannot be installed. Works only with
        -Download.

    -Install <SwitchParameter>
        Get list of updates and install approved updates.

    -ForceInstall <SwitchParameter>
        A forced installation is an installation in which an update is installed even if the metadata indicates that
        the update is already installed. Before you use ForceInstall to force an installation, determine whether the
        update is installed and available. If an update is not installed, a forced installation fails. Works only with
        -Install.

    -AutoReboot <SwitchParameter>
        Do not ask for reboot if it needed.

    -IgnoreReboot <SwitchParameter>
        Do not ask for reboot if it needed, but do not reboot automaticaly.

    -ScheduleReboot <DateTime>
        Specify time when system will be rebooted.

    -ServiceID <string>
        Use specific Service Manager if it's available.

        Examples Of ServiceID: \r\n \r\n -- Windows Update 9482f4b4-e343-43b6-b170-9a65bc822c77 \r\n -- Microsoft
        Update 7971f918-a847-4430-9279-4a52d1efe18d \r\n -- Windows Store 117cab2d-82b1-4b5a-a08c-4d62dbee7782 \r\n --
        Windows Server Update Service 3da21691-e39d-4da6-8a4b-b43877bcb1b7

    -WindowsUpdate <SwitchParameter>
        Use Microsoft Update Service Manager - '7971f918-a847-4430-9279-4a52d1efe18d'

    -MicrosoftUpdate <SwitchParameter>
        Use Windows Update Service Manager - '9482f4b4-e343-43b6-b170-9a65bc822c77'

    -Criteria <string>
        Pre search criteria - native for WUAPI. Set own string that specifies the search criteria.
        https://docs.microsoft.com/pl-pl/windows/desktop/api/wuapi/nf-wuapi-iupdatesearcher-search

    -UpdateType <string>
        Pre search criteria - native for WUAPI. Finds updates with a specific type, such as 'Driver' and 'Software'.
        Default value contains all updates.

    -DeploymentAction <string>
        Pre search criteria - native for WUAPI. Finds updates that are deployed for a specific action, such as an
        installation or uninstallation that the administrator of a server specifies. "DeploymentAction='Installation'"
        finds updates that are deployed for installation on a destination computer.
        "DeploymentAction='Uninstallation'" depends on the other query criteria.

        "DeploymentAction='Uninstallation'" finds updates that are deployed for uninstallation on a destination
        computer. "DeploymentAction='Uninstallation'" depends on the other query criteria.

        If this criterion is not explicitly specified, each group of criteria that is joined to an AND operator
        implies "DeploymentAction='Installation'".

    -IsAssigned <SwitchParameter>
        Pre search criteria - native for WUAPI. Finds updates that are intended for deployment by Automatic Updates.
        "IsAssigned=1" finds updates that are intended for deployment by Automatic Updates, which depends on the other
        query criteria.At most, one assigned Windows-based driver update is returned for each local device on a
        destination computer.

        "IsAssigned=0" finds updates that are not intended to be deployed by Automatic Updates.

    -IsPresent <SwitchParameter>
        Pre search criteria - native for WUAPI. When set to 1, finds updates that are present on a computer.

        "IsPresent=1" finds updates that are present on a destination computer.If the update is valid for one or more
        products, the update is considered present if it is installed for one or more of the products.

        "IsPresent=0" finds updates that are not installed for any product on a destination computer.

    -BrowseOnly <SwitchParameter>
        Pre search criteria - native for WUAPI. "BrowseOnly=1" finds updates that are considered optional.
        "BrowseOnly=0" finds updates that are not considered optional.

    -AutoSelectOnWebSites <SwitchParameter>
        Pre search criteria - native for WUAPI. Finds updates where the AutoSelectOnWebSites property has the
        specified value.

        "AutoSelectOnWebSites=1" finds updates that are flagged to be automatically selected by Windows Update.

        "AutoSelectOnWebSites=0" finds updates that are not flagged for Automatic Updates.

    -UpdateID <string[]>
        Pre search criteria - native for WUAPI. Finds updates with a specific UUID (or sets of UUIDs), such as
        '12345678-9abc-def0-1234-56789abcdef0'.

    -NotUpdateID <string[]>
        Pre search criteria - native for WUAPI. Finds updates without a specific UUID (or sets of UUIDs), such as
        '12345678-9abc-def0-1234-56789abcdef0'.

    -RevisionNumber <int>
        Pre search criteria - native for WUAPI. Finds updates with a specific RevisionNumber, such as '100'. This
        criterion must be combined with the UpdateID param.

    -CategoryIDs <string[]>
        Pre search criteria - native for WUAPI. Finds updates that belong to a specified category (or sets of UUIDs),
        such as '0fa1201d-4330-4fa8-8ae9-b877473b6441'.

    -IsInstalled <SwitchParameter>
        Pre search criteria - native for WUAPI. Finds updates that are installed on the destination computer.

    -IsHidden <SwitchParameter>
        Pre search criteria - native for WUAPI. Finds updates that are marked as hidden on the destination computer.
        Default search criteria is only not hidden upadates.

    -WithHidden <SwitchParameter>
        Pre search criteria - native for WUAPI. Finds updates that are both hidden and not on the destination
        computer. Overwrite IsHidden param. Default search criteria is only not hidden upadates.

    -ShowPreSearchCriteria <SwitchParameter>
        Show choosen search criteria. Only works for pre search criteria.

    -RootCategories <string[]>
        Post search criteria. Finds updates that contain a specified root category name 'Critical Updates',
        'Definition Updates', 'Drivers', 'Feature Packs', 'Security Updates', 'Service Packs', 'Tools', 'Update
        Rollups', 'Updates', 'Upgrades', 'Microsoft'.

    -Category <string[]>
        Post search criteria. Finds updates that contain a specified category name (or sets of categories name), such
        as 'Updates', 'Security Updates', 'Critical Updates', etc...

    -KBArticleID <string[]>
        Post search criteria. Finds updates that contain a KBArticleID (or sets of KBArticleIDs), such as 'KB982861'.

    -Title <string>
        Post search criteria. Finds updates that match part of title (case sensitive), such as '.NET Framework 4'.

    -Severity <string[]>
        Post search criteria. Finds updates that match part of severity, such as 'Important', 'Critical', 'Moderate',
        etc...

    -NotCategory <string[]>
        Post search criteria. Finds updates that not contain a specified category name (or sets of categories name),
        such as 'Updates', 'Security Updates', 'Critical Updates', etc...

    -NotKBArticleID <string[]>
        Post search criteria. Finds updates that not contain a KBArticleID (or sets of KBArticleIDs), such as
        'KB982861'.

    -NotTitle <string>
        Post search criteria. Finds updates that not match part of title (case sensitive).

    -NotSeverity <string[]>
        Post search criteria. Finds updates that not match part of severity.

    -IgnoreUserInput <SwitchParameter>
        Post search criteria. Finds updates that the installation or uninstallation of an update can't prompt for user
        input.

    -Silent <SwitchParameter>
        Post search criteria. Finds updates that the installation or uninstallation of an update can't prompt for user
        input.

        This is an alias of the IgnoreUserInput parameter.

    -IgnoreRebootRequired <SwitchParameter>
        Post search criteria. Finds updates that specifies the restart behavior that not occurs when you install or
        uninstall the update.

    -AutoSelectOnly <SwitchParameter>
        Install only the updates that have status AutoSelectOnWebsites on true.

    -MaxSize <long>
        Post search criteria. Finds updates that have MaxDownloadSize less or equal. Size is in Bytes.

    -MinSize <long>
        Post search criteria. Finds updates that have MaxDownloadSize greater or equal. Size is in Bytes.

    -Debuger <SwitchParameter>
        Debuger return original exceptions. For additional debug information use $DebugPreference = "Continue"

    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters (https:/go.microsoft.com/fwlink/?LinkID=113216).

    ----------  EXAMPLE 1  ----------

    Get windows updates available from default service manager.

    Get-WindowsUpdate -Verbose

    VERBOSE: MG-PC: Connecting to Windows Server Update Service server. Please wait...
    VERBOSE: Found[4] Updates in pre search criteria
    VERBOSE: Found[4] Updates in post search criteria

    ComputerName Status     KB          Size Title
    ------------ ------     --          ---- -----
    MG-PC        -------    KB890830    44MB Narzędzie Windows do usuwania złośliwego oprogramowania dla systemów
    Window...
    MG-PC        -------    KB4034658    1GB 2017-08 Aktualizacja zbiorcza dla systemu Windows 10 Version 1607 dla
    syste...
    MG-PC        -------    KB4034662   21MB 2017-08 Aktualizacja zabezpieczeń Adobe Flash Player w Windows 10 Version
    1...
    MG-PC        -------    KB4035631   11MB 2017-08 Aktualizacja Windows 10 Version 1607 dla systemów opartych na
    archi...

    ----------  EXAMPLE 2  ----------

    Get all installed drivers that are available at Windows Update. Additionaly show pre search criteria.

    Get-WindowsUpdate -WindowsUpdate -UpdateType Driver -IsInstalled -ShowPreSearchCriteria -Verbose

    PreSearchCriteria: IsInstalled = 0 and Type = 'Driver' and IsHidden = 0
    VERBOSE: MG-PC: Connecting to Windows Update server.Please wait...
    VERBOSE: Found[1] Updates in pre search criteria
    VERBOSE: Found[1] Updates in post search criteria

    ComputerName Status     KB          Size Title
    ------------ ------     --          ---- -----
    MGAJDALAP3   -DI----                 3MB Intel - Other hardware - Intel(R) Watchdog Timer Driver (Intel(R) WDT)

    ----------  EXAMPLE 3  ----------

    Get all available update on remote machine MG-PC, that contains in Title this two words 'Aktualizacja' and
    'Windows 10' (as regular expression).

    Get-WindowsUpdate -ComputerName MG-PC -MicrosoftUpdate -Title "Aktualizacja.*Windows 10" -Verbose

    VERBOSE: MG-PC: Connecting to Microsoft Update server. Please wait...
    VERBOSE: Found[14] Updates in pre search criteria
    VERBOSE: Found[5] Updates in post search criteria

    ComputerName Status     KB          Size Title
    ------------ ------     --          ---- -----
    MG-PC        -------    KB3150513    2MB 2017-06 Aktualizacja Windows 10 Version 1607 dla systemów opartych na
    archi...
    MG-PC        -------    KB4034658    1GB 2017-08 Aktualizacja zbiorcza dla systemu Windows 10 Version 1607 dla
    syste...
    MG-PC        -------    KB4034662   21MB 2017-08 Aktualizacja zabezpieczeń Adobe Flash Player w Windows 10 Version
    1...
    MG-PC        -------    KB4035631   11MB 2017-08 Aktualizacja Windows 10 Version 1607 dla systemów opartych na
    archi...
    MG-PC        -------    KB4033637    4MB Aktualizacja systemu Windows 10 Version 1607 dla komputerów z procesorami
    x...

    ----------  EXAMPLE 4  ----------

    Hide update with KBArticleID: KB4034658.

    Get-WindowsUpdate -KBArticleID KB4034658 -Hide -Verbose
    or use alias
    Hide-WindowsUpdate -KBArticleID KB4034658 -Verbose

    VERBOSE: MG-PC: Connecting to Windows Server Update Service server. Please wait...
    VERBOSE: Found[4] Updates in pre search criteria
    VERBOSE: Found[1] Updates in post search criteria

    Confirm
    Are you sure you want to perform this action?
    Performing the operation "Hide 2017-08 Aktualizacja zbiorcza dla systemu Windows 10 Version 1607 dla systemów
    opartych na architekturze x64 (KB4034658)[1GB]" on target "MG-PC".
    [Y] Yes[A] Yes to All  [N] No[L] No to All  [S] Suspend[?] Help (default is "Y"): Y

    ComputerName Status     KB          Size Title
    ------------ ------     --          ---- -----
    MG-PC        ---H--     KB4034658    1GB 2017-08 Aktualizacja zbiorcza dla systemu Windows 10 Version 1607 dla
    syste...

    ----------  EXAMPLE 5  ----------

    Unhide update with KBArticleID: KB4034658.

    Get-WindowsUpdate -KBArticleID KB4034658 -WithHidden -Hide:$false -Verbose
    or use alias
    Show-WindowsUpdate -KBArticleID KB4034658 -Verbose

    VERBOSE: MG-PC: Connecting to Windows Server Update Service server. Please wait...
    VERBOSE: Found[4] Updates in pre search criteria
    VERBOSE: Found[1] Updates in post search criteria

    Confirm
    Are you sure you want to perform this action?
    Performing the operation "Show 2017-08 Aktualizacja zbiorcza dla systemu Windows 10 Version 1607 dla systemów
    opartych na architekturze x64 (KB4034658)[1GB]" on target "MG-PC".
    [Y] Yes[A] Yes to All  [N] No[L] No to All  [S] Suspend[?] Help (default is "Y"): Y

    ComputerName Status     KB          Size Title
    ------------ ------     --          ---- -----
    MG-PC        ------     KB4034658    1GB 2017-08 Aktualizacja zbiorcza dla systemu Windows 10 Version 1607 dla
    syste...

    ----------  EXAMPLE 6  ----------

    Schedule job at 6:00 PM to install update with UpdateId='ddb74579-7a1f-4d1f-80c8-e8647055314e' and
    RevisionNumber=200. Update will be automaticaly accepted and after all serwer will be automaticaly restarted if
    needed.

    Get-WindowsUpdate -MicrosoftUpdate -UpdateID ddb74579-7a1f-4d1f-80c8-e8647055314e -RevisionNumber 200 -ScheduleJob
    (Get-Date -Hour 18 -Minute 0 -Second 0) -Install -AcceptAll -AutoReboot -Verbose
    or use alias
    Install-WindowsUpdate -MicrosoftUpdate -UpdateID ddb74579-7a1f-4d1f-80c8-e8647055314e -RevisionNumber 200
    -ScheduleJob (Get-Date -Hour 18 -Minute 0 -Second 0) -AcceptAll -AutoReboot -Verbose

    VERBOSE: MG-PC: Connecting to Microsoft Update server. Please wait...
    VERBOSE: Found[1] Updates in pre search criteria
    VERBOSE: Found[1] Updates in post search criteria
    VERBOSE: Choosed pre Search Criteria: (UpdateID = 'ddb74579-7a1f-4d1f-80c8-e8647055314e' and RevisionNumber = 200)

    X ComputerName Result     KB          Size Title
    - ------------ ------     --          ---- -----
    1 MG-PC        Accepted   KB4023307   13MB Microsoft Silverlight(KB4023307)
    VERBOSE: Accepted[1] Updates ready to Download
    VERBOSE: Invoke-WUJob: MG-PC(31.08.2017 18:00:00):
    VERBOSE: powershell.exe -Command "Get-WindowsUpdate -Criteria \"(UpdateID = 'ddb74579-7a1f-4d1f-80c8-e8647055314e'
    and RevisionNumber = 200)\" -AcceptAll -AutoReboot -Download -Install -MicrosoftUpdate -Verbose *>&1 | Out-File
    $Env:TEMP\PSWindowsUpdate.log"

    ----------  EXAMPLE 7  ----------

    Install updates on remote computer. After all send a report from the installation process.

    Install-WindowsUpdate -ComputerName MG-PC -MicrosoftUpdate -AcceptAll -AutoReboot -SendReport -PSWUSettings
    @{SmtpServer="your.smtp.server";From="sender@email.address";To="recipient@email.address";Port=25} -Verbose
    or use global PSWUSettings
    @{SmtpServer="your.smtp.server";From="sender@email.address";To="recipient@email.address";Port=25} | Export-Clixml
    -Path 'C:\Program Files\WindowsPowerShell\Modules\PSWindowsUpdate\PSWUSettings.xml'
    Install-WindowsUpdate -ComputerName MG-PC -MicrosoftUpdate -AcceptAll -AutoReboot -SendReport -Verbose

    VERBOSE: MG-PC: Connecting to Microsoft Update server. Please wait...
    VERBOSE: Found[4] Updates in pre search criteria
    VERBOSE: Found[4] Updates in post search criteria

    Confirm
    Are you sure you want to perform this action?
    Performing the operation "Microsoft Silverlight (KB4023307)[13MB]" on target "MG-PC".
    [Y] Yes[A] Yes to All  [N] No[L] No to All  [S] Suspend[?] Help (default is "Y"): Y

    Confirm
    Are you sure you want to perform this action?
    Performing the operation "2017-06 Aktualizacja Windows 10 Version 1607 dla systemów opartych na architekturze x64
    (KB3150513)[2MB]" on target "MG-PC".
    [Y] Yes[A] Yes to All  [N] No[L] No to All  [S] Suspend[?] Help (default is "Y"): Y

    Confirm
    Are you sure you want to perform this action?
    Performing the operation "Aktualizacja pakietu językowego usługi Microsoft Dynamics 365 2.1[47MB]" on target
    "MG-PC".
    [Y] Yes[A] Yes to All  [N] No[L] No to All  [S] Suspend[?] Help (default is "Y"): L

    X ComputerName Result     KB          Size Title
    - ------------ ------     --          ---- -----
    1 MG-PC Accepted KB4023307   13MB Microsoft Silverlight (KB4023307)
    1 MG-PC Accepted KB3150513    2MB 2017-06 Aktualizacja Windows 10 Version 1607 dla systemów opartych na arc...
    1 MG-PC Rejected KB4013759   47MB Aktualizacja pakietu językowego usługi Microsoft Dynamics 365 2.1
    1 MG-PC Rejected KB3186568   67MB Program Microsoft .NET Framework 4.7 w syst. Windows 10 Version 1607 i Wi...
    VERBOSE: Accepted [2]
    Updates ready to Download
    VERBOSE: Invoke-WUJob: MG-PC (Now):
    VERBOSE: powershell.exe -Command "Get-WindowsUpdate -Criteria \"(UpdateID = 'ddb74579-7a1f-4d1f-80c8-e8647055314e'
    and RevisionNumber = 200) or (UpdateID = '151c4402-513c-4f39-8da1-f84d0956b5e3' and RevisionNumber = 200)\"
    -AcceptAll -Download -Install -AutoReboot -MicrosoftUpdate -SendReport -ProofOfLife -Verbose *>&1 | Out-File
    $Env:TEMP\PSWindowsUpdate.log"

    ----------  EXAMPLE 8  ----------

    Schedule Job to install all available updates and automatically reboot system if needed. Also send report after
    installation (but before reboot if needed) and send second instalation history report after reboot.

    @{SmtpServer="your.smtp.server";From="sender@email.address";To="recipient@email.address";Port=25} | Export-Clixml
    -Path 'C:\Program Files\WindowsPowerShell\Modules\PSWindowsUpdate\PSWUSettings.xml'
    Install-WindowsUpdate -MicrosoftUpdate -SendReport -SendHistory -AcceptAll -AutoReboot -ScheduleJob (Get-Date
    -Hour 18 -Minute 30 -Second 0) -ComputerName MG-PC -Verbose

    VERBOSE: MG-PC: Connecting to Microsoft Update server. Please wait...
    VERBOSE: Found[4] Updates in pre search criteria
    VERBOSE: Found[4] Updates in post search criteria

    X ComputerName Result     KB          Size Title
    - ------------ ------     --          ---- -----
    1 MG-PC        Accepted   KB3038936    5MB Aktualizacja systemu Windows 8.1 dla komputerów z procesorami
    x64(KB3038...
    1 MG-PC        Accepted   KB3186606    4MB Pakiety językowe programu Microsoft.NET Framework 4.7 w syst. Windows
    8....
    1 MG-PC        Accepted   KB4035038   53MB Sierpień 2017: wersja zapozn. pak.zb.aktual.jakości dla pr. .NET
    Frame...
    1 MG-PC        Accepted   KB2267602  309MB Aktualizacja definicji dla: Windows Defender — KB2267602 (Definicja
    1.251...
    VERBOSE: Accepted[4] Updates ready to Download
    VERBOSE: Invoke-WUJob: MG-PC (02.09.2017 08:30:00):
    VERBOSE: powershell.exe -Command "Get-WindowsUpdate -Criteria \"(UpdateID = 'e69c9679-7ce8-489a-a21c-62fb920be67a'
    and RevisionNumber = 201) or(UpdateID = 'de44604d-ec38-4a7f-ac63-28b3edfdb382' and RevisionNumber = 207)
    or(UpdateID = '9cf1d8c9-a7c3-4603-90e8-f22131ff6d7e' and RevisionNumber = 201) or(UpdateID =
    'b51935f9-0e40-4624-9c26-b29bff92dcf9' and RevisionNumber = 200)\" -AcceptAll -Install -AutoReboot
    -MicrosoftUpdate -SendReport -SendHistory -Verbose *>&1 | Out-File $Env:TEMP\PSWindowsUpdate.log"
    VERBOSE: Send report

REMARKS
    To see the examples, type: "get-help Get-WindowsUpdate -examples".
    For more information, type: "get-help Get-WindowsUpdate -detailed".
    For technical information, type: "get-help Get-WindowsUpdate -full".
    For online help, type: "get-help Get-WindowsUpdate -online"
```
{% endcode %}
