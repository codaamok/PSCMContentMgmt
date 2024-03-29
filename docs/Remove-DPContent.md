---
external help file: PSCMContentMgmt-help.xml
Module Name: PSCMContentMgmt
online version:
schema: 2.0.0
---

# Remove-DPContent

## SYNOPSIS
Remove content objects from distribution point(s).

## SYNTAX

### InputObject
```
Remove-DPContent -InputObject <PSObject[]> [-DistributionPoint <String>] [-SiteServer <String>]
 [-SiteCode <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### SpecifyProperties
```
Remove-DPContent -ObjectID <String> -ObjectType <SMS_DPContentInfo> -DistributionPoint <String>
 [-SiteServer <String>] [-SiteCode <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Remove content objects from distribution point(s).

## EXAMPLES

### EXAMPLE 1
```
Get-DPContent -DistributionPoint "dp.contoso.com" | Remove-DPContent -WhatIf
```

Removes all content from the distribution point dp.contoso.com

### EXAMPLE 2
```
Get-DPContent -DistributionPoint "dp.contoso.com" | Remove-DPContent -DistributionPoint "anotherdp.contoso.com" -WhatIf
```

Removes all content found on distribution point dp.contoso.com from the distribution point anotherdp.contoso.com.

### EXAMPLE 3
```
Remove-DPContent -ObjectID "17014765" -ObjectType "Application" -DistributionPoint "dp.contoso.com" -WhatIf
```

Removes application with CI_ID value of 17014765 from distribution point dp.contoso.com.

## PARAMETERS

### -InputObject
A PSObject type "PSCMContentMgmt" generated by Get-DPContent

```yaml
Type: PSObject[]
Parameter Sets: InputObject
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ObjectID
Unique ID of the content object you want to remove.

For Applications the ID must be the CI_ID value whereas for all other content objects the ID is PackageID.

When using this parameter you must also use ObjectType.

```yaml
Type: String
Parameter Sets: SpecifyProperties
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ObjectType
Object type of the content object you want to remove.

Can be one of the following values: "Package", "DriverPackage", "DeploymentPackage", "OperatingSystemImage", "OperatingSystemInstaller", "BootImage", "Application".

When using this parameter you must also use ObjectID.

```yaml
Type: SMS_DPContentInfo
Parameter Sets: SpecifyProperties
Aliases:
Accepted values: Package, DriverPackage, TaskSequence, DeploymentPackage, OperatingSystemImage, BootImage, OperatingSystemInstaller, Application

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DistributionPoint
Name of distribution point (as it appears in Configuration Manager, usually FQDN) you want to remove content from.

```yaml
Type: String
Parameter Sets: InputObject
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: SpecifyProperties
Aliases:

Required: True
Position: Named
Default value: None
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
Position: Named
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
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Management.Automation.PSObject
## OUTPUTS

### System.Management.Automation.PSObject
## NOTES

## RELATED LINKS
