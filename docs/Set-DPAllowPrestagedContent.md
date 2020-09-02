---
external help file: PSCMContentMgmt-help.xml
Module Name: PSCMContentMgmt
online version:
schema: 2.0.0
---

# Set-DPAllowPrestagedContent

## SYNOPSIS
Configure the allow prestage content setting for a distribution point.

## SYNTAX

```
Set-DPAllowPrestagedContent [-DistributionPoint] <String> [[-State] <Boolean>] [[-SiteServer] <String>]
 [[-SiteCode] <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Configure the allow prestage content setting for a distribution point.

This can be useful if you are intending to use Export-DPContent and Import-DPContent for a distribution point content library migration.
If this is your intent, ensure you first configure your distribution point to allow prestage content using this function, distribute the content objects you want to import (see Start-DPContentDistribution) and then you should use Import-DPContent.

## EXAMPLES

### EXAMPLE 1
```
Set-DPAllowPrestageContent -DistributionPoint "dp1.contoso.com" -State $true -WhatIf
```

Enables dp1.contoso.com to allow prestaged content.

## PARAMETERS

### -DistributionPoint
Name of distribution point (as it appears in Configuration Manager, usually FQDN) you want to change the setting on.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -State
A boolean value, $true configures the distribution point to allow prestage contet whereas $false removes the config.

This is the equivilant of checking the box in the distribution point's properties for "Enables this distribution point for prestaged content".
Checked = $true, unchecked = $false.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -SiteServer
It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteServer variable which is the default value for this parameter.

Specify this to query an alternative server, or if the module import process was unable to auto-detect and set $CMSiteServer.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: $CMSiteServer
Accept pipeline input: False
Accept wildcard characters: False
```

### -SiteCode
Site code of which the server specified by -SiteServer belongs to.

It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteCode variable which is the default value for this parameter.

Specify this to query an alternative site, or if the module import process was unable to auto-detect and set $CMSiteCode.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: $CMSiteCode
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

### This function does not accept pipeline input.
## OUTPUTS

### System.Management.Automation.PSObject
## NOTES

## RELATED LINKS
