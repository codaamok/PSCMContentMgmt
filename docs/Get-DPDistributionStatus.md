---
external help file: PSCMContentMgmt-help.xml
Module Name: PSCMContentMgmt
online version:
schema: 2.0.0
---

# Get-DPDistributionStatus

## SYNOPSIS
Retrieve the content distribution status of all content objects for a distribution point.

## SYNTAX

```
Get-DPDistributionStatus [-DistributionPoint] <String[]> [-Distributed] [-DistributionPending]
 [-DistributionRetrying] [-DistributionFailed] [-RemovalPending] [-RemovalRetrying] [-RemovalFailed]
 [-ContentUpdating] [-ContentMonitoring] [[-SiteServer] <String>] [[-SiteCode] <String>] [<CommonParameters>]
```

## DESCRIPTION
Retrieve the content distribution status of all content objects for a distribution point.

## EXAMPLES

### EXAMPLE 1
```
Get-DPDistributionStatus -DistributionPoint "dp1.contoso.com"
```

Gets the content distribution status for all content objects on dp1.contoso.com.

### EXAMPLE 2
```
Get-DPDistributionStatus -DistributionPoint "dp1.contoso.com" | Start-DPContentRedistribution
```

Gets the content distribution status for content objects in DistributionFailed state on dp1.contoso.com and initiates redisitribution for each of those content objects.

### EXAMPLE 3
```
Get-DP | Get-DPDistributionStatus -DistributionFailed | Group-Object -Property DistributionPoint
```

Return all distribution points, their associated failed distribution tasks and group the results by distribution point name for an overview.

## PARAMETERS

### -DistributionPoint
Name of distribution point(s) (as it appears in Configuration Manager, usually FQDN) you want to query.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: Name, ServerName

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Distributed
Filter on content objects in distributed state

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

### -DistributionPending
Filter on content objects in distribution pending state

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

### -DistributionRetrying
Filter on content objects in distribution retrying state

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

### -DistributionFailed
Filter on content objects in distribution failed state

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

### -RemovalPending
Filter on content objects in removal pending state

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

### -RemovalRetrying
Filter on content objects in removal retrying state

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

### -RemovalFailed
Filter on content objects in removal failed state

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

### -ContentUpdating
Filter on content objects in content updating state

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

### -ContentMonitoring
Filter on content objects in content monitoring state

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
