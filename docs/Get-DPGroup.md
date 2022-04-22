---
external help file: PSCMContentMgmt-help.xml
Module Name: PSCMContentMgmt
online version:
schema: 2.0.0
---

# Get-DPGroup

## SYNOPSIS
Find distribution point group(s) by name.
If nothing is returned, no match was found.
% wildcard accepted.

## SYNTAX

```
Get-DPGroup [[-Name] <String[]>] [[-Exclude] <String[]>] [[-SiteServer] <String>] [[-SiteCode] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
Find distribution point group(s) by name.
If nothing is returned, no match was found.
% wildcard accepted.

## EXAMPLES

### EXAMPLE 1
```
Get-DPGroup
```

Return all distribution point groups within the site.

### EXAMPLE 2
```
Get-DPGroup -Name "All%" -Exclude "London%"
```

Return all distribution point groups where their Name starts with All but exclude those where their name starts with London.

### EXAMPLE 3
```
Get-DPGroup -Name "All DPs" | Get-DPGroupContent
```

Get all the content associated with the distribution point group All DPs.

## PARAMETERS

### -Name
Name of distribution point group(s) you want to search for.
This does not have to be an exact match of how it appears in Configuration Manager, you can leverage the % wildcard character.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Exclude
Name of distribution point group(s) you want to exclude from the search.
This does not have to be an exact match of how it appears in Configuration Manager, you can leverage the % wildcard character.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
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
Position: 3
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
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### This function does not accept pipeline input.
## OUTPUTS

### Microsoft.Management.Infrastructure.CimInstance#SMS_DistributionPointGroup
## NOTES

## RELATED LINKS
