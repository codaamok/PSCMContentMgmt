---
external help file: PSCMContentMgmt-help.xml
Module Name: PSCMContentMgmt
online version:
schema: 2.0.0
---

# Get-DP

## SYNOPSIS
Find distribution point(s) by name.
If nothing is returned, no match was found.
% wildcard accepted.

## SYNTAX

```
Get-DP [[-Name] <String[]>] [[-Exclude] <String[]>] [[-SiteServer] <String>] [[-SiteCode] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
Find distribution point(s) by name.
If nothing is returned, no match was found.
% wildcard accepted.

## EXAMPLES

### EXAMPLE 1
```
Get-DP
```

Return all disttribution points within the site.

### EXAMPLE 2
```
Get-DP -Name "SERVERA%", "SERVERB%" -Exclude "%CMG%"
```

Return distribution points which have a ServerName property starting with SERVERA or SERVERB, but excluding any that match CMG anywhere in its name.

### EXAMPLE 3
```
Get-DP | Get-DPDistributionStatus -DistributionFailed | Group-Object -Property Name
```

Return all distribution points, their associated failed distribution tasks and group the results by distribution point now for an overview.

### EXAMPLE 4
```
Get-DP -Name "London%" | Get-DPContent
```

Return all content objects found on distribution points where their ServerName starts with "London".

## PARAMETERS

### -Name
Name of distribution point(s) you want to search for.
This does not have to be an exact match of how it appears in Configuration Manager (usually FQDN), you can leverage the % wildcard character.

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
Name of distribution point(s) you want to exclude from the search.
This does not have to be an exact match of how it appears in Configuration Manager (usually FQDN), you can leverage the % wildcard character.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### This function does not accept pipeline input.
## OUTPUTS

### Microsoft.Management.Infrastructure.CimInstance#SMS_DistributionPointInfo
## NOTES

## RELATED LINKS
