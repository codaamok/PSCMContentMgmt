---
external help file: PSCMContentMgmt-help.xml
Module Name: PSCMContentMgmt
online version:
schema: 2.0.0
---

# Import-DPContent

## SYNOPSIS
Imports .pkgx files to the local distribution point found in the given -Folder.

## SYNTAX

```
Import-DPContent [-Folder] <String> [[-ExtractContentExe] <String>] [-ImportAllFromFolder]
 [[-SiteServer] <String>] [[-SiteCode] <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Imports .pkgx files to the local distribution point found in the given -Folder.

Must be run locally to the distribution point you're importing content to, and run as administrator (ExtractContent.exe requirement).

For further guidance on how migrate a distribution point's content library using this function, Export-DPContent and Set-DPAllowPrestagedContent, please read the CONTENT LIBRARY MIRATION section in the About help topic about_PSCMContentMgmt_ExportImport.

Import-DPContent only imports content objects which are in "pending" state in the SMS_PackageStatusDistPointsSummarizer class on the site server (in console, view objects' distribution state in Monitoring \> Distribution Status \> Content Status).

For content objects which are "pending", the function looks in the given -Folder for .pkgx files and attempts to import them by calling ExtractContent.exe with those files.

The .pkgx files in -Folder must match the file name pattern of "\<ObjectType\>_\<ObjectID\>.pkgx".
The Export-DPContent function generates .pkgx files in this format.
For example:
    512_16873723.pkgx - an Application (512, as per SMS_DPContentInfo) with CI_ID value 16873723
    258_ACC00004.pkgx - a Boot Image (258, as per SMS_DPContentInfo) with PackageID value ACC00004
    0_ACC00007.pkgx - a Package (0, as per SMS_DPContentInfo) with PackageID value ACC00007

For .pkgx file that do not match this pattern, they are skipped.

For .pkgx files that do match the pattern, but are not in the "pending" state, they are also skipped.
Use the -ImportAllFromFolder switch to always import all matching .pkgx files.

When calling this function, you are prompted for confirmation whether you want to import content to local host.
Suppress this with -Confirm:$false.

## EXAMPLES

### EXAMPLE 1
```
Import-DPContent -Folder "F:\prestaged" -WhatIf
```

Imports .pkgx files found in F:\prestaged but only if the content objects are in "pending" state.

### EXAMPLE 2
```
Import-DPContent -Folder "\\server\share\prestaged" -ImportAllFromFolder -WhatIf
```

Imports all .pkgx files found in \\\\server\share\prestaged.

## PARAMETERS

### -Folder
Folder containing .pkgx files.

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

### -ExtractContentExe
Absolute path to ExtractContent.exe.

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

### -ImportAllFromFolder
Import all .pkgx files found -Folder regardless as to whether the content object is currently in pending state or not.

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
