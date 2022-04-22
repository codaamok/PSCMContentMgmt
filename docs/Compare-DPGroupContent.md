---
external help file: PSCMContentMgmt-help.xml
Module Name: PSCMContentMgmt
online version:
schema: 2.0.0
---

# Compare-DPGroupContent

## SYNOPSIS
Returns a list of content objects missing from the given target distribution point group compared to the source distribution point group.

## SYNTAX

```
Compare-DPGroupContent [-Source] <String> [-Target] <String> [[-SiteServer] <String>] [[-SiteCode] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
Returns a list of content objects missing from the given target distribution poiint group compared to the source distribution poiint group.

This function calls Get-DPGroupContent for both -Source and -Target.
The results are passed to Compare-Object.
The reference object is -Source and the difference object is -Target.

## EXAMPLES

### EXAMPLE 1
```
Compare-DPGroupContent -Source "Asia DPs" -Target "Europe DPs"
```

Return content objects which are missing from Europe DPs compared to Asia DPs.

### EXAMPLE 2
```
Compare-DPGroupContent -Source "London DPs" -Target "Mancester DPs" | Start-DPGroupContentDistribution -DistributionPointGroup "Mancester DPs"
```

Compares the missing content objects in group Manchester DPs compared to London DPs, and distributes them to distribution point group Manchester DPs.

### EXAMPLE 3
```
Compare-DPGroupContent -Source "London DPs" -Target "Mancester DPs" | Remove-DPGroupContent
```

Compares the missing content objects in group Manchester DPs compared to London DPs, and removes them from distribution point group London DPs.

Use -DistributionPointGroup with Remove-DPGroupContent to either explicitly target London DPs or some other group.
In this example, London DPs is the implicit target distribution point group as it reads the DistributionPointGroup passed through the pipeline.

## PARAMETERS

### -Source
Name of the referencing distribution point group you want to query.

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
Name of the differencing distribution point group you want to query.

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
