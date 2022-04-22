---
external help file: PSCMContentMgmt-help.xml
Module Name: PSCMContentMgmt
online version:
schema: 2.0.0
---

# Find-CMOBject

## SYNOPSIS
A "searcher" function to find Configuration Manager objects which match a given ID.

## SYNTAX

```
Find-CMOBject [-ID] <String[]> [[-SiteServer] <String>] [[-SiteCode] <String>] [<CommonParameters>]
```

## DESCRIPTION
A "searcher" function to find Configuration Manager objects which match a given ID.
The ID can be anything - the function will attempt to determine to ID type based on its structure using regex, and looking for objects based on its predicted type.

The function searches for the following objects:
    - Applications
    - Deployment Types
    - Packages
    - Drivers
    - Driver Packages
    - Boot Images
    - Operating System Images
    - Operating System Upgrade Images
    - Task Sequences
    - Configuration Items
    - Configuration Baselines
    - User Collections
    - Device Collections
    - (Software Update) Deployment Packages

## EXAMPLES

### EXAMPLE 1
```
Find-CMObject -ID "ACC00048"
```

Finds any object which has the PackageID "ACC00048", this includes applications, collections, driver packages, boot images, OS images, OS upgrade images, task sequences and deployment packages.

### EXAMPLE 2
```
Find-CMObject -ID "17007122"
```

Finds any object which has the CI_ID "17007122", this includes applications, deployment types, drivers, configuration items and configuration baselines.

### EXAMPLE 3
```
Find-CMObject -ID "ScopeId_B3FF3CC4-0319-4434-9D24-77689C53C615/Application_197d8de7-022d-4c0b-aec4-c339ccc17ba4"
```

Finds an application which matches the ModelName "ScopeId_B3FF3CC4-0319-4434-9D24-77689C53C615/Application_197d8de7-022d-4c0b-aec4-c339ccc17ba4"

### EXAMPLE 4
```
Find-CMObject -ID "ScopeId_B3FF3CC4-0319-4434-9D24-77689C53C615/DeploymentType_328afa1b-6fdb-4f13-8133-f97aab8edff2"
```

Find a deployment type which matches the ModelName "ScopeId_B3FF3CC4-0319-4434-9D24-77689C53C615/DeploymentType_328afa1b-6fdb-4f13-8133-f97aab8edff2"

### EXAMPLE 5
```
Find-CMObject -ID "ScopeId_B3FF3CC4-0319-4434-9D24-77689C53C615/Baseline_0fc5de89-80c9-4a0e-8f92-7a3a99cfe747"
```

Finds a configuration baseline which matches the ModelName "ScopeId_B3FF3CC4-0319-4434-9D24-77689C53C615/Baseline_0fc5de89-80c9-4a0e-8f92-7a3a99cfe747"

### EXAMPLE 6
```
Find-CMObject -ID "ScopeId_B3FF3CC4-0319-4434-9D24-77689C53C615/LogicalName_3a7dc9c1-3bd1-4cc3-b750-30cc9debe1ec"
```

Finds a configuration item which matches the ModelName "ScopeId_B3FF3CC4-0319-4434-9D24-77689C53C615/LogicalName_3a7dc9c1-3bd1-4cc3-b750-30cc9debe1ec"

### EXAMPLE 7
```
Find-CMOBject -ID "SCOPEID_B3FF3CC4-0319-4434-9D24-77689C53C615/DRIVER_4E2772AE8A92D353896D69ECCA435728C4B44957_180B604588D114D354CFF75148B012319F39A8EB8F7C5AB10C21084AEA14F0D5"
```

Finds a driver which matches the ModelName "SCOPEID_B3FF3CC4-0319-4434-9D24-77689C53C615/DRIVER_4E2772AE8A92D353896D69ECCA435728C4B44957_180B604588D114D354CFF75148B012319F39A8EB8F7C5AB10C21084AEA14F0D5"

## PARAMETERS

### -ID
The ID to search for.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
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

### This function does not accept pipeline input.
## OUTPUTS

### System.Management.Automation.PSObject
## NOTES

## RELATED LINKS
