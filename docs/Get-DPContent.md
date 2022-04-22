---
external help file: PSCMContentMgmt-help.xml
Module Name: PSCMContentMgmt
online version:
schema: 2.0.0
---

# Get-DPContent

## SYNOPSIS
Get all content distributed to a given distribution point.

## SYNTAX

```
Get-DPContent [-DistributionPoint] <String[]> [-Package] [-DriverPackage] [-DeploymentPackage]
 [-OperatingSystemImage] [-OperatingSystemInstaller] [-BootImage] [-Application] [[-SiteServer] <String>]
 [[-SiteCode] <String>] [<CommonParameters>]
```

## DESCRIPTION
Get all content distributed to a given distribution point.

By default this function returns all content object types that match the given distribution point in the SMS_DPContentInfo class on the site server.

You can filter the content objects by cumulatively using the available switches, e.g.
using -Package -DriverPackage will return packages and driver packages.

Properties returned are: ObjectName, Description, ObjectType, ObjectID, SourceSize, DistributionPoint.

## EXAMPLES

### EXAMPLE 1
```
Get-DPContent -Name dp.contoso.com -Package -Application
```

Return all packages and applications found on dp.contoso.com.s

### EXAMPLE 2
```
Get-DP -Name "London%" | Get-DPContent
```

Return all content objects found on distribution points where their ServerName starts with "London".

## PARAMETERS

### -DistributionPoint
Name of distribution point (as it appears in Configuration Manager, usually FQDN) you want to query.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: Name

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Package
Filter on packages

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -DriverPackage
Filter on driver packages

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -DeploymentPackage
Filter on deployment packages

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -OperatingSystemImage
Filter on Operating System images

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -OperatingSystemInstaller
Filter on Operating System upgrade images

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -BootImage
Filter on boot images

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Application
Filter on applications

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -SiteServer
FQDN address of the site server (SMS Provider). 

You only need to use this parameter once for any function of PSCMContentMgmt that also has a -SiteServer parameter.
PSCMContentMgmt remembers the site server for subsequent commands, unless you specify the parameter again to change site server.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SiteCode
Site code of which the server specified by -SiteServer belongs to.

You only need to use this parameter once for any function of PSCMContentMgmt that also has a -SiteCode parameter.
PSCMContentMgmt remembers the site code for subsequent commands, unless you specify the parameter again to change site code.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String[]
## OUTPUTS

### System.Management.Automation.PSObject
## NOTES

## RELATED LINKS
