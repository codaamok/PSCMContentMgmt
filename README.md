# PSCMContentMgmt

PowerShell module used for managing Microsoft Endpoint Manager Configuration Manager distribution point content.

## Functions

- Find-CMObject
- Compare-DPContent
- Compare-DPGroupContent
- Export-DPContent
- Get-DPContent
- Get-DPDistributionStatus
- Get-DPGroupContent
- Import-DPContent
- Invoke-DPContentLibraryCleanup
- Remove-DPContent
- Remove-DPGroupContent
- Set-DPAllowPrestagedContent
- Start-DPContentDistribution
- Start-DPGroupContentDistribution

## Getting started

Install and import:

```powershell
Install-Module PSCMContentMgmt -Scope CurrentUSer
Import-Module PSCMContentMgmt
```

If you receive a warning along the lines of being unable to auto-populate variables `$CMSiteServer` or `$CMSiteCode`, that means the module failed to sniff the registry on your location machine to find your site server's FQDN, and/or read the site server's SMS_ProviderLocation class to retrieve your site code. 

If you receive either of these warnings, use `-SiteServer` and `-SiteCode` parameters which are available for all functions or set `$CMSiteServer` and `$CMSiteCode` in your session.

The registry key it attempts to read for your site server's FQDN is `HKLM:\SOFTWARE\WOW6432Node\Microsoft\ConfigMgr10\AdminUI\Connection` which is used by the Configuration Manager console.

## Examples

```powershell
PS C:\> Compare-DPContent -Source "dp1.contoso.com" -Target "dp2.contoso.com"

ObjectName        : 2020-03-1809
Description       :
ObjectType        : DeploymentPackage
ObjectID          : ACC000F3
SourceSize        : 324981
DistributionPoint : dp1.contoso.com

ObjectName        : 2020-02-1809
Description       :
ObjectType        : DeploymentPackage
ObjectID          : ACC000F4
SourceSize        : 292894
DistributionPoint : dp1.contoso.com

...
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
PS C:\> Get-DPContent -DistributionPoint "OldDP.contoso.com" | Export-DPContent -Folder "\\NewDP.contoso.com\export$"

PS C:\> Set-DPAllowPrestagedContent -DistributionPoint "NewDP.contoso.com" -State $true

PS C:\> Start-DPContentDistribution -Folder "\\NewDP.contoso.com\export$" -DistributionPoint "NewDP.contoso.com"

PS C:\> # log in to NewDP.contoso.com

PS C:\> $env:ComputerName
NewDP

PS C:\> Import-DPContent -Folder "E:\export"
```

Migrate Distribution Points by exporting all content on OldDP.contoso.com and import the .pkgx files to NewDP.contoso.com (note that `Import-DPContent` must be ran localhost on the ideal server).

_Note: in an ideal world you'll use Pull Distribution Points to stand up a new DP beside another, but this is another method if that isn't an option for you._

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
