# PSCMContentMgmt

PowerShell module used for managing Microsoft Endpoint Manager Configuration Manager distribution point content.

Here are some of the things you can do with it:

- Query content objects which are distributed to distribution point(s) or distribution point group(s)
- Compare content objects distributed to distribution point(s) or distribution point group(s)
- Find content objects in a "distribution failed" state for all or selective distribution points
- Remove, distribute or redistribute content objects returned by any function to distribution point(s)
- Find an object in your site by searching on any arbitrary ID (useful when reading logs and want to know what object an ID resolves to)
- Migrate a distribution point’s content to a new/different distribution point by exporting its content library to prestaged .pkgx files and importing the .pkgx files to the new distribution point
- Invoke the ContentLibraryCleanup.exe tool

PSCMContentMgmt is a mix of being no more than a wrapper for MEMCM cmdlets or native binaries. Some functions query WMI or invoke WMI methods.

PSCMContentMgmt does not intend to reinvent the wheel from already available cmdlets. Instead it provides a simpler workflow for managing your distribution points by offering:

- Easy to use pipeline support, so you can easily progress through the motions for tasks such as querying content on a distribution point or distribution point group – perhaps in a particular state (e.g. "distribution failed") – and distributing, redistributing or removing it from another (or the same) distribution point or distribution point group.
- Consistent property names when dealing with different types of content objects, i.e. the ObjectID property is always PackageID except for Applications/Deployment Types where it is CI_ID (same is true for the -ObjectID parameter on functions that offer it).
- Functionality which the Configuration Manager module does not provide.

## Functions

- [Find-CMObject](docs/Find-CMOBject.md)
- [Compare-DPContent](docs/Compare-DPContent.md)
- [Compare-DPGroupContent](docs/Compare-DPGroupContent.md)
- [Export-DPContent](docs/Export-DPContent.md)
- [Get-DP](docs/Get-DP.md)
- [Get-DPContent](docs/Get-DPContent.md)
- [Get-DPDistributionStatus](docs/Get-DPDistributionStatus.md)
- [Get-DPGroup](docs/Get-DPGroup.md)
- [Get-DPGroupContent](docs/Get-DPGroupContent.md)
- [Import-DPContent](docs/Import-DPContent.md)
- [Invoke-DPContentLibraryCleanup](docs/Invoke-DPContentLibraryCleanup.md)
- [Remove-DPContent](docs/Remove-DPContent.md)
- [Remove-DPGroupContent](docs/Remove-DPGroupContent.md)
- [Set-DPAllowPrestagedContent](docs/Set-DPAllowPrestagedContent.md)
- [Start-DPContentDistribution](docs/Start-DPContentDistribution.md)
- [Start-DPContentRedistribution](docs/Start-DPContentRedistribution.md)
- [Start-DPGroupContentDistribution](docs/Start-DPGroupContentDistribution.md)

## Requirements

- PowerShell 5.1
- Configuration Manager module available locally on the system you import the module

## Getting started

Install and import:

```powershell
PS C:\> Install-Module PSCMContentMgmt -Scope CurrentUser
PS C:\> Import-Module PSCMContentMgmt
```

All functions of the module require use of `-SiteServer` or `-SiteCode` parameters. This can be tedious to repeatedly type out. Therefore upon importing the module, two variables will be set in your session:

- `$CMSiteServer`
  - Value determined by reading the `Server` registry value in key `HKLM:\SOFTWARE\WOW6432Node\Microsoft\ConfigMgr10\AdminUI\Connection`.
  - This registry key is used by the Configuration Manager module, therefore it is assumed this is the site you want to work in.
- `$CMSiteCode`
  - Value determined by reading the `SiteCode` property in the `SMS_ProviderLocation` WMI class on the server defined in `$CMSiteServer`.

Ovewritting these variables is OK and essential if you operate in a multi-site environment.

If you receive a warning along the lines of being unable to auto-populate variables `$CMSiteServer` or `$CMSiteCode`, that means the module failed to read the previously mentioned registry value or the `SMS_ProviderLocation` class on your site server.

If the reason why the module could not set these variables itself is not known, or there's no viable workaround for you, then you can set `$CMSiteServer` or `$CMSiteCode` yourself. Alternatively you can use the `-SiteServer` and `-SiteCode` parameters on an ad-hoc basis.

Where any of the functions return an object with the property ObjectID, or where a parameter is named -ObjectID, it will always be the PackageID for all content objects (Packages, Driver Packages, Boot Images etc) except for Applications/Deployment Types where it is CI_ID. This enables you to have a property ready to use for Applications with any of the cmdlets from the Configuration Manager module.

## Examples

```powershell
PS C:\> Get-Help "about_PSCMContentMgmt_ExportImpot"
```

To learn more about how to migrate distribution point content using PSCMContentMgmt, please see my [SysManSquad blog post](https://sysmansquad.com/2020/09/04/manage-distribution-point-content-using-pscmcontentmgmt/#comparing-distribution-content-objects-between-two-distribution-points-or-distribution-point-groups) or read the help topic `about_PSCMContentMgmt_ExportImport`.

___

```powershell
PS C:\> Get-DP -Name "SERVERA%", "SERVERB%" -Exclude "%CMG%"
```

Return distribution points which have a ServerName property starting with `SERVERA` or `SERVERB`, but excluding any that match `CMG` anywhere in its name.

___

```powershell
PS C:\> Get-DP | Get-DPDistributionStatus -DistributionFailed | Group-Object -Property DistributionPoint
```

Return all distribution points, their associated failed distribution tasks and group the results by distribution point now for an overview.

___

```powershell
PS C:\> Get-DP | Get-DPDistributionStatus -DistributionFailed | Start-DPContentRedistribution
```

Return all distribution points, their associated failed distribution tasks and initiate redistribution for them.

___

```powershell
PS C:\> Get-DP -Name "London%" | Get-DPContent
```

Return all content objects found on distribution points where their ServerName starts with "London".

_Note: the same is available for groups with Get-DPGroup and `Get-DPGroupContent`._
___

```powershell
PS C:\> Compare-DPContent -Source "dp1.contoso.com" -Target "dp2.contoso.com"
```

Return objects which are on dp1.contoso.com but not on dp2.contoso.com.

_Note: the same is available for groups with `Compare-DPGroupContent`._

___

```powershell
PS C:\> Compare-DPContent -Source "dp1.contoso.com" -Target "dp2.contoso.com" | Start-DPContentDistribution -DistributionPoint "dp2.contoso.com"
```

Distribute the missing objects to dp2.contoso.com.

_Note: the same is available for groups with `Start-DPGroupContentDistribution`._

___

```powershell
PS C:\> Get-DPContent -DistributionPoint "dp1.contoso.com" -Package | Remove-DPContent
```

Remove all Packages from a distribution point.

_Note: the same is available for groups with `Get-DPGroupContent` and `Remove-DPGroupContent`._

___

```powershell
PS C:\> Invoke-DPContentLibraryCleanup -DistributionPoint "dp1.contoso.com" -Delete
```

Invoke the ContentLibraryCleanup.exe tool.

___

```powershell
PS C:\> Find-CMObject -ID "ACC00048"
```
Finds any object which has the PackageID "ACC00048", this includes applications, collections, driver packages, boot images, OS images, OS upgrade images, task sequences and deployment packages.

___


```powershell
PS C:\> Find-CMObject -ID "17007122"
```

Finds any object which has the CI_ID "17007122", this includes applications, deployment types, drivers, configuration items and configuration baselines.

___

```powershell
PS C:\> Find-CMObject -ID "ScopeId_B3FF3CC4-0319-4434-9D24-77689C53C615/Application_197d8de7-022d-4c0b-aec4-c339ccc17ba4"
```
Finds an application which matches the ModelName "ScopeId_B3FF3CC4-0319-4434-9D24-77689C53C615/Application_197d8de7-022d-4c0b-aec4-c339ccc17ba4"

## Known issues

- The Configuration Manager module notoriously returns generic error messages (if any) for most of its cmdlets/functions. Since this module is mostly nothing more than a wrapper for most cmdlets/functions, I just forward those messages on to you so please bear that in mind.
- `Remove-DPContent` and `Remove-DPGroupContent` only removes items that are fully distributed.
- It is not possible to suppress the output of `Export-DPContent` (which is essentially just `Publish-CMPrestageContent`).
- The functions given by this module are not the most performant method of dealing with distribution point content. Most of the Configuraion Manager cmdlet/functions accept arrays of IDs. Whereas I purposefully chose to call the cmdlets for each object purely for the benefit of giving success/failure results back to the user for each object.

## Support

For help, be sure to use `Get-Help` to check out the About help pages or the comment based help in each of functions (which includes examples). Example commands below if you're unsure:

```powershell
PS C:\> Get-Help "about_PSCMContentMgmt*"
PS C:\> Get-Help "Find-CMObject" -Detailed
```

Failing that:

- If you think you've experiencing, or have found, a bug in PSCMContentMgmt, please open an issue.
- Ping me on Twitter ([@codaamok](https://twitter.com/codaamok))
- Come to the [WinAdmins Discord](https://winadmins.io) and bug me there, my handle is @acc.
