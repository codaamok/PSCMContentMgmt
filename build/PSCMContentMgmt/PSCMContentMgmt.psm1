#region Private functions
function ConvertTo-ModelNameCIID {
    <#
    .SYNOPSIS
        Get a ConfigMgr Application's CI_ID property from the given ModelName property
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$ModelName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$SiteServer,
        
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$SiteCode
    )
    begin {
        $Namespace = "ROOT/SMS/Site_{0}" -f $SiteCode
    }
    process {
        $Query = "SELECT CI_ID FROM SMS_ApplicationLatest WHERE ModelName = '{0}'" -f $ModelName
        (Get-CimInstance -ComputerName $SiteServer -Namespace $Namespace -Query $Query).CI_ID
    }
    end {

    }
}

function ConvertTo-PackageIDCIID {
    <#
    .SYNOPSIS
        Get a ConfigMgr Application's CI_ID property from the given PackageID property
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$PackageID,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$SiteServer,
        
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$SiteCode
    )
    begin {
        $Namespace = "ROOT/SMS/Site_{0}" -f $SiteCode
    }
    process {
        $Query = "SELECT SMS_ApplicationLatest.CI_ID 
        FROM SMS_ApplicationLatest
        WHERE SMS_ApplicationLatest.ModelName in (
            SELECT SMS_PackageStatusDistPointsSummarizer.SecureObjectID 
            FROM SMS_PackageStatusDistPointsSummarizer 
            WHERE PackageID = '{0}'
        )" -f $PackageID
        (Get-CimInstance -ComputerName $SiteServer -Namespace $Namespace -Query $Query).CI_ID
    }
    end {

    }
}

function Find-CMApplication {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName="ModelName")]
        [String]$ModelName,
        [Parameter(Mandatory, ParameterSetName="CI_ID")]
        [String]$CI_ID,
        [Parameter(Mandatory)]
        [Hashtable]$CimParams
    )

    $Query = "SELECT CI_ID,LocalizedDisplayName,LocalizedDescription FROM SMS_ApplicationLatest WHERE {0} = '{1}'" -f $PSCmdlet.ParameterSetName, (Get-Variable -Name $PSCmdlet.ParameterSetName).Value
    Get-CimInstance -Query $Query @CimParams | Select-Object -Property @(
        @{Label="Name";Expression={$_.LocalizedDisplayName}}
        @{Label="Description";Expression={$_.LocalizedDescription}}
        @{Label="ObjectType";Expression={"Application"}}
        "CI_ID"
    )
}

function Find-CMCICB {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName="ModelName")]
        [String]$ModelName,
        [Parameter(Mandatory, ParameterSetName="CI_ID")]
        [String]$CI_ID,
        [Parameter(Mandatory)]
        [Hashtable]$CimParams
    )
    $Query = "SELECT CI_ID,LocalizedDisplayName,CIType_ID FROM SMS_ConfigurationItemLatest WHERE {0} = '{1}'" -f $PSCmdlet.ParameterSetName, (Get-Variable -Name $PSCmdlet.ParameterSetName).Value
    Get-CimInstance -Query $Query @CimParams | Select-Object -Property @(
        @{Label="Name";Expression={$_.LocalizedDisplayName}}
        @{Label="Description";Expression={$_.LocalizedDescription}}
        @{Label="ObjectType";Expression={[SMS_ConfigurationItemLatest_CIType_ID]$_.CIType_ID}}
        "CI_ID"
    )
}

function Find-CMDeploymentType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName="ModelName")]
        [String]$ModelName,
        [Parameter(Mandatory, ParameterSetName="CI_ID")]
        [String]$CI_ID,
        [Parameter(Mandatory)]
        [Hashtable]$CimParams
    )
    $Query = "SELECT AppModelName,CI_ID,LocalizedDisplayName FROM SMS_DeploymentType WHERE IsLatest = 'True' AND {0} = '{1}'" -f $PSCmdlet.ParameterSetNAme, (Get-Variable -Name $PSCmdlet.ParameterSetName).Value
    Get-CimInstance -Query $Query @CimParams | Select-Object -Property @(
        @{Label="Name";Expression={$_.LocalizedDisplayName}}
        @{Label="Description";Expression={$_.LocalizedDescription}}
        @{Label="ObjectType";Expression={"DeploymentType"}}
        "CI_ID"
        @{Label="AppCIID";Expression={ConvertTo-ModelNameCIID -ModelName $_.AppModelName -SiteServer $SiteServer -SiteCode $SiteCode}}
    )
}

function Find-CMDriver {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName="ModelName")]
        [String]$ModelName,
        [Parameter(Mandatory, ParameterSetName="CI_ID")]
        [String]$CI_ID,
        [Parameter(Mandatory)]
        [Hashtable]$CimParams
    )
    $Query = "SELECT CI_ID,LocalizedDisplayName FROM SMS_Driver WHERE {0} = '{1}'" -f $PSCmdlet.ParameterSetNAme, (Get-Variable -Name $PSCmdlet.ParameterSetName).Value
    Get-Ciminstance -Query $Query @CimParams | Select-Object -Property @(
        @{Label="Name";Expression={$_.LocalizedDisplayName}}
        @{Label="Description";Expression={$_.LocalizedDescription}}
        @{Label="ObjectType";Expression={"Driver"}}
        "CI_ID"
    )
}

function Invoke-NativeCommand {
    <#
    .SYNOPSIS
        Invoke a native command (.exe) as a new process.
        
    .DESCRIPTION
        Invoke-NativeCommand executes an arbitrary executable as a new process. Both the standard
        and error output streams are redirected.
        
        Error out is written as a single non-terminating error. ErrorAction can be used to raise
        this as a terminating error.
    
    .EXAMPLE
        Invoke-NativeCommand git clone repo-uri -ErrorAction "Stop"
        
        Run the git command to clone repo-uri. Raise a terminating error if the command fails.
    #>

    [CmdletBinding()]
    param (
        <#
            The command line to execute. This parameter is named to attempt to avoid conflicts with
            parameters for the executing command line.
        #>
        [Parameter(Position = 1, ValueFromRemainingArguments, ValueFromPipeline)]
        $__CommandLine
    )

    process {
        $command, $argumentList = $__CommandLine

        try {
            $process = [System.Diagnostics.Process]@{
                StartInfo = [System.Diagnostics.ProcessStartInfo]@{
                    FileName               = (Get-Command $command -ErrorAction "Stop").Source
                    Arguments              = $argumentList
                    WorkingDirectory       = $pwd
                    RedirectStandardOutput = $true
                    RedirectStandardError  = $true
                    UseShellExecute        = $false
                }
            }
            $null = $process.Start()
            $process.WaitForExit()

            while (-not $process.StandardOutput.EndOfStream) {
                $process.StandardOutput.ReadToEnd()
            }

            while (-not $process.StandardError.EndOfStream) {
                Write-Error $process.StandardError.ReadToEnd()
            }
        } catch {
            Write-Error -ErrorRecord $_
        }
    }
}

function Resolve-DP {
    <#
    .SYNOPSIS
        Validate whether a given host is a distribution point within a Configuration Manager site
    .DESCRIPTION
        Validate whether a given host is a distribution point within a Configuration Manager site
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]$Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$SiteServer,
        
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$SiteCode
    )
    begin {
        $OriginalLocation = (Get-Location).Path

        if($null -eq (Get-PSDrive -Name $SiteCode -PSProvider "CMSite" -ErrorAction "SilentlyContinue")) {
            $null = New-PSDrive -Name $SiteCode -PSProvider "CMSite" -Root $SiteServer -ErrorAction "Stop"
        }

        Set-Location ("{0}:\" -f $SiteCode) -ErrorAction "Stop"
    }
    process {
        try {
            $Obj = Get-CMDistributionPoint -Name $Name -AllSite -ErrorAction "Stop"
            if (-not $Obj) {
                throw ("Distribution point '{0}' does not exist" -f $Name)
            }
        }
        catch {
            Set-Location $OriginalLocation 
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    end {
        Set-Location $OriginalLocation   
    }
}

function Resolve-DPGroup {
    <#
    .SYNOPSIS
        Validate whether a distribution point group exists within a Configuration Manager site
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]$Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$SiteServer,
        
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$SiteCode
    )
    begin {
        $OriginalLocation = (Get-Location).Path

        if($null -eq (Get-PSDrive -Name $SiteCode -PSProvider "CMSite" -ErrorAction "SilentlyContinue")) {
            $null = New-PSDrive -Name $SiteCode -PSProvider "CMSite" -Root $SiteServer -ErrorAction "Stop"
        }

        Set-Location ("{0}:\" -f $SiteCode) -ErrorAction "Stop"
    }
    process {
        try {
            $Obj = Get-CMDistributionPointGroup -Name $Name -ErrorAction "Stop"
            if (-not $Obj) {
                throw ("Distribution point group '{0}' does not exist" -f $Name)
            }
        }
        catch {
            Set-Location $OriginalLocation 
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    end {
        Set-Location $OriginalLocation   
    }
}
#endregion Private functions

#region Public functions
function Compare-DPContent {
    <#
    .SYNOPSIS
        Returns a list of content objects missing from the given target server compared to the source server.
    .PARAMETER Source
        Name of the referencing distribution point (as it appears in ConfigMgr, usually FQDN) you want to query.
    .PARAMETER Target
        Name of the differencing distribution point (as it appears in ConfigMgr, usually FQDN) you want to query.
    .PARAMETER SiteServer
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteServer variable which is the default value for this parameter.

        Specify this to query an alternative server, or if the module import process was unable to auto-detect and set $CMSiteServer.
    .PARAMETER SiteCode
        Site code of which the server specified by -SiteServer belongs to.

        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteCode variable which is the default value for this parameter.
        
        Specify this to query an alternative site, or if the module import process was unable to auto-detect and set $CMSiteCode.
    .EXAMPLE
        PS C:\> Compare-DPContent -Source "dp1.contoso.com" -Target "dp2.contoso.com"

        Return content objects which are missing from "dp2.contoso.com" compared to "dp1.contoso.com".
    .EXAMPLE
        PS C:\> Compare-DPContent -Source "dp1.contoso.com" -Target "dp2.contoso.com" | Start-DPContentDistribution -DistributionPoint "dp2.contoso.com"

        Compares the missing content objects on "dp2.contoso.com" compared to "dp1.contoso.com", and distributes them to "dp2.contoso.com"
    .EXAMPLE
        PS C:\> Compare-DPContent -Source "dp1.contoso.com" -Target "dp2.contoso.com" | Remove-DPContent 

        Compares the missing content objects in "dp2.contoso.com" compared to "dp1.contoso.com", and removes them from distribution point "dp1.contoso.com".

        Use -DistributionPoint with Remove-DPContent to either explicitly target "dp1.contoso.com" or some other group. In this example, "dp1.contoso.com" is the implicit target distribution point group as it reads the DistributionPointGroup property return from Compare-DPGroupContent.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Source,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Target,

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

        try {
            Resolve-DP -Name $Source -SiteServer $SiteServer -SiteCode $SiteCode
            Resolve-DP -Name $Target -SiteServer $SiteServer -SiteCode $SiteCode
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    process {
        $SourceContent = Get-DPContent -DistributionPoint $Source -SiteServer $SiteServer -SiteCode $SiteCode
        $TargetContent = Get-DPContent -DistributionPoint $Target -SiteServer $SiteServer -SiteCode $SiteCode
    
        Compare-Object -ReferenceObject @($SourceContent) -DifferenceObject @($TargetContent) -Property ObjectID -PassThru | ForEach-Object {
            if ($_.SideIndicator -eq "<=") {
                [PSCustomObject]@{
                    PSTypeName        = "PSCMContentMgmt"
                    ObjectName        = $_.ObjectName
                    Description       = $_.Description
                    ObjectType        = [SMS_DPContentInfo]$_.ObjectType
                    ObjectID          = $_.ObjectID
                    SourceSize        = $_.SourceSize
                    DistributionPoint = $_.DistributionPoint
                }  
            }
        }
    }
    end {
    }    
}

function Compare-DPGroupContent {
    <#
    .SYNOPSIS
        Returns a list of content objects missing from the given target server compared to the source server.
    .PARAMETER Source
        Name of the referencing distribution point group you want to query.
    .PARAMETER Target
        Name of the differencing distribution point group you want to query.
    .PARAMETER SiteServer
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteServer variable which is the default value for this parameter.

        Specify this to query an alternative server, or if the module import process was unable to auto-detect and set $CMSiteServer.
    .PARAMETER SiteCode
        Site code of which the server specified by -SiteServer belongs to.

        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteCode variable which is the default value for this parameter.
        
        Specify this to query an alternative site, or if the module import process was unable to auto-detect and set $CMSiteCode.
    .EXAMPLE
        PS C:\> Compare-DPGroupContent -Source "Asia DPs" -Target "Europe DPs"

        Return content objects which are missing from "Europe DPs" compared to "Asia DPs"
    .EXAMPLE
        PS C:\> Compare-DPGroupContent -Source "London DPs" -Target "Mancester DPs" | Start-DPGroupContentDistribution -DistributionPointGroup "Mancester DPs"

        Compares the missing content objects in group Manchester DPs compared to "London DPs", and distributes them to distribution point group Manchester DPs.
    .EXAMPLE
        PS C:\> Compare-DPGroupContent -Source "London DPs" -Target "Mancester DPs" | Remove-DPGroupContent 

        Compares the missing content objects in group Manchester DPs compared to "London DPs", and removes them from distribution point group "London DPs".

        Use -DistributionPointGroup with Remove-DPGroupContent to either explicitly target "London DPs" or some other group. In this example, "London DPs" is the implicit target distribution point group as it reads the DistributionPointGroup property return from Compare-DPGroupContent.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Source,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Target,

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

        try {
            Resolve-DPGroup -Name $Source -SiteServer $SiteServer -SiteCode $SiteCode
            Resolve-DPGroup -Name $Target -SiteServer $SiteServer -SiteCode $SiteCode
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    process {
        $SourceContent = Get-DPGroupContent -DistributionPointGroup $Source -SiteServer $SiteServer -SiteCode $SiteCode
        $TargetContent = Get-DPGroupContent -DistributionPointGroup $Target -SiteServer $SiteServer -SiteCode $SiteCode
    
        Compare-Object -ReferenceObject @($SourceContent) -DifferenceObject @($TargetContent) -Property ObjectID -PassThru | ForEach-Object {
            if ($_.SideIndicator -eq "<=") {
                [PSCustomObject]@{
                    PSTypeName             = "PSCMContentMgmt"
                    ObjectName             = $_.ObjectName
                    Description            = $_.Description
                    ObjectType             = [SMS_DPContentInfo]$_.ObjectType
                    ObjectID               = $_.ObjectID
                    SourceSize             = $_.SourceSize
                    DistributionPointGroup = $_.DistributionPointGroup
                }  
            }
        }
    }
    end {
    }    
}

function Export-DPContent {
    <#
    .SYNOPSIS
        Exports distribution point content to .pkgx files 
    .PARAMETER InputObject
        A PSObject type "PSCMContentMgmt" generated by Get-DPContent
    .PARAMETER DistributionPoint
        Name of distribution point (as it appears in ConfigMgr, usually FQDN) you want to export content from.
    .PARAMETER ObjectID
        Unique ID of the content object you want to export.

        For Applications the ID must be the CI_ID value whereas for all other content objects the ID is PackageID.

        When using this parameter you must also use ObjectType.
    .PARAMETER ObjectType
        Object type of the content object you want to export.

        Can be one of the following values: "Package", "DriverPackage", "DeploymentPackage", "OperatingSystemImage", "OperatingSystemInstaller", "BootImage", "Application".

        When using this parameter you must also use ObjectID.
    .PARAMETER Folder
        The target directory to store the generated .pkgx files in.
    .PARAMETER SiteServer
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteServer variable which is the default value for this parameter.

        Specify this to query an alternative server, or if the module import process was unable to auto-detect and set $CMSiteServer.
    .PARAMETER SiteCode
        Site code of which the server specified by -SiteServer belongs to.

        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteCode variable which is the default value for this parameter.

        Specify this to query an alternative site, or if the module import process was unable to auto-detect and set $CMSiteCode.
    .EXAMPLE
        PS C:\> Get-DPContent -DistributionPoint "dp1.contoos.com" | Export-DPContent -Folder "E:\prestaged"

        Gathers all content objects on "dp1.contoso.com" and exports them to .pkgx files in E:\prestaged, overwriting any files that already exist with the same name.
    .EXAMPLE
        PS C:\> Compare-DPContent -Source "dp1.contoso.com" -Target "dp2.contoso.com" | Export-DPContent -Folder "E:\prestaged"

        Compares the missing content objects on "dp2.contoso.com" compared to "dp1.contoso.com", and exports them to "E:\prestaged".
    .EXAMPLE
        PS C:\> Export-DPContent -DistributionPoint "dp1.contoso.com" -ObjectID "P01000F6" -ObjectType "Package" -Folder "E:\prestaged"

        Exports package item P01000F6 from dp1.contoos.com and saves the exported .pkgx file in E:\prestaged.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Low")]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName="InputObject")]
        [PSTypeName('PSCMContentMgmt')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory, ParameterSetName="SpecifyProperties")]
        [ValidateNotNullOrEmpty()]
        [String]$ObjectID,

        [Parameter(Mandatory, ParameterSetName="SpecifyProperties")]
        [ValidateSet("Package","DriverPackage","DeploymentPackage","OperatingSystemImage","OperatingSystemInstaller","BootImage","Application")]
        [SMS_DPContentInfo]$ObjectType,

        [Parameter(Mandatory)]
        [ValidateScript({
            if (!([System.IO.Directory]::Exists($_))) {
                throw "Invalid path or access denied"
            } elseif (!($_ | Test-Path -PathType Container)) {
                throw "Value must be a directory, not a file"
            } else {
                return $true
            }
        })]
        [String]$Folder,

        [Parameter(Mandatory, ParameterSetName="SpecifyProperties")]
        [ValidateNotNullOrEmpty()]
        [String]$DistributionPoint,

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

        $TargetDP = $DistributionPoint

        if ($PSCmdlet.ParameterSetName -ne "InputObject") {
            $InputObject = [PSCustomObject]@{
                ObjectID          = $ObjectID
                ObjectType        = $ObjectType
                DistributionPoint = $TargetDP
            }
        }

        $OriginalLocation = (Get-Location).Path

        if($null -eq (Get-PSDrive -Name $SiteCode -PSProvider "CMSite" -ErrorAction "SilentlyContinue")) {
            $null = New-PSDrive -Name $SiteCode -PSProvider "CMSite" -Root $SiteServer -ErrorAction "Stop"
        }

        Set-Location ("{0}:\" -f $SiteCode) -ErrorAction "Stop"
    }
    process {
        try {
            foreach ($Object in $InputObject) {
                switch ($true) {
                    ($LastDP -ne $Object.DistributionPoint -And -not $PSBoundParameters.ContainsKey("DistributionPoint")) {
                        $TargetDP = $Object.DistributionPoint
                    }
                    ($LastDP -ne $TargetDP) {
                        try {
                            Resolve-DP -Name $TargetDP -SiteServer $SiteServer -SiteCode $SiteCode
                        }
                        catch {
                            Write-Error -ErrorRecord $_
                            return
                        }
                        
                        $LastDP = $TargetDP
                    }
                    default {
                        $LastDP = $TargetDP
                    }
                }

                $File = "{0}_{1}.pkgx" -f [int]$Object.ObjectType, $Object.ObjectID
                $Path = Join-Path -Path $Folder -ChildPath $File
        
                $result = @{ 
                    PSTypeName = "PSCMContentMgmtPrestage"
                    ObjectID   = $Object.ObjectID
                    ObjectType = $Object.ObjectType
                    Message    = $null
                }
        
                $Command = 'Publish-CMPrestageContent -{0} "{1}" -DistributionPointName "{2}" -FileName "{3}"' -f [SMS_DPContentInfo_CMParameters][SMS_DPContentInfo]$Object.ObjectType, $Object.ObjectID, $TargetDP, $Path
                $ScriptBlock = [ScriptBlock]::Create($Command)
                try {
                    if ($PSCmdlet.ShouldProcess(
                        ("Would export '{0}' ({1}) to '{2}'" -f $Object.ObjectID, $Object.ObjectType, $Folder),
                        "Are you sure you want to continue?",
                        ("Exporting '{0}' ({1}) to '{2}'" -f $Object.ObjectID, $Object.ObjectType, $Folder))) {
                            Invoke-Command -ScriptBlock $ScriptBlock -ErrorAction "Stop"
                            $result["Result"] = "Success"
                    }
                    else {
                        $result["Result"] = "No change"
                    }
                }
                catch {
                    Write-Error -ErrorRecord $_
                    $result["Result"] = "Failed"
                    $result["Message"] = $_.Exception.Message
                }
                
                if (-not $WhatIfPreference) { [PSCustomObject]$result }
            }
        }
        catch {
            Set-Location $OriginalLocation 
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    end {
        Set-Location $OriginalLocation
    }
}

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

function Get-DPContent {
    <#
    .SYNOPSIS
        Get all content distributed to a given distribution point by querying SMS_DPContentInfo class.
    .DESCRIPTION
        Get all content distributed to a given distribution point by querying SMS_DPContentInfo class.

        By default this function returns all content object types that match the given distribution point in the SMS_DPContentInfo class on the site server.

        You can filter the content objects by cumulatively using the available switches, e.g. using -Package -DriverPackage will return packages and driver packages.

        Properties returned are: ObjectName, Description, ObjectType, ObjectID, SourceSize, DistributionPoint.
    .PARAMETER Name
        Name of distribution point (as it appears in ConfigMgr, usually FQDN) you want to query.
    .PARAMETER Package
        Filter on packages
    .PARAMETER DriverPackage
        Filter on driver packages
    .PARAMETER DeploymentPackage
        Filter on deployment packages
    .PARAMETER OperatingSystemImage
        Filter on Operating System images
    .PARAMETER OperatingSystemInstaller
        Filter on Operating System upgrade images
    .PARAMETER BootImage
        Filter on boot images
    .PARAMETER Application
        Filter on applications
    .PARAMETER SiteServer
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteServer variable which is the default value for this parameter.
        
        Specify this to query an alternative server, or if the module import process was unable to auto-detect and set $CMSiteServer.
    .PARAMETER SiteCode
        Site code of which the server specified by -SiteServer belongs to.
        
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteCode variable which is the default value for this parameter.
        
        Specify this to query an alternative site, or if the module import process was unable to auto-detect and set $CMSiteCode.
    .EXAMPLE
        PS C:\> Get-DPContent -Name dp.contoso.com -Package -Application

        Return all packages and applications found on dp.contoso.com.s
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$DistributionPoint,

        [Parameter()]
        [Switch]$Package,

        [Parameter()]
        [Switch]$DriverPackage,
        
        [Parameter()]
        [Switch]$DeploymentPackage,
        
        [Parameter()]
        [Switch]$OperatingSystemImage,
        
        [Parameter()]
        [Switch]$OperatingSystemInstaller,
        
        [Parameter()]
        [Switch]$BootImage,
        
        [Parameter()]
        [Switch]$Application,

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
        
        try {
            Resolve-DP -Name $DistributionPoint -SiteServer $SiteServer -SiteCode $SiteCode
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    process {
        $Namespace = "ROOT/SMS/Site_{0}" -f $SiteCode
        $Query = "SELECT * FROM SMS_DPContentInfo WHERE NALPath like '%{0}%'" -f $DistributionPoint
    
        $conditions = switch ($true) {
            $Package                    { "ObjectType = '{0}'" -f [Int][SMS_DPContentInfo]"Package" }
            $DriverPackage              { "ObjectType = '{0}'" -f [Int][SMS_DPContentInfo]"DriverPackage" }
            $DeploymentPackage          { "ObjectType = '{0}'" -f [Int][SMS_DPContentInfo]"DeploymentPackage" }
            $OperatingSystemImage       { "ObjectType = '{0}'" -f [Int][SMS_DPContentInfo]"OperatingSystemImage" }
            $OperatingSystemInstaller   { "ObjectType = '{0}'" -f [Int][SMS_DPContentInfo]"OperatingSystemInstaller" }
            $BootImage                  { "ObjectType = '{0}'" -f [Int][SMS_DPContentInfo]"BootImage" }
            $Application                { "ObjectType = '{0}'" -f [Int][SMS_DPContentInfo]"Application" }
        }
    
        if ($conditions) { 
            $Query = "{0} AND ( {1} )" -f $Query, ([String]::Join(" OR ", $conditions)) 
        }
    
        Get-CimInstance -ComputerName $SiteServer -Namespace $Namespace -Query $Query -ErrorAction "Stop" | ForEach-Object {
            [PSCustomObject]@{
                PSTypeName        = "PSCMContentMgmt"
                ObjectName        = $_.Name
                Description       = $_.Description
                ObjectType        = [SMS_DPContentInfo]$_.ObjectType
                ObjectID          = $(if ($_.ObjectType -eq [SMS_DPContentInfo]"Application") {
                    ConvertTo-ModelNameCIID -ModelName $_.ObjectID -SiteServer $SiteServer -SiteCode $SiteCode
                }
                else {
                    $_.ObjectID
                })
                SourceSize        = $_.SourceSize
                DistributionPoint = $DistributionPoint
            }
        }
    }
    end {
    }
}

function Get-DPDistributionStatus {
    <#
    .SYNOPSIS
        Retrieve the content distribution status of all objects for a distribution point.
    .PARAMETER DistributionPoint
        Name of distribution point (as it appears in ConfigMgr, usually FQDN) you want to query.
    .PARAMETER Distributed
        Filter on objects in distributed state
    .PARAMETER DistributionPending
        Filter on objects in distribution pending state
    .PARAMETER DistributionRetrying
        Filter on objects in distribution retrying state
    .PARAMETER DistributionFailed
        Filter on objects in distribution failed state
    .PARAMETER RemovalPending
        Filter on objects in removal pending state
    .PARAMETER RemovalRetrying
        Filter on objects in removal retrying state
    .PARAMETER RemovalFailed
        Filter on objects in removal failed state
    .PARAMETER ContentUpdating
        Filter on objects in content updating state
    .PARAMETER ContentMonitoring
        Filter on objects in content monitoring state
    .PARAMETER SiteServer
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteServer variable which is the default value for this parameter.

        Specify this to query an alternative server, or if the module import process was unable to auto-detect and set $CMSiteServer.
    .PARAMETER SiteCode
        Site code of which the server specified by -SiteServer belongs to.

        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteCode variable which is the default value for this parameter.

        Specify this to query an alternative site, or if the module import process was unable to auto-detect and set $CMSiteCode.
    .EXAMPLE
        PS C:\> Get-DPDistributionStatus -DistributionPoint "dp1.contoso.com"

        Gets the content distribution status for all objects on "dp1.contoso.com".
    #>
    [CmdletBinding()]
    param (
        [ParameteR(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$DistributionPoint,

        [Parameter()]
        [Switch]$Distributed,

        [Parameter()]
        [Switch]$DistributionPending,

        [Parameter()]
        [Switch]$DistributionRetrying,

        [Parameter()]
        [Switch]$DistributionFailed,

        [Parameter()]
        [Switch]$RemovalPending,

        [Parameter()]
        [Switch]$RemovalRetrying,

        [Parameter()]
        [Switch]$RemovalFailed,

        [Parameter()]
        [Switch]$ContentUpdating,

        [Parameter()]
        [Switch]$ContentMonitoring,

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

        try {
            Resolve-DP -Name $DistributionPoint -SiteServer $SiteServer -SiteCode $SiteCode
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    process {
        $Namespace = "ROOT/SMS/Site_{0}" -f $SiteCode
        $Query = "SELECT PackageID,PackageType,State,SourceVersion FROM SMS_PackageStatusDistPointsSummarizer WHERE ServerNALPath like '%{0}%'" -f $DistributionPoint

        $conditions = switch ($true) {
            $Distributed            { "State = '{0}'" -f [Int][SMS_PackageStatusDistPointsSummarizer_State]"DISTRIBUTED" }
            $DistributionPending    { "State = '{0}'" -f [Int][SMS_PackageStatusDistPointsSummarizer_State]"DISTRIBUTION_PENDING" }
            $DistributionRetrying   { "State = '{0}'" -f [Int][SMS_PackageStatusDistPointsSummarizer_State]"DISTRIBUTION_RETRYING" }
            $DistributionFailed     { "State = '{0}'" -f [Int][SMS_PackageStatusDistPointsSummarizer_State]"DISTRIBUTION_FAILED" }
            $RemovalPending         { "State = '{0}'" -f [Int][SMS_PackageStatusDistPointsSummarizer_State]"REMOVAL_PENDING" }
            $RemovalRetrying        { "State = '{0}'" -f [Int][SMS_PackageStatusDistPointsSummarizer_State]"REMOVAL_RETRYING" }
            $RemovalFailed          { "State = '{0}'" -f [Int][SMS_PackageStatusDistPointsSummarizer_State]"REMOVAL_FAILED" }
            $ContentUpdating        { "State = '{0}'" -f [Int][SMS_PackageStatusDistPointsSummarizer_State]"CONTENT_UPDATING" }
            $ContentMonitoring      { "State = '{0}'" -f [Int][SMS_PackageStatusDistPointsSummarizer_State]"CONTENT_MONITORING" }
        }

        if ($conditions) {
            $Query = "{0} AND ( {1} )" -f $Query, ([String]::Join(" OR ", $conditions)) 
        }

        Get-CimInstance -ComputerName $SiteServer -Namespace $Namespace -Query $Query -ErrorAction "Stop" | ForEach-Object {
            [PSCustomObject]@{
                PSTypeName        = "PSCMContentMgmt"
                ObjectID          = $_.PackageID
                ObjectType        = [SMS_PackageStatusDistPointsSummarizer_PackageType]$_.PackageType
                State             = [SMS_PackageStatusDistPointsSummarizer_State]$_.State
                SourceVersion     = $_.SourceVersion
                DistributionPoint = $DistributionPoint
            }
        }
    }
    end {
    }
}

function Get-DPGroupContent {
    <#
    .SYNOPSIS
        Get all content distributed to a given distribution point group by querying the SMS_DPGroupContentInfo.
    .DESCRIPTION
        Get all content distributed to a given distribution point group by querying the SMS_DPGroupContentInfo.

        By default this function returns all content object types that match the given distribution point group in the SMS_DPGroupContentInfo class on the site server.

        You can filter the content objects by cumulatively using the available switches, e.g. using -Package -DriverPackage will return packages and driver packages.

        Properties returned are: ObjectName, Description, ObjectType, ObjectID, SourceSize, DistributionPoint.
    .PARAMETER Name
        Name of distribution point group you want to query.
    .PARAMETER Package
        Filter on packages
    .PARAMETER DriverPackage
        Filter on driver packages
    .PARAMETER DeploymentPackage
        Filter on deployment packages
    .PARAMETER OperatingSystemImage
        Filter on Operating System images
    .PARAMETER OperatingSystemInstaller
        Filter on Operating System upgrade images
    .PARAMETER BootImage
        Filter on boot images
    .PARAMETER Application
        Filter on applications
    .PARAMETER SiteServer
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteServer variable which is the default value for this parameter.
        
        Specify this to query an alternative server, or if the module import process was unable to auto-detect and set $CMSiteServer.
    .PARAMETER SiteCode
        Site code of which the server specified by -SiteServer belongs to.
        
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteCode variable which is the default value for this parameter.
        
        Specify this to query an alternative site, or if the module import process was unable to auto-detect and set $CMSiteCode.
    .EXAMPLE
        PS C:\> Get-DPGroupContent -Name "Asia DPs" -Package -Application

        Return all packages and applications found in the distribution point group "Asia DPs"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$DistributionPointGroup,

        [Parameter()]
        [Switch]$Package,

        [Parameter()]
        [Switch]$DriverPackage,
        
        [Parameter()]
        [Switch]$DeploymentPackage,
        
        [Parameter()]
        [Switch]$OperatingSystemImage,
        
        [Parameter()]
        [Switch]$OperatingSystemInstaller,
        
        [Parameter()]
        [Switch]$BootImage,
        
        [Parameter()]
        [Switch]$Application,

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
        
        try {
            Resolve-DPGroup -Name $DistributionPointGroup -SiteServer $SiteServer -SiteCode $SiteCode
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }        
    }
    process {
        $Namespace = "ROOT/SMS/Site_{0}" -f $SiteCode
        $Query = "SELECT * 
        FROM SMS_DPGroupContentInfo 
        WHERE SMS_DPGroupContentInfo.GroupID in (
            SELECT SMS_DPGroupInfo.GroupID
            FROM SMS_DPGroupInfo
            WHERE Name = '{0}'
        )" -f $DistributionPointGroup
    
        $conditions = switch ($true) {
            $Package                    { "ObjectType = '{0}'" -f [Int][SMS_DPContentInfo]"Package" }
            $DriverPackage              { "ObjectType = '{0}'" -f [Int][SMS_DPContentInfo]"DriverPackage" }
            $DeploymentPackage          { "ObjectType = '{0}'" -f [Int][SMS_DPContentInfo]"DeploymentPackage" }
            $OperatingSystemImage       { "ObjectType = '{0}'" -f [Int][SMS_DPContentInfo]"OperatingSystemImage" }
            $OperatingSystemInstaller   { "ObjectType = '{0}'" -f [Int][SMS_DPContentInfo]"OperatingSystemInstaller" }
            $BootImage                  { "ObjectType = '{0}'" -f [Int][SMS_DPContentInfo]"BootImage" }
            $Application                { "ObjectType = '{0}'" -f [Int][SMS_DPContentInfo]"Application" }
        }
    
        if ($conditions) { 
            $Query = "{0} AND ( {1} )" -f $Query, ([String]::Join(" OR ", $conditions)) 
        }
    
        Get-CimInstance -ComputerName $SiteServer -Namespace $Namespace -Query $Query -ErrorAction "Stop" | ForEach-Object {
            [PSCustomObject]@{
                PSTypeName             = "PSCMContentMgmt"
                ObjectName             = $_.Name
                Description            = $_.Description
                ObjectType             = [SMS_DPContentInfo]$_.ObjectType
                ObjectID               = $(if ($_.ObjectType -eq [SMS_DPContentInfo]"Application") {
                    ConvertTo-ModelNameCIID -ModelName $_.ObjectID -SiteServer $SiteServer -SiteCode $SiteCode
                }
                else {
                    $_.ObjectID
                })
                SourceSize             = $_.SourceSize
                DistributionPointGroup = $DistributionPointGroup
            }
        }
    }
    end {
    }
}

function Import-DPContent {
    <#
    .SYNOPSIS
        Imports .pkgx files to the local distribution point found in the given -Folder.

        Must be run locally to the distribution point you're importing content to, and run as administrator (ExtractContent.exe requirement).
    .DESCRIPTION
        Imports .pkgx files to the local distribution point found in the given -Folder.

        Must be run locally to the distribution point you're importing content to, and run as administrator (ExtractContent.exe requirement).

        By default, this function only imports objects which are in "pending" state in the SMS_PackageStatusDistPointsSummarizer class on the site server (in console, view objects' distribution state in Monitoring > Distribution Status > Content Status).
        
        For objects which are "pending", the function looks in the given -Folder for .pkgx files and attempts to import them by calling ExtractContent.exe with those files.
        
        The .pkgx files in -Folder must match the file name pattern of "<ObjectType>_<ObjectID>.pkgx". The Export-DPContent function generates .pkgx files in this format. For example:
            512_16873723.pkgx - an Application (512, as per SMS_DPContentInfo) with CI_ID value 16873723
            258_ACC00004.pkgx - a Boot Image (258, as per SMS_DPContentInfo) with PackageID value ACC00004
            0_ACC00007.pkgx - a Package (0, as per SMS_DPContentInfo) with PackageID value ACC00007
        
        For .pkgx file that do not match this pattern, they are skipped.
        
        For .pkgx files that do match the pattern, but are not in the "pending" state, they are also skipped. Use the -ImportAllFromFolder switch to always import all matching .pkgx files.

        When calling this function, you are prompted for confirmation whether you want to import content to local host. Suppress this with -Confirm:$false.
    .PARAMETER Folder
        Folder containing .pkgx files.
    .PARAMETER ExtractContentExe
        Absolute path to ExtractContent.exe.

        The function attempts to discover the location of this exe, however if it is unable to find it you will receive a terminating error and asked to use this parameter.
    .PARAMETER ImportAllFromFolder
        Import all .pkgx files found -Folder regardless as to whether the object is currently in pending state or not.
    .PARAMETER SiteServer       
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteServer variable which is the default value for this parameter.
        
        Specify this to query an alternative server, or if the module import process was unable to auto-detect and set $CMSiteServer.
    .PARAMETER SiteCode
        Site code of which the server specified by -SiteServer belongs to.
        
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteCode variable which is the default value for this parameter.
        
        Specify this to query an alternative site, or if the module import process was unable to auto-detect and set $CMSiteCode.
    .EXAMPLE
        PS C:\> Import-DPContent -Folder "F:\prestaged" -WhatIf

        Imports .pkgx files found in F:\prestaged but only if the objects are in "pending" state.
    .EXAMPLE
        PS C:\> Import-DPContent -Folder "\\server\share\prestaged" -ImportAllFromFolder -WhatIf

        Imports all .pkgx files found in \\server\share\prestaged.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
    param (
        [Parameter(Mandatory)]
        [ValidateScript({
            if (!([System.IO.Directory]::Exists($_))) {
                throw "Invalid path or access denied"
            } elseif (!($_ | Test-Path -PathType Container)) {
                throw "Value must be a directory, not a file"
            } else {
                return $true
            }
        })]
        [String]$Folder,

        [Parameter()]
        [ValidateScript({
            if (([System.IO.File]::Exists($_) -And ($_ -like "*ExtractContent.exe"))) {
                return $true
            } else {
                throw "Invalid path or given file is not named ExtractContent.exe"
            }
        })]
        [String]$ExtractContentExe,

        [Parameter()]
        [Switch]$ImportAllFromFolder,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SiteServer = $CMSiteServer,
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SiteCode = $CMSiteCode
    )
    begin {
        if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator") -eq $false) {
            $Exception = [UnauthorizedAccessException]::new("Must run as administrator")
            $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
                $Exception,
                "2",
                [System.Management.Automation.ErrorCategory]::PermissionDenied,
                $null
            )
            $PSCmdlet.ThrowTerminatingError($ErrorRecord)
        }

        switch ($null) {
            $SiteCode {
                Write-Error -Message "Please supply a site code using the -SiteCode parameter" -Category "InvalidArgument" -ErrorAction "Stop"
            }
            $SiteServer {
                Write-Error -Message "Please supply a site server FQDN address using the -SiteServer parameter" -Category "InvalidArgument" -ErrorAction "Stop"
            }
        }

        $DistributionPoint = [System.Net.Dns]::GetHostByName($env:ComputerName).HostName        

        try {
            Resolve-DP -Name $DistributionPoint -SiteServer $SiteServer -SiteCode $SiteCode
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }

        # Get-PSDrive instead of Get-Volume because of UAC
        :loop foreach ($Volume in (Get-PSDrive -PSProvider "FileSystem")) {
            $Paths = @(
                "{0}SMS_DP$\sms\Tools\ExtractContent.exe" -f $Volume.Root
                "{0}SMS_DP$\ExtractContent.exe" -f $Volume.Root
            )

            foreach ($Path in $Paths) {
                try {
                    if (Test-Path $Path -ErrorAction "Stop") {
                        $ExtractContentExe = $Path
                        break loop
                    }
                }
                catch [System.UnauthorizedAccessException] {
                    Write-Error -Message ("Access denied finding ExtractContent.exe in {0}" -f (Split-Path -Parent $Path)) -Category "PermissionDenied" -CategoryTargetName $Path
                }
                catch {
                    Write-Error -ErrorRecord $_
                }
            }
        }

        if (-not $ExtractContentExe) {
            $Exception = [System.IO.FileNotFoundException]::new("Could not find ExtractContent.exe on disk, please use -ExtractContentExe parameter")
            $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
                $Exception,
                "2",
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                $null
            )
            $PSCmdlet.ThrowTerminatingError($ErrorRecord)
        }

        try {
            if ($ImportAllFromFolder.IsPresent -eq $true) {
                $Files = Get-ChildItem -Path $Folder -Filter "*.pkgx" -ErrorAction "Stop"
            }
            else {
                $Namespace = "ROOT/SMS/Site_{0}" -f $SiteCode
                $Filter = "ServerNALPath like '%{0}%'" -f $DistributionPoint
                $ObjPackagesPending = (Get-CimInstance -ComputerName $SiteServer -Namespace $Namespace -ClassName "SMS_PackageStatusDistPointsSummarizer" -Filter $Filter -ErrorAction "Stop").Where{ $_.State -ne 0 }
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    process {
        if ($ImportAllFromFolder.IsPresent -eq $true) {
            foreach ($File in $Files) {
                if ($File.Name -match "^(?<ObjectType>0|3|5|257|258|259|512)_(?<ObjectID>[A-Za-z0-9]+)\.pkgx$") {

                    $result = @{ 
                        PSTypeName = "PSCMContentMgmtImport"
                        ObjectID   = $Matches.ObjectID
                        ObjectType = [SMS_DPContentInfo]$Matches.ObjectType
                        Message    = $null
                    }

                    try {
                        if ($PSCmdlet.ShouldProcess(
                            ("Would import {0} {1} ({2}) to '{3}'" -f [SMS_DPContentInfo]$Matches.ObjectType, $Matches.ObjectID, $File.Name, $env:ComputerName),
                            "Are you sure you want to continue?",
                            ("Warning: Importing {0} {1} ({2}) to '{3}'" -f [SMS_DPContentInfo]$Matches.ObjectType, $Matches.ObjectID, $File.Name, $env:ComputerName))) {
                                $null = Invoke-NativeCommand $ExtractContentExe /p:$($File.FullName) /F -ErrorAction "Stop"
                                $result["Result"] = "Success"
                        }
                        else {
                            $result["Result"] = "No change"
                        }   
                    }
                    catch {
                        Write-Error -ErrorRecord $_
                        $result["Result"] = "Failed"
                        $result["Message"] = $_.Exception.Message
                    }
                    
                    if (-not $WhatIfPreference) { [PSCustomObject]$result }
                }
                else {
                    Write-Warning ("File '{0}' is not identifiable, skipping" -f $File.Name)
                }
            }
        }
        else {
            foreach ($ObjPackage in $ObjPackagesPending) {
                # All of the object type values between SMS_DPContentInfo and SMS_PackageStatusDistPointsSummarizer are similar except for Application
                $ObjectType = ([SMS_DPContentInfo]([SMS_PackageStatusDistPointsSummarizer_PackageType]$ObjPackage.PackageType).ToString()).value__
    
                if ($ObjectType -eq [SMS_DPContentInfo]"Application") {
                    $ObjectID = ConvertTo-PackageIDCIID -PackageID $ObjPackage.PackageID -SiteServer $SiteServer -SiteCode $SiteCode
                }
                else {
                    $ObjectID = $ObjPackage.PackageID
                }
    
                $FileName = "{0}_{1}.pkgx" -f $ObjectType, $ObjectID
                $Path = Join-Path -Path $Folder -ChildPath $FileName
    
                if (Test-Path $Path) {
                    $result = @{ 
                        PSTypeName = "PSCMContentMgmtImport"
                        ObjectID   = $ObjectID
                        ObjectType = [SMS_DPContentInfo]$ObjectType
                        Message    = $null
                    }

                    try {
                        if ($PSCmdlet.ShouldProcess(
                            ("Would import {0} {1} ({2}) to '{3}'" -f [SMS_DPContentInfo]$ObjectType, $ObjectID, $FileName, $env:ComputerName),
                            "Are you sure you want to continue?",
                            ("Warning: Importing {0} {1} ({2}) to '{3}'" -f [SMS_DPContentInfo]$ObjectType, $ObjectID, $FileName, $env:ComputerName))) {
                                $null = Invoke-NativeCommand $ExtractContentExe /p:$Path /F -ErrorAction "Stop"
                                $result["Result"] = "Success"
                        }
                        else {
                            $result["Result"] = "No change"
                        }
                    }
                    catch {
                        Write-Error -ErrorRecord $_
                        $result["Result"] = "Failed"
                        $result["Message"] = $_.Exception.Message
                    }

                    if (-not $WhatIfPreference) { [PSCustomObject]$result }
                }
                else {
                    Write-Warning ("Could not find '{0}' ({1}) '{2}'" -f $ObjectID, [SMS_DPContentInfo]$ObjectType, $Path)
                }
            }
        }
    }
    end {
    }
}

function Invoke-DPContentLibraryCleanup {
    <#
    .SYNOPSIS
        Invoke the ContentLibraryCleanup.exe utility against a distribution point.
    .DESCRIPTION
        Invoke the ContentLibraryCleanup.exe utility against a distribution point.

        This is essentially just a wrapper for the binary.

        Worth noting that omitting the -Delete parameter is the equivilant of omitting the "/delete" parameter for the binary too. In other words, without -Delete it will just report on orphaned content and not delete it.
    .PARAMETER DistributionPoint
        Name of the distribution point (as it appears in ConfigMgr, usually FQDN) you want to clean up.
    .PARAMETER ContentLibraryCleanupExe
        Absolute path to ContentLibraryCleanup.exe.

        The function attempts to discover the location of this exe, however if it is unable to find it you will receive a terminating error and asked to use this parameter.
    .PARAMETER Delete
        Deletes orphaned content.
    .PARAMETER SiteServer        
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteServer variable which is the default value for this parameter.
        
        Specify this to query an alternative server, or if the module import process was unable to auto-detect and set $CMSiteServer.
    .PARAMETER SiteCode
        Site code of which the server specified by -SiteServer belongs to.
        
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteCode variable which is the default value for this parameter.
        
        Specify this to query an alternative site, or if the module import process was unable to auto-detect and set $CMSiteCode.
    .EXAMPLE
        PS C:\> Invoke-DPContentLibraryCleanup.ps1 -DistributionPoint "dp1.contoso.com"

        Queries "dp1.contoso.com" for orphaned content. Because of the missing -Delete parameter, data will not be deleted.
    .EXAMPLE
        PS C:\> Invoke-DPContentLibraryCleanup.ps1 -DistributionPoint "dp1.contoso.com" -ContentLibraryCleanupExe "C:\Sources\ContentLibraryCleanup.exe" -Delete

        Deletes orphaned content on "dp1.contoso.com". Uses binary "C:\Sources\ContentLibraryCleanup.exe".
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$DistributionPoint,

        [Parameter()]
        [ValidateScript({
            if (([System.IO.File]::Exists($_) -And ($_ -like "*ContentLibraryCleanup.exe"))) {
                return $true
            } else {
                throw "Invalid path or given file is not named ContentLibraryCleanup.exe"
            }
        })]
        [String]$ContentLibraryCleanupExe,

        [Parameter()]
        [Switch]$Delete,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SiteServer = $CMSiteServer,
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SiteCode = $CMSiteCode
    )
    begin {
        if ($DistributionPoint.StartsWith($env:ComputerName)) {
            if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator") -eq $false) {
                $Exception = [UnauthorizedAccessException]::new("Must run as administrator")
                $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $Exception,
                    "2",
                    [System.Management.Automation.ErrorCategory]::PermissionDenied,
                    $null
                )
                $PSCmdlet.ThrowTerminatingError($ErrorRecord)
            }
        }

        try {
            Resolve-DP -Name $DistributionPoint -SiteServer $SiteServer -SiteCode $SiteCode
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }

        $Namespace = "ROOT/SMS/Site_{0}" -f $SiteCode
        $Query = "SELECT InstallDir FROM SMS_Site WHERE SiteCode = '{0}'" -f $SiteCode

        try {
            $SiteInstallPath = (Get-CimInstance -ComputerName $SiteServer -Namespace $Namespace -Query $Query -ErrorAction "Stop").InstallDir
        }
        catch {
            Write-Error -ErrorRecord $_
        }

        $Paths = @(
            "\\{0}\SMS_{1}\cd.latest\SMSSETUP\TOOLS\ContentLibraryCleanup\ContentLibraryCleanup.exe" -f $SiteServer, $SiteCode
            "{0}\cd.latest\SMSSETUP\TOOLS\ContentLibraryCleanup\ContentLibraryCleanup.exe" -f $SiteInstallPath
        )
        
        foreach ($Path in $Paths) {
            try {
                if (Test-Path $Path -ErrorAction "Stop") {
                    $ContentLibraryCleanupExe = $Path
                }
            }
            catch [System.UnauthorizedAccessException] {
                Write-Error -Message ("Access denied finding ContentLibraryCleanup.exe in {0}" -f (Split-Path -Parent $Path)) -Category "PermissionDenied" -CategoryTargetName $Path
            }
            catch {
                Write-Error -ErrorRecord $_
            }
        }

        if (-not $ContentLibraryCleanupExe) {
            $Exception = [System.IO.FileNotFoundException]::new("Could not find ContentLibraryCleanup.exe, please use -ContentLibraryCleanupExe parameter")
            $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
                $Exception,
                "2",
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                $null
            )
            $PSCmdlet.ThrowTerminatingError($ErrorRecord)
        }
    }
    process {
        if ($Delete.IsPresent) {
            if ($PSCmdlet.ShouldProcess(
                ("Would perform content library cleanup on '{0}'" -f $DistributionPoint),
                "Are you sure you want to continue?",
                ("Warning: calling ContentLibraryCleanup.exe against '{0}' with /delete parameter" -f $DistributionPoint))) {
                    $pArgs = "/dp", $DistributionPoint, "/q", "/delete"
                    & $Path $pArgs
            }
        }
        else {
            $pArgs = "/dp", $DistributionPoint, "/q" 
            & $Path $pArgs
        }
    }
    end {
    }
}

function Remove-DPContent {
    <#
    .SYNOPSIS
        Remove objects from a distribution point
    .PARAMETER InputObject
        A PSObject type "PSCMContentMgmt" generated by Get-DPContent
    .PARAMETER DistributionPoint
        Name of distribution point (as it appears in ConfigMgr, usually FQDN) you want to remove content from.
    .PARAMETER ObjectID
        Unique ID of the content object you want to remove.

        For Applications the ID must be the CI_ID value whereas for all other content objects the ID is PackageID.

        When using this parameter you must also use ObjectType.
    .PARAMETER ObjectType
        Object type of the content object you want to remove.

        Can be one of the following values: "Package", "DriverPackage", "DeploymentPackage", "OperatingSystemImage", "OperatingSystemInstaller", "BootImage", "Application".

        When using this parameter you must also use ObjectID.
    .PARAMETER SiteServer
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteServer variable which is the default value for this parameter.
        
        Specify this to query an alternative server, or if the module import process was unable to auto-detect and set $CMSiteServer.
    .PARAMETER SiteCode
        Site code of which the server specified by -SiteServer belongs to.
        
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteCode variable which is the default value for this parameter.
        
        Specify this to query an alternative site, or if the module import process was unable to auto-detect and set $CMSiteCode.
    .EXAMPLE 
        PS C:\> Get-DPContent -DistributionPoint "dp.contoso.com" | Remove-DPContent -WhatIf

        Removes all content from the distribution point "dp.contoso.com"
    .EXAMPLE 
        PS C:\> Get-DPContent -DistributionPoint "dp.contoso.com" | Remove-DPContent -DistributionPoint "anotherdp.contoso.com" -WhatIf

        Removes all content found on distribution point "dp.contoso.com" from the distribution point "anotherdp.contoso.com"
    .EXAMPLE
        PS C:\> Remove-DPContent -ObjectID "17014765" -ObjectType "Application" -DistributionPoint "dp.contoso.com" -WhatIf

        Removes application with CI_ID value of "17014765" from distribution point "dp.contoso.com"
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName="InputObject")]
        [PSTypeName('PSCMContentMgmt')]
        [PSCustomObject[]]$InputObject,

        [Parameter(Mandatory, ParameterSetName="SpecifyProperties")]
        [ValidateNotNullOrEmpty()]
        [String]$ObjectID,

        [Parameter(Mandatory, ParameterSetName="SpecifyProperties")]
        [ValidateSet("Package","DriverPackage","DeploymentPackage","OperatingSystemImage","OperatingSystemInstaller","BootImage","Application")]
        [SMS_DPContentInfo]$ObjectType,

        [Parameter(ParameterSetName="InputObject")]
        [Parameter(Mandatory, ParameterSetName="SpecifyProperties")]
        [ValidateNotNullOrEmpty()]
        [String]$DistributionPoint,

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

        $TargetDP = $DistributionPoint

        if ($PSCmdlet.ParameterSetName -ne "InputObject") {
            $InputObject = [PSCustomObject]@{
                ObjectID          = $ObjectID
                ObjectType        = $ObjectType
                DistributionPoint = $TargetDP
            }
        }

        $OriginalLocation = (Get-Location).Path

        if($null -eq (Get-PSDrive -Name $SiteCode -PSProvider "CMSite" -ErrorAction "SilentlyContinue")) {
            $null = New-PSDrive -Name $SiteCode -PSProvider "CMSite" -Root $SiteServer -ErrorAction "Stop"
        }

        Set-Location ("{0}:\" -f $SiteCode) -ErrorAction "Stop"
    }
    process {
        try {
            foreach ($Object in $InputObject) {   
                switch ($true) {
                    ($LastDP -ne $Object.DistributionPoint -And -not $PSBoundParameters.ContainsKey("DistributionPoint")) {
                        $TargetDP = $Object.DistributionPoint
                    }
                    ($LastDP -ne $TargetDP) {
                        try {
                            Resolve-DP -Name $TargetDP -SiteServer $SiteServer -SiteCode $SiteCode
                        }
                        catch {
                            Write-Error -ErrorRecord $_
                            return
                        }
                        
                        $LastDP = $TargetDP
                    }
                    default {
                        $LastDP = $TargetDP
                    }
                }

                $result = @{ 
                    PSTypeName = "PSCMContentMgmtRemove"
                    ObjectID   = $Object.ObjectID
                    ObjectType = $Object.ObjectType
                    Message    = $null
                }
                
                $Command = 'Remove-CMContentDistribution -DistributionPointName "{0}" -{1} "{2}" -Force -ErrorAction "Stop"' -f $TargetDP, [SMS_DPContentInfo_CMParameters][SMS_DPContentInfo]$Object.ObjectType, $Object.ObjectID
                $ScriptBlock = [ScriptBlock]::Create($Command)
                try {
                    if ($PSCmdlet.ShouldProcess(
                        ("Would remove '{0}' ({1}) from '{2}'" -f $Object.ObjectID, $Object.ObjectType, $TargetDP),
                        "Are you sure you want to continue?",
                        ("Removing '{0}' ({1}) from '{2}'" -f $Object.ObjectID, $Object.ObjectType, $TargetDP))) {
                            Invoke-Command -ScriptBlock $ScriptBlock -ErrorAction "Stop"
                            $result["Result"] = "Success"
                    }
                    else {
                        $result["Result"] = "No change"
                    }
                }
                catch {
                    Write-Error -ErrorRecord $_
                    $result["Result"] = "Failed"
                    $result["Message"] = $_.Exception.Message
                }
                
                if (-not $WhatIfPreference) { [PSCustomObject]$result }
            }
        }
        catch {
            Set-Location $OriginalLocation 
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    end {
        Set-Location $OriginalLocation
    }
}

function Remove-DPGroupContent {
    <#
    .SYNOPSIS
        Remove objects from a distribution point group
    .PARAMETER InputObject
        A PSObject type "PSCMContentMgmt" generated by Get-DPContent
    .PARAMETER DistributionPointGroup
        Name of distribution point group you want to remove content from.
    .PARAMETER ObjectID
        Unique ID of the content object you want to remove.

        For Applications the ID must be the CI_ID value whereas for all other content objects the ID is PackageID.

        When using this parameter you must also use ObjectType.
    .PARAMETER ObjectType
        Object type of the content object you want to remove.

        Can be one of the following values: "Package", "DriverPackage", "DeploymentPackage", "OperatingSystemImage", "OperatingSystemInstaller", "BootImage", "Application".

        When using this parameter you must also use ObjectID.
    .PARAMETER SiteServer
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteServer variable which is the default value for this parameter.
        
        Specify this to query an alternative server, or if the module import process was unable to auto-detect and set $CMSiteServer.
    .PARAMETER SiteCode
        Site code of which the server specified by -SiteServer belongs to.
        
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteCode variable which is the default value for this parameter.
        
        Specify this to query an alternative site, or if the module import process was unable to auto-detect and set $CMSiteCode.
    .EXAMPLE 
        PS C:\> Get-DPGroupContent -DistributionPointGroup "Asia DPs" | Remove-DPGroupContent -WhatIf

        Removes all content from the distribution point group "Asia DPs"
    .EXAMPLE
        PS C:\> Remove-DPGroupContent -ObjectID "17014765" -ObjectType "Application" -DistributionPointGroup "Asia DPs" -WhatIf

        Removes application with CI_ID value of "17014765" from distribution point group "Asia DPs"
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName="InputObject")]
        [PSTypeName('PSCMContentMgmt')]
        [PSCustomObject[]]$InputObject,

        [Parameter(Mandatory, ParameterSetName="SpecifyProperties")]
        [ValidateNotNullOrEmpty()]
        [String]$ObjectID,

        [Parameter(Mandatory, ParameterSetName="SpecifyProperties")]
        [ValidateSet("Package","DriverPackage","DeploymentPackage","OperatingSystemImage","OperatingSystemInstaller","BootImage","Application")]
        [SMS_DPContentInfo]$ObjectType,

        [Parameter(ParameterSetName="InputObject")]
        [Parameter(Mandatory, ParameterSetName="SpecifyProperties")]
        [ValidateNotNullOrEmpty()]
        [String]$DistributionPointGroup,

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

        $TargetDPGroup = $DistributionPointGroup

        if ($PSCmdlet.ParameterSetName -ne "InputObject") {
            $InputObject = [PSCustomObject]@{
                ObjectID               = $ObjectID
                ObjectType             = $ObjectType
                DistributionPointGroup = $TargetDPGroup
            }
        }
        
        $OriginalLocation = (Get-Location).Path

        if($null -eq (Get-PSDrive -Name $SiteCode -PSProvider "CMSite" -ErrorAction "SilentlyContinue")) {
            $null = New-PSDrive -Name $SiteCode -PSProvider "CMSite" -Root $SiteServer -ErrorAction "Stop"
        }

        Set-Location ("{0}:\" -f $SiteCode) -ErrorAction "Stop"
    }
    process {
        try {
            foreach ($Object in $InputObject) {
                switch ($true) {
                    ($LastDPGroup -ne $Object.DistributionPointGroup -And -not $PSBoundParameters.ContainsKey("DistributionPointGroup")) {
                        $TargetDPGroup = $Object.DistributionPointGroup
                    }
                    ($LastDPGroup -ne $TargetDPGroup) {
                        try {
                            Resolve-DPGroup -Name $TargetDPGroup -SiteServer $SiteServer -SiteCode $SiteCode
                        }
                        catch {
                            Write-Error -ErrorRecord $_
                            return
                        }
                        
                        $LastDPGroup = $TargetDPGroup
                    }
                    default {
                        $LastDPGroup = $TargetDPGroup
                    }
                }
                
                $result = @{ 
                    PSTypeName             = "PSCMContentMgmtRemove"
                    ObjectID               = $Object.ObjectID
                    ObjectType             = $Object.ObjectType
                    DistributionPointGroup = $TargetDPGroup
                    Message                = $null
                }
                
                $Command = 'Remove-CMContentDistribution -DistributionPointGroupName "{0}" -{1} "{2}" -Force -ErrorAction "Stop"' -f $TargetDPGroup, [SMS_DPContentInfo_CMParameters][SMS_DPContentInfo]$Object.ObjectType, $Object.ObjectID
                $ScriptBlock = [ScriptBlock]::Create($Command)
                try {
                    if ($PSCmdlet.ShouldProcess(
                        ("Would remove '{0}' ({1}) from '{2}'" -f $Object.ObjectID, $Object.ObjectType, $TargetDPGroup),
                        "Are you sure you want to continue?",
                        ("Removing '{0}' ({1}) from '{2}'" -f $Object.ObjectID, $Object.ObjectType, $TargetDPGroup))) {
                            Invoke-Command -ScriptBlock $ScriptBlock -ErrorAction "Stop"
                            $result["Result"] = "Success"
                    }
                    else {
                        $result["Result"] = "No change"
                    }
                }
                catch {
                    Write-Error -ErrorRecord $_
                    $result["Result"] = "Failed"
                    $result["Message"] = $_.Exception.Message
                }
                
                if (-not $WhatIfPreference) { [PSCustomObject]$result }
            }
        }
        catch {
            Set-Location $OriginalLocation 
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    end {
        Set-Location $OriginalLocation
    }
}

function Set-DPAllowPrestagedContent {
    <#
    .SYNOPSIS
        Configure the allow prestage content setting for a distribution point
    .PARAMETER DistributionPoint
        Name of distribution point (as it appears in ConfigMgr, usually FQDN) you want to change the setting on.
    .PARAMETER State
        A boolean value, $true configures the distribution point to allow prestage contet whereas $false removes the config.

        This is the equivilant of checking the box in the distribution point's properties for "Enables this distribution point for prestaged content". Checked = $true, unchecked = $false.
    .PARAMETER SiteServer
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteServer variable which is the default value for this parameter.
        
        Specify this to query an alternative server, or if the module import process was unable to auto-detect and set $CMSiteServer.
    .PARAMETER SiteCode
        Site code of which the server specified by -SiteServer belongs to.
        
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteCode variable which is the default value for this parameter.
        
        Specify this to query an alternative site, or if the module import process was unable to auto-detect and set $CMSiteCode.
    .EXAMPLE
        PS C:\> Set-DPAllowPrestageContent -DistributionPoint "dp1.contoso.com" -State $true -WhatIf

        Enables "dp1.contoso.com" to allow prestaged content.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$DistributionPoint,

        [Parameter()]
        [Bool]$State = $true,

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

        try {
            Resolve-DP -Name $DistributionPoint -SiteServer $SiteServer -SiteCode $SiteCode
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }

        $Action = switch ($State) {
            $true { "enable" }
            $false { "disable" }
        }

        $OriginalLocation = (Get-Location).Path

        if($null -eq (Get-PSDrive -Name $SiteCode -PSProvider "CMSite" -ErrorAction "SilentlyContinue")) {
            $null = New-PSDrive -Name $SiteCode -PSProvider "CMSite" -Root $SiteServer -ErrorAction "Stop"
        }

        Set-Location ("{0}:\" -f $SiteCode) -ErrorAction "Stop"
    }
    process {
        try {
            $result = @{
                PSTypeName        = "PSCMContentMgmtPrestageSetting"
                DistributionPoint = $DistributionPoint
                Message           = $null
            }
            try {
                if ($PSCmdlet.ShouldProcess(
                    ("Would {0} allowing prestage content on '{1}'" -f $Action, $DistributionPoint),
                    "Are you sure you want to continue?",
                    ("Warning: Changing allow prestage setting to {0}d for '{1}'" -f $Action, $DistributionPoint))) {
                        Set-CMDistributionPoint -SiteSystemServerName $DistributionPoint -AllowPreStaging $State
                        $result["Result"] = "Success"
                }
                else {
                    $result["Result"] = "No change"
                }
            }
            catch {
                Write-Error -ErrorRecord $_
                $result["Result"] = "Failed"
                $result["Message"] = $_.Exception.Message
            }
            
            if (-not $WhatIfPreference) { [PSCustomObject]$result }
        }
        catch {
            Set-Location $OriginalLocation 
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    end {
        Set-Location $OriginalLocation
    }
}

function Start-DPContentDistribution {
    <#
    .SYNOPSIS
        Distributes objects to a given distribution point. The function can accept input object from Get-DPContent, by manually specifying -ObjectID and -ObjectType or by using -Folder where it will distribute all objects for .pkgx files found in said folder.
    .PARAMETER InputObject
        A PSObject type "PSCMContentMgmt" generated by Get-DPContent
    .PARAMETER DistributionPoint
        Name of distribution point (as it appears in ConfigMgr, usually FQDN) you want to distribute objects to.
    .PARAMETER ObjectID
        Unique ID of the content object you want to distribute.

        For Applications the ID must be the CI_ID value whereas for all other content objects the ID is PackageID.

        When using this parameter you must also use ObjectType.
    .PARAMETER ObjectType
        Object type of the content object you want to distribute.

        Can be one of the following values: "Package", "DriverPackage", "DeploymentPackage", "OperatingSystemImage", "OperatingSystemInstaller", "BootImage", "Application".

        When using this parameter you must also use ObjectID.
    .PARAMETER Folder
        For all .pkgx files in this folder that use the following naming convention "<ObjectType>_<ObjectID>.pkgx", distribute the <ObjectID> of type <ObjectType> to -DistributionPoint.

        This can be useful if you have a folder filled with .pkgx files, generated by Export-DPContent, and want to distribute those objects to a distribution point.
    .PARAMETER SiteServer
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteServer variable which is the default value for this parameter.
        
        Specify this to query an alternative server, or if the module import process was unable to auto-detect and set $CMSiteServer.
    .PARAMETER SiteCode
        Site code of which the server specified by -SiteServer belongs to.
        
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteCode variable which is the default value for this parameter.
        
        Specify this to query an alternative site, or if the module import process was unable to auto-detect and set $CMSiteCode.
    .EXAMPLE
        PS C:\> Compare-DPContent -Source "dp1.contoso.com" -Target "dp2.contoso.com" | Start-DPContentDistribution -DistributionPoint "dp2.contoso.com" -WhatIf

        Compares the missing content objects on "dp2.contoso.com" compared to "dp1.contoso.com", and distributes them to "dp2.contoso.com".
    .EXAMPLE
        PS C:\> Start-DPContentDistribution -Folder "E:\exported" -DistributionPoint "dp2.contoso.com" -WhatIf

        For all .pkgx files in folder "E:\exported" that use the following naming convention "<ObjectType>_<ObjectID>.pkgx", distributes them to "dp2.contoso.com".
    .EXAMPLE
        PS C:\> Start-DPContentDistribution -ObjectID ACC00007 -ObjectType Package -DistributionPoint "dp2.contoso.com" -WhatIf
        
        Nothing more than a wrapper for Start-CMContentDistribution. Distributes package ACC00007 to "dp2.contoso.com".
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName="InputObject")]
        [PSTypeName('PSCMContentMgmt')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory, ParameterSetName="Properties")]
        [ValidateNotNullOrEmpty()]
        [String]$ObjectID,

        [Parameter(Mandatory, ParameterSetName="Properties")]
        [ValidateSet("Package","DriverPackage","DeploymentPackage","OperatingSystemImage","OperatingSystemInstaller","BootImage","Application")]
        [SMS_DPContentInfo]$ObjectType,

        [Parameter(Mandatory, ParameterSetName="Folder")]
        [ValidateScript({
            if (!([System.IO.Directory]::Exists($_))) {
                throw "Invalid path or access denied"
            } elseif (!($_ | Test-Path -PathType Container)) {
                throw "Value must be a directory, not a file"
            } else {
                return $true
            }
        })]
        [String]$Folder,

        [Parameter(ParameterSetName="InputObject")]
        [Parameter(Mandatory, ParameterSetName="Properties")]
        [Parameter(Mandatory, ParameterSetName="Folder")]
        [ValidateNotNullOrEmpty()]
        [String]$DistributionPoint,

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

        $TargetDP = $DistributionPoint

        if ($PSCmdlet.ParameterSetName -ne "InputObject") {
            $InputObject = [PSCustomObject]@{
                ObjectID          = $ObjectID
                ObjectType        = $ObjectType
                Distributionpoint = $TargetDP
            }
        }

        if ($PSCmdlet.ParameterSetName -eq "Folder") {
            $Files = Get-ChildItem -Path $Folder -Filter "*.pkgx"

            try {
                Resolve-DP -Name $TargetDP -SiteServer $SiteServer -SiteCode $SiteCode
            }
            catch {
                $PSCmdlet.ThrowTerminatingError($_)
            }
        }

        $OriginalLocation = (Get-Location).Path

        if ($null -eq (Get-PSDrive -Name $SiteCode -PSProvider "CMSite" -ErrorAction "SilentlyContinue")) {
            $null = New-PSDrive -Name $SiteCode -PSProvider "CMSite" -Root $SiteServer -ErrorAction "Stop"
        }

        Set-Location ("{0}:\" -f $SiteCode) -ErrorAction "Stop"
    }
    process {
        try {
            switch ($PSCmdlet.ParameterSetName) {
                "Folder" {
                    foreach ($File in $Files) {
                        if ($File.Name -match "^(?<ObjectType>0|3|5|257|258|259|512)_(?<ObjectID>[A-Za-z0-9]+)\.pkgx$") {
                            $InputObject = [PSCustomObject]@{
                                ObjectID   = $Matches.ObjectID
                                ObjectType = $Matches.ObjectType
                            }
        
                            $result = @{
                                PSTypeName = "PSCMContentMgmtDistribute" 
                                ObjectID   = $InputObject.ObjectID
                                ObjectType = [SMS_DPContentInfo]$InputObject.ObjectType
                                Message    = $null
                            }

                            $Command = 'Start-CMContentDistribution -{0} "{1}" -DistributionPointName "{2}" -ErrorAction "Stop"' -f [SMS_DPContentInfo_CMParameters][SMS_DPContentInfo]$InputObject.ObjectType, $InputObject.ObjectID, $TargetDP
                            $ScriptBlock = [ScriptBlock]::Create($Command)
                            try {
                                if ($PSCmdlet.ShouldProcess(
                                    ("Would distribute '{0}' ({1}) to '{2}'" -f $InputObject.ObjectID, [SMS_DPContentInfo]$InputObject.ObjectType, $TargetDP),
                                    "Are you sure you want to continue?",
                                    ("Distributing '{0}' ({1}) to '{2}'" -f $InputObject.ObjectID, [SMS_DPContentInfo]$InputObject.ObjectType, $TargetDP))) {
                                        Invoke-Command -ScriptBlock $ScriptBlock -ErrorAction "Stop"
                                        $result["Result"] = "Success"
                                }
                                else {
                                    $result["Result"] = "No change"
                                }
                            }
                            catch {
                                Write-Error -ErrorRecord $_
                                $result["Result"] = "Failed"
                                $result["Message"] = $_.Exception.Message
                            }
                            
                            if (-not $WhatIfPreference) { [PSCustomObject]$result }
                        }
                        else {
                            Write-Warning ("Skipping '{0}'" -f $File.Name)
                        }
                    }
                }
                default {
                    foreach ($Object in $InputObject) {
                        switch ($true) {
                            ($LastDP -ne $Object.DistributionPoint -And -not $PSBoundParameters.ContainsKey("DistributionPoint")) {
                                $TargetDP = $Object.DistributionPoint
                            }
                            ($LastDP -ne $TargetDP) {
                                try {
                                    Resolve-DP -Name $TargetDP -SiteServer $SiteServer -SiteCode $SiteCode
                                }
                                catch {
                                    Write-Error -ErrorRecord $_
                                    return
                                }
                                
                                $LastDP = $TargetDP
                            }
                            default {
                                $LastDP = $TargetDP
                            }
                        }

                        $result = @{
                            PSTypeName = "PSCMContentMgmtDistribute" 
                            ObjectID   = $Object.ObjectID
                            ObjectType = $Object.ObjectType
                            Message    = $null
                        }
        
                        $Command = 'Start-CMContentDistribution -{0} "{1}" -DistributionPointName "{2}" -ErrorAction "Stop"' -f [SMS_DPContentInfo_CMParameters][SMS_DPContentInfo]$Object.ObjectType, $Object.ObjectID, $TargetDP
                        $ScriptBlock = [ScriptBlock]::Create($Command)
                        try {
                            if ($PSCmdlet.ShouldProcess(
                                ("Would distribute '{0}' ({1}) to '{2}'" -f $Object.ObjectID, $Object.ObjectType, $TargetDP),
                                "Are you sure you want to continue?",
                                ("Distributing '{0}' ({1}) to '{2}'" -f $Object.ObjectID, $Object.ObjectType, $TargetDP))) {
                                    Invoke-Command -ScriptBlock $ScriptBlock -ErrorAction "Stop"
                                    $result["Result"] = "Success"
                            }
                            else {
                                $result["Result"] = "No change"
                            }
                        }
                        catch {
                            Write-Error -ErrorRecord $_
                            $result["Result"] = "Failed"
                            $result["Message"] = $_.Exception.Message
                        }
                        
                        if (-not $WhatIfPreference) { [PSCustomObject]$result }
                    }
                }
            }
        }
        catch {
            Set-Location $OriginalLocation 
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    end {
        Set-Location $OriginalLocation
    }
}

function Start-DPGroupContentDistribution {
    <#
    .SYNOPSIS
        Distributes objects to a given distribution point group. 
        
        The function can accept input object from Get-DPContent, by manually specifying -ObjectID and -ObjectType or by using -Folder where it will distribute all objects for .pkgx files found in said folder.
    .PARAMETER InputObject
        A PSObject type "PSCMContentMgmt" generated by Get-DPContent
    .PARAMETER DistributionPointGroup
        Name of distribution point group you want to distribute objects to.
    .PARAMETER ObjectID
        Unique ID of the content object you want to distribute.

        For Applications the ID must be the CI_ID value whereas for all other content objects the ID is PackageID.

        When using this parameter you must also use ObjectType.
    .PARAMETER ObjectType
        Object type of the content object you want to distribute.

        Can be one of the following values: "Package", "DriverPackage", "DeploymentPackage", "OperatingSystemImage", "OperatingSystemInstaller", "BootImage", "Application".

        When using this parameter you must also use ObjectID.
    .PARAMETER Folder
        For all .pkgx files in this folder that use the following naming convention "<ObjectType>_<ObjectID>.pkgx", distribute the <ObjectID> of type <ObjectType> to -DistributionPoint.

        This can be useful if you have a folder filled with .pkgx files, generated by Export-DPContent, and want to distribute those objects to a distribution point.
    .PARAMETER SiteServer
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteServer variable which is the default value for this parameter.
        
        Specify this to query an alternative server, or if the module import process was unable to auto-detect and set $CMSiteServer.
    .PARAMETER SiteCode
        Site code of which the server specified by -SiteServer belongs to.
        
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteCode variable which is the default value for this parameter.
        
        Specify this to query an alternative site, or if the module import process was unable to auto-detect and set $CMSiteCode.
    .EXAMPLE
        PS C:\> Compare-DPGroupContent -Source "London DPs" -Target "Mancester DPs" | Start-DPGroupContentDistribution -DistributionPointGroup "Mancester DPs" -WhatIf

        Compares the missing content objects in group Manchester DPs compared to "London DPs", and distributes them to distribution point group Manchester DPs.
    .EXAMPLE
        PS C:\> Start-DPGroupContentDistribution -Folder "E:\exported" -DistributionPointGroup "London DPs" -WhatIf

        For all .pkgx files in folder "E:\exported" that use the following naming convention "<ObjectType>_<ObjectID>.pkgx", distributes them to distribution point group "London DPs".
    .EXAMPLE
        PS C:\> Start-DPGroupContentDistribution -ObjectID ACC00007 -ObjectType Package -DistributionPointGroup "London DPs" -WhatIf
        
        Nothing more than a wrapper for Start-CMContentDistribution. Distributes package ACC00007 to distribution point group "London DPs".
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName="InputObject")]
        [PSTypeName('PSCMContentMgmt')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory, ParameterSetName="Properties")]
        [ValidateNotNullOrEmpty()]
        [String]$ObjectID,

        [Parameter(Mandatory, ParameterSetName="Properties")]
        [ValidateSet("Package","DriverPackage","DeploymentPackage","OperatingSystemImage","OperatingSystemInstaller","BootImage","Application")]
        [SMS_DPContentInfo]$ObjectType,

        [Parameter(Mandatory, ParameterSetName="Folder")]
        [ValidateScript({
            if (!([System.IO.Directory]::Exists($_))) {
                throw "Invalid path or access denied"
            } elseif (!($_ | Test-Path -PathType Container)) {
                throw "Value must be a directory, not a file"
            } else {
                return $true
            }
        })]
        [String]$Folder,

        [Parameter(ParameterSetName="InputObject")]
        [Parameter(Mandatory, ParameterSetName="Properties")]
        [Parameter(Mandatory, ParameterSetName="Folder")]
        [ValidateNotNullOrEmpty()]
        [String]$DistributionPointGroup,

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

        $TargetDPGroup = $DistributionPointGroup

        if ($PSCmdlet.ParameterSetName -ne "InputObject") {
            $InputObject = [PSCustomObject]@{
                ObjectID               = $ObjectID
                ObjectType             = $ObjectType
                DistributionPointGroup = $TargetDPGroup
            }
        }

        if ($PSCmdlet.ParameterSetName -eq "Folder") {
            $Files = Get-ChildItem -Path $Folder -Filter "*.pkgx"

            try {
                Resolve-DPGroup -Name $TargetDPGroup -SiteServer $SiteServer -SiteCode $SiteCode
            }
            catch {
                $PSCmdlet.ThrowTerminatingError($_)
            }
        }

        $OriginalLocation = (Get-Location).Path

        if ($null -eq (Get-PSDrive -Name $SiteCode -PSProvider "CMSite" -ErrorAction "SilentlyContinue")) {
            $null = New-PSDrive -Name $SiteCode -PSProvider "CMSite" -Root $SiteServer -ErrorAction "Stop"
        }

        Set-Location ("{0}:\" -f $SiteCode) -ErrorAction "Stop"
    }
    process {
        try {
            switch ($PSCmdlet.ParameterSetName) {
                "Folder" {
                    foreach ($File in $Files) {
                        if ($File.Name -match "^(?<ObjectType>0|3|5|257|258|259|512)_(?<ObjectID>[A-Za-z0-9]+)\.pkgx$") {
                            $InputObject = [PSCustomObject]@{
                                ObjectID   = $Matches.ObjectID
                                ObjectType = $Matches.ObjectType
                            }
        
                            $result = @{
                                PSTypeName = "PSCMContentMgmtDistribute" 
                                ObjectID   = $InputObject.ObjectID
                                ObjectType = [SMS_DPContentInfo]$InputObject.ObjectType
                                Message    = $null
                            }

                            $Command = 'Start-CMContentDistribution -{0} "{1}" -DistributionPointGroupName "{2}" -ErrorAction "Stop"' -f [SMS_DPContentInfo_CMParameters][SMS_DPContentInfo]$InputObject.ObjectType, $InputObject.ObjectID, $TargetDPGroup
                            $ScriptBlock = [ScriptBlock]::Create($Command)
                            try {
                                if ($PSCmdlet.ShouldProcess(
                                    ("Would distribute '{0}' ({1}) to '{2}'" -f $InputObject.ObjectID, [SMS_DPContentInfo]$InputObject.ObjectType, $TargetDPGroup),
                                    "Are you sure you want to continue?",
                                    ("Distributing '{0}' ({1}) to '{2}'" -f $InputObject.ObjectID, [SMS_DPContentInfo]$InputObject.ObjectType, $TargetDPGroup))) {
                                        Invoke-Command -ScriptBlock $ScriptBlock -ErrorAction "Stop"
                                        $result["Result"] = "Success"
                                }
                                else {
                                    $result["Result"] = "No change"
                                }
                            }
                            catch {
                                Write-Error -ErrorRecord $_
                                $result["Result"] = "Failed"
                                $result["Message"] = $_.Exception.Message
                            }
                            
                            if (-not $WhatIfPreference) { [PSCustomObject]$result }
                        }
                        else {
                            Write-Warning ("Skipping '{0}'" -f $File.Name)
                        }
                    }
                }
                default {
                    foreach ($Object in $InputObject) {
                        switch ($true) {
                            ($LastDPGroup -ne $Object.DistributionPointGroup -And -not $PSBoundParameters.ContainsKey("DistributionPointGroup")) {
                                $TargetDPGroup = $Object.DistributionPointGroup
                            }
                            ($LastDPGroup -ne $TargetDPGroup) {
                                try {
                                    Resolve-DPGroup -Name $TargetDPGroup -SiteServer $SiteServer -SiteCode $SiteCode
                                }
                                catch {
                                    Write-Error -ErrorRecord $_
                                    return
                                }
                                
                                $LastDPGroup = $TargetDPGroup
                            }
                            default {
                                $LastDPGroup = $TargetDPGroup
                            }
                        }

                        $result = @{
                            PSTypeName = "PSCMContentMgmtDistribute" 
                            ObjectID   = $Object.ObjectID
                            ObjectType = $Object.ObjectType
                            Message    = $null
                        }
        
                        $Command = 'Start-CMContentDistribution -{0} "{1}" -DistributionPointGroupName "{2}" -ErrorAction "Stop"' -f [SMS_DPContentInfo_CMParameters][SMS_DPContentInfo]$Object.ObjectType, $Object.ObjectID, $TargetDPGroup
                        $ScriptBlock = [ScriptBlock]::Create($Command)
                        try {
                            if ($PSCmdlet.ShouldProcess(
                                ("Would distribute '{0}' ({1}) to '{2}'" -f $Object.ObjectID, $Object.ObjectType, $TargetDPGroup),
                                "Are you sure you want to continue?",
                                ("Distributing '{0}' ({1}) to '{2}'" -f $Object.ObjectID, $Object.ObjectType, $TargetDPGroup))) {
                                    Invoke-Command -ScriptBlock $ScriptBlock -ErrorAction "Stop"
                                    $result["Result"] = "Success"
                            }
                            else {
                                $result["Result"] = "No change"
                            }
                        }
                        catch {
                            Write-Error -ErrorRecord $_
                            $result["Result"] = "Failed"
                            $result["Message"] = $_.Exception.Message
                        }
                        
                        if (-not $WhatIfPreference) { [PSCustomObject]$result }
                    }
                }
            }
        }
        catch {
            Set-Location $OriginalLocation 
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    end {
        Set-Location $OriginalLocation
    }
}
#endregion Public functions

