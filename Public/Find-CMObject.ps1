function Find-CMOBject {
    <#
    .SYNOPSIS
        A "searcher" function to find Configuration Manager objects which match a given ID.
    .DESCRIPTION
        A "searcher" function to find Configuration Manager objects which match a given ID. The ID can be anything - the function will attempt to determine to ID type based on its structure using regex, and looking for objects based on its predicted type.
        
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
    .EXAMPLE
        PS C:\> Find-CMObject -ID "ACC00048"

        Finds any object which has the PackageID "ACC00048", this includes applications, collections, driver packages, boot images, OS images, OS upgrade images, task sequences and deployment packages.
    .EXAMPLE 
        PS C:\> Find-CMObject -ID "17007122"

        Finds any object which has the CI_ID "17007122", this includes applications, deployment types, drivers, configuration items and configuration baselines.
    .EXAMPLE
        PS C:\> Find-CMObject -ID "ScopeId_B3FF3CC4-0319-4434-9D24-77689C53C615/Application_197d8de7-022d-4c0b-aec4-c339ccc17ba4"

        Finds an application which matches the ModelName "ScopeId_B3FF3CC4-0319-4434-9D24-77689C53C615/Application_197d8de7-022d-4c0b-aec4-c339ccc17ba4"
    .EXAMPLE
        PS C:\> Find-CMObject -ID "ScopeId_B3FF3CC4-0319-4434-9D24-77689C53C615/DeploymentType_328afa1b-6fdb-4f13-8133-f97aab8edff2"

        Find a deployment type which matches the ModelName "ScopeId_B3FF3CC4-0319-4434-9D24-77689C53C615/DeploymentType_328afa1b-6fdb-4f13-8133-f97aab8edff2"
    .EXAMPLE
        PS C:\> Find-CMObject -ID "ScopeId_B3FF3CC4-0319-4434-9D24-77689C53C615/Baseline_0fc5de89-80c9-4a0e-8f92-7a3a99cfe747"

        Finds a configuration baseline which matches the ModelName "ScopeId_B3FF3CC4-0319-4434-9D24-77689C53C615/Baseline_0fc5de89-80c9-4a0e-8f92-7a3a99cfe747"
    .EXAMPLE
        PS C:\> Find-CMObject -ID "ScopeId_B3FF3CC4-0319-4434-9D24-77689C53C615/LogicalName_3a7dc9c1-3bd1-4cc3-b750-30cc9debe1ec"

        Finds a configuration item which matches the ModelName "ScopeId_B3FF3CC4-0319-4434-9D24-77689C53C615/LogicalName_3a7dc9c1-3bd1-4cc3-b750-30cc9debe1ec"
    .EXAMPLE
        PS C:\> Find-CMOBject -ID "SCOPEID_B3FF3CC4-0319-4434-9D24-77689C53C615/DRIVER_4E2772AE8A92D353896D69ECCA435728C4B44957_180B604588D114D354CFF75148B012319F39A8EB8F7C5AB10C21084AEA14F0D5"
        
        Finds a driver which matches the ModelName "SCOPEID_B3FF3CC4-0319-4434-9D24-77689C53C615/DRIVER_4E2772AE8A92D353896D69ECCA435728C4B44957_180B604588D114D354CFF75148B012319F39A8EB8F7C5AB10C21084AEA14F0D5"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String[]]$ID,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SiteServer = $CMSiteServer,
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SiteCode = $CMSiteCode
    )
    begin {
        switch ($null) {
            $SiteCode {
                Write-Error -Message "Please supply a site code using the -SiteCode parameter" -Category "InvalidArgument" -ErrorAction "Stop"
            }
            $SiteServer {
                Write-Error -Message "Please supply a site server FQDN address using the -SiteServer parameter" -Category "InvalidArgument" -ErrorAction "Stop"
            }
        }

        $GetCimInstanceSplat = @{
            ComputerName    = $SiteServer
            Namespace       = "ROOT/SMS/Site_{0}" -f $SiteCode 
        }
    }
    process {
        :parent switch -Regex ($ID) {
            "^ScopeId_[\w-]+\/Application_[\w-]+$" { # ModelName for application
                Find-CMApplication -ModelName $_ -CimParams $GetCimInstanceSplat
            }
            "^ScopeId_[\w-]+\/DeploymentType_[\w-]+$" { # ModelName for deployment type
                Find-CMDeploymentType -ModelName $_ -CimParams $GetCimInstanceSplat
            }
            "^ScopeId_[\w-]+\/DRIVER_[\w_]+$" { # ModelName for drivers
                Find-CMDriver -ModelName $_ -CimParams $GetCimInstanceSplat
            }
            "^ScopeId_[\w-]+\/(LogicalName|Baseline)_[\w-]+$" { # ModelName for CI or CB
                Find-CMCICB -ModelName $_ -CimParams $GetCimInstanceSplat
            }
            "^[0-9]{8}$" { # CI_ID for CI/CB, application, deployment type or driver
                $r = Find-CMCICB -CI_ID $_ -CimParams $GetCimInstanceSplat
                if ($r -is [Object]) { $r; continue parent }
                $r = Find-CMApplication -CI_ID $_ -CimParams $GetCimInstanceSplat
                if ($r -is [Object]) { $r; continue parent }
                $r = Find-CMDeploymentType -CI_ID $_ -CimParams $GetCimInstanceSplat
                if ($r -is [Object]) { $r; continue parent }
                $r = Find-CMDriver -CI_ID $_ -CimParams $GetCimInstanceSplat
                if ($r -is [Object]) { $r; continue parent }
            }
            ("^({0}|SMS)(\w){{5}}$" -f $SiteCode) { # PackageID (or IDs of similar structure, e.g. collections) for each of the objects listed in the $Classes array below
                $ObjectId = $_

                $Classes = @(
                    "SMS_Package"
                    "SMS_DriverPackage"
                    "SMS_ImagePackage"
                    "SMS_OperatingSystemInstallPackage"
                    "SMS_BootImagePackage"
                    "SMS_SoftwareUpdatesPackage"
                    "SMS_TaskSequencePackage"
                    "SMS_Collection"
                    "SMS_ApplicationLatest"
                )
                
                switch ($Classes) {
                    "SMS_ApplicationLatest" {
                        # This class is deliberately last in the array because it's the most taxing
                        # To retrieve an application's PackageID, we must first gather all applications
                        # and invoke Get-CimInstance again on each application CIM object to get the PackageID property because it's a lazy property
                        $Query = "SELECT * FROM {0}" -f $_
                        $AllApplications = Get-CimInstance -Query $Query @GetCimInstanceSplat
                        
                        foreach ($Application in $AllApplications) {
                            $Properties = $Application | Get-CimInstance
                            
                            if ($Properties.PackageID -eq $ObjectId) {
                                $Application | Select-Object -Property @(
                                    @{Label="Name";Expression={$_.LocalizedDisplayName}}
                                    @{Label="Description";Expression={$_.LocalizedDescription}}
                                    @{Label="ObjectType";Expression={"Application"}}
                                    "CI_ID"
                                )
                                continue parent
                            }
                        }
                    }
                    "SMS_Collection" {
                        $Query = "SELECT Name, CollectionID, Comment, CollectionType FROM {0} WHERE CollectionID = '{1}'" -f $_, $ObjectId

                        Get-CimInstance -Query $Query @GetCimInstanceSplat | Select-Object -Property @(
                            "Name",
                            @{Label="Description";Expression={$_.Comment}}
                            @{Label="ObjectType";Expression={[SMS_Collection]$_.CollectionType}}
                            "CollectionID"
                        )
                    }
                    default {
                        $Query = "SELECT PackageID, Name, Description, PackageType FROM {0} WHERE PackageID = '{1}'" -f $_, $ObjectId
                        
                        $result = Get-Ciminstance -Query $Query @GetCimInstanceSplat | Select-Object -Property @(
                            "Name"
                            "Description"
                            @{Label="ObjectType";Expression={[SMS_DPContentInfo]$_.PackageType}}
                            "PackageID"
                        )

                        if ($result -is [Object]) {		
                            $result	
                            continue parent	
                        }
                    }
                }
            }
            default {
                # Write-Warning ("Can not determine what type of object used for '{0}'" -f $_)
            }
        }
    }
    end {
    }
}