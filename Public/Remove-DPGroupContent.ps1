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
        PS C:\> Get-DPGroupContent -DistributionPointGroup "Asia DPs" | Remove-DPGroupContent

        Removes all content from the distribution point group "Asia DPs"
    .EXAMPLE
        PS C:\> Remove-DPGroupContent -ObjectID "17014765" -ObjectType "Application" -DistributionPointGroup "Asia DPs"

        Removes application with CI_ID value of "17014765" from distribution point group "Asia DPs"
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName="InputObject")]
        [PSTypeName('PSCMContentMgmt')]
        [PSCustomObject[]]$InputObject,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$DistributionPointGroup,

        [Parameter(Mandatory, ParameterSetName="SpecifyProperties")]
        [ValidateNotNullOrEmpty()]
        [String]$ObjectID,

        [Parameter(Mandatory, ParameterSetName="SpecifyProperties")]
        [ValidateSet("Package","DriverPackage","DeploymentPackage","OperatingSystemImage","OperatingSystemInstaller","BootImage","Application")]
        [SMS_DPContentInfo]$ObjectType,

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
        
        $OriginalLocation = (Get-Location).Path

        if($null -eq (Get-PSDrive -Name $SiteCode -PSProvider "CMSite" -ErrorAction "SilentlyContinue")) {
            $null = New-PSDrive -Name $SiteCode -PSProvider "CMSite" -Root $SiteServer -ErrorAction "Stop"
        }

        Set-Location ("{0}:\" -f $SiteCode) -ErrorAction "Stop"
    }
    process {
        if ($PSCmdlet.ParameterSetName -ne "InputObject") {
            $InputObject = [PSCustomObject]@{
                ObjectID   = $ObjectID
                ObjectType = $ObjectType
            }
        }

        foreach ($Object in $InputObject) {
            if ($LastDPGroup -ne $Object.DistributionPointGroup) {
                if ($PSBoundParameters.ContainsKey("DistributionPointGroup")) {
                    $Target = $DistributionPointGroup
                }
                else {
                    $Target = $Object.DistributionPointGroup
                }
        
                try {
                    Resolve-DPGroup -Name $Target -SiteServer $SiteServer -SiteCode $SiteCode
                }
                catch {
                    $PSCmdlet.ThrowTerminatingError($_)
                } 
            }
            else { 
                $LastDPGroup = $Object.DistributionPointGroup
            }
            
            $result = @{ 
                PSTypeName             = "PSCMContentMgmtRemove"
                ObjectID               = $Object.ObjectID
                ObjectType             = $Object.ObjectType
                DistributionPointGroup = $Target
                Message                = $null
            }
            
            $Command = 'Remove-CMContentDistribution -DistributionPointGroupName "{0}" -{1} "{2}" -Force -ErrorAction "Stop"' -f $Target, [SMS_DPContentInfo_CMParameters][SMS_DPContentInfo]$Object.ObjectType, $Object.ObjectID
            $ScriptBlock = [ScriptBlock]::Create($Command)
            try {
                if ($PSCmdlet.ShouldProcess(
                    ("Would remove '{0}' ({1}) from '{2}'" -f $Object.ObjectID, [SMS_DPContentInfo]$Object.ObjectType, $Target),
                    "Are you sure you want to continue?",
                    ("Removing '{0}' ({1}) from '{2}'" -f $Object.ObjectID, [SMS_DPContentInfo]$Object.ObjectType, $Target))) {
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
    end {
        Set-Location $OriginalLocation
    }
}
