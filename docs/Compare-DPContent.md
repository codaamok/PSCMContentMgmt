---
external help file: PSCMContentMgmt-help.xml
Module Name: PSCMContentMgmt
online version:
schema: 2.0.0
---

# Compare-DPContent

## SYNOPSIS
Returns a list of content objects missing from the given target server compared to the source server.

## SYNTAX

```
Compare-DPContent [-Source] <String> [-Target] <String> [[-SiteServer] <String>] [[-SiteCode] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
Returns a list of content objects missing from the given target server compared to the source server.

This function calls Get-DPContent for both -Source and -Target.
The results are passed to Compare-Object.
The reference object is -Source and the difference object is -Target.

## EXAMPLES

### EXAMPLE 1
```
Compare-DPContent -Source "dp1.contoso.com" -Target "dp2.contoso.com"
```

Return content objects which are missing from dp2.contoso.com compared to dp1.contoso.com.

### EXAMPLE 2
```
Compare-DPContent -Source "dp1.contoso.com" -Target "dp2.contoso.com" | Start-DPContentDistribution -DistributionPoint "dp2.contoso.com"
```

Compares the missing content objects on dp2.contoso.com to dp1.contoso.com, and distributes them to dp2.contoso.com.

### EXAMPLE 3
```
Compare-DPContent -Source "dp1.contoso.com" -Target "dp2.contoso.com" | Remove-DPContent
```

Compares the missing content objects on dp2.contoso.com to dp1.contoso.com, and removes them from distribution point dp1.contoso.com.

Use -DistributionPoint with Remove-DPContent to either explicitly target dp1.contoso.com or some other group.
In this example, dp1.contoso.com is the implicit target distribution point group as it reads the DistributionPointGroup property passed through the pipeline.

## PARAMETERS

### -Source
Name of the referencing distribution point (as it appears in Configuration Manager, usually FQDN) you want to query.

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

### -Target
Name of the differencing distribution point (as it appears in Configuration Manager, usually FQDN) you want to query.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
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

### System.Management.Automation.PSObject
## NOTES

## RELATED LINKS
