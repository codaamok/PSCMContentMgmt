---
external help file: PSCMContentMgmt-help.xml
Module Name: PSCMContentMgmt
online version:
schema: 2.0.0
---

# Invoke-DPContentLibraryCleanup

## SYNOPSIS
Invoke the ContentLibraryCleanup.exe utility against a distribution point.

## SYNTAX

```
Invoke-DPContentLibraryCleanup [-DistributionPoint] <String> [[-ContentLibraryCleanupExe] <String>] [-Delete]
 [[-SiteServer] <String>] [[-SiteCode] <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Invoke the ContentLibraryCleanup.exe utility against a distribution point.

This is essentially just a wrapper for the binary.

Worth noting that omitting the -Delete parameter is the equivilant of omitting the "/delete" parameter for the binary too.
In other words, without -Delete it will just report on orphaned content and not delete it.

## EXAMPLES

### EXAMPLE 1
```
Invoke-DPContentLibraryCleanup.ps1 -DistributionPoint "dp1.contoso.com"
```

Queries "dp1.contoso.com" for orphaned content.
Because of the missing -Delete parameter, data will not be deleted.

### EXAMPLE 2
```
Invoke-DPContentLibraryCleanup.ps1 -DistributionPoint "dp1.contoso.com" -ContentLibraryCleanupExe "C:\Sources\ContentLibraryCleanup.exe" -Delete
```

Deletes orphaned content on "dp1.contoso.com".
Uses binary "C:\Sources\ContentLibraryCleanup.exe".

## PARAMETERS

### -DistributionPoint
Name of the distribution point (as it appears in Configuration Manager, usually FQDN) you want to clean up.

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

### -ContentLibraryCleanupExe
Absolute path to ContentLibraryCleanup.exe.

The function attempts to discover the location of this exe, however if it is unable to find it you will receive a terminating error and asked to use this parameter.

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

### -Delete
Deletes orphaned content.

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

### System.Array of System.String
## NOTES

## RELATED LINKS
