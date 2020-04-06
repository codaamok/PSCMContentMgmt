function Start-DPContentDistribution {
    <#
    .SYNOPSIS
        Distributes objects to a given distribution point. The function can accept input object from Get-DPContent, by manually specifying -ObjectID and -ObjectType or by using -Folder where it will distribute all objects for .pkgx files found in said folder.
    .PARAMETER InputObject
        A PSObject type "PSCMContentMgmt" generated by Get-DPContent
    .PARAMETER DistributionPoint
        Name of distribution point (as it appears in ConfigMgr, usually FQDN) you want to distribute objects to.
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
        Query SMS_DPContentInfo on this server.
        
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteServer variable which is the default value for this parameter.
        
        Specify this to query an alternative server, or if the module import process was unable to auto-detect and set $CMSiteServer.
    .PARAMETER SiteCode
        Site code of which the server specified by -SiteServer belongs to.
        
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteCode variable which is the default value for this parameter.
        
        Specify this to query an alternative site, or if the module import process was unable to auto-detect and set $CMSiteCode.
    .EXAMPLE
        PS C:\> Get-DPContent -DistributionPoint "dp1.contoso.com" | Start-DPContentDistribution -DistributionPoint "dp2.contoso.com"

        Gathers all the objects on dp1.contoso.com and distributes them to dp2.contoso.com.
    .EXAMPLE
        PS C:\> Start-DPContentDistribution -DistributionPoint "dp2.contoso.com" -ObjectID ACC00007 -ObjectType "Package"

        Distributes package ACC00007 to dp2.contoso.com.
    .EXAMPLE
        PS C:\> Start-DPContentDistribution -DistributionPoint "dp2.contoso.com" -Folder "F:\prestaged"

        For all .pkgx files in this folder that use the following naming convention "<ObjectType>_<ObjectID>.pkgx", distribute the <ObjectID> of type <ObjectType> to dp2.contoso.com.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName="InputObjectDP")]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName="InputObjectDPG")]
        [PSTypeName('PSCMContentMgmt')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory, ParameterSetName="PropertiesDP")]
        [Parameter(Mandatory, ParameterSetName="PropertiesDPG")]
        [ValidateNotNullOrEmpty()]
        [String]$ObjectID,

        [Parameter(Mandatory, ParameterSetName="PropertiesDP")]
        [Parameter(Mandatory, ParameterSetName="PropertiesDPG")]
        [ValidateSet("Package","DriverPackage","DeploymentPackage","OperatingSystemImage","OperatingSystemInstaller","BootImage","Application")]
        [SMS_DPContentInfo]$ObjectType,

        [Parameter(Mandatory, ParameterSetName="FolderDP")]
        [Parameter(Mandatory, ParameterSetName="FolderDPG")]
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

        [Parameter(Mandatory, ParameterSetName="InputObjectDP")]
        [Parameter(Mandatory, ParameterSetName="PropertiesDP")]
        [Parameter(Mandatory, ParameterSetName="FolderDP")]
        [String]$DistributionPoint,

        [Parameter(Mandatory, ParameterSetName="InputObjectDPG")]
        [Parameter(Mandatory, ParameterSetName="PropertiesDPG")]
        [Parameter(Mandatory, ParameterSetName="FolderDPG")]
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

        try {
            switch -Regex ($PSCmdlet.ParameterSetName) {
                "DPG$" {
                    $Target = [PSCustomObject]@{
                        Parameter = "DistributionPointGroupName"
                        Name      = $DistributionPointGroup
                    }
                    Resolve-DPGroup -Name $DistributionPointGroup -SiteServer $SiteServer -SiteCode $SiteCode
                }
                "DP$" {
                    $Target = [PSCustomObject]@{
                        Parameter = "DistributionPointName"
                        Name      = $DistributionPoint
                    }
                    Resolve-DP -Name $DistributionPoint -SiteServer $SiteServer -SiteCode $SiteCode
                }
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }

        switch -Regex ($PSCmdlet.ParameterSetName) {
           "InputObjectDP|InputObjectDPG" { }
           "PropertiesDP|PropertiesDPG" {
                $InputObject = [PSCustomObject]@{
                    ObjectID          = $ObjectID
                    ObjectType        = $ObjectType
                }
            }
            "FolderDP|FolderDPG" {
                $Files = Get-ChildItem -Path $Folder -Filter "*.pkgx"
            }
        }

        $OriginalLocation = (Get-Location).Path

        if ($null -eq (Get-PSDrive -Name $SiteCode -PSProvider "CMSite" -ErrorAction "SilentlyContinue")) {
            $null = New-PSDrive -Name $SiteCode -PSProvider "CMSite" -Root $SiteServer -ErrorAction "Stop"
        }

        Set-Location ("{0}:\" -f $SiteCode) -ErrorAction "Stop"
    }
    process {
        switch -Regex ($PSCmdlet.ParameterSetName) {
            "FolderDP|FolderDPG" {
                foreach ($File in $FIles) {
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

                        $Command = 'Start-CMContentDistribution -{0} "{1}" -{2} "{3}" -ErrorAction "Stop"' -f [SMS_DPContentInfo_CMParameters][SMS_DPContentInfo]$InputObject.ObjectType, $InputObject.ObjectID, $Target.Parameter, $Target.Name
                        $ScriptBlock = [ScriptBlock]::Create($Command)
                        try {
                            if ($PSCmdlet.ShouldProcess(
                                ("Would distribute '{0}' ({1}) to '{2}'" -f $InputObject.ObjectID, [SMS_DPContentInfo]$ObjectType, $Target.Name),
                                "Are you sure you want to continue?",
                                ("Distributing '{0}' ({1}) to '{2}'" -f $InputObject.ObjectID, [SMS_DPContentInfo]$ObjectType, $Target.Name))) {
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
                        [PSCustomObject]$result
                    }
                    else {
                        Write-Warning ("Skipping '{0}'" -f $File.Name)
                    }
                }
            }
            default {
                $result = @{
                    PSTypeName = "PSCMContentMgmtDistribute" 
                    ObjectID   = $InputObject.ObjectID
                    ObjectType = $InputObject.ObjectType
                    Message    = $null
                }

                $Command = 'Start-CMContentDistribution -{0} "{1}" -{2} "{3}" -ErrorAction "Stop"' -f [SMS_DPContentInfo_CMParameters][SMS_DPContentInfo]$InputObject.ObjectType, $InputObject.ObjectID, $Target.Parameter, $Target.Name
                $ScriptBlock = [ScriptBlock]::Create($Command)
                try {
                    if ($PSCmdlet.ShouldProcess(
                        ("Would distribute '{0}' ({1}) to '{2}'" -f $InputObject.ObjectID, [SMS_DPContentInfo]$ObjectType, $Target.Name),
                        "Are you sure you want to continue?",
                        ("Distributing '{0}' ({1}) to '{2}'" -f $InputObject.ObjectID, [SMS_DPContentInfo]$ObjectType, $Target.Name))) {
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
                [PSCustomObject]$result
            }
        }
    }
    end {
        Set-Location $OriginalLocation
    }
}
