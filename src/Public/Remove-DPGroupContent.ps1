function Remove-DPGroupContent {
    <#
    .SYNOPSIS
        Remove content objects from distribution point group(s).
    .DESCRIPTIOn
        Remove content objects from distribution point group(s).
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
        FQDN address of the site server (SMS Provider). 
        
        You only need to use this parameter once for any function of PSCMContentMgmt that also has a -SiteServer parameter. PSCMContentMgmt remembers the site server for subsequent commands, unless you specify the parameter again to change site server.
    .PARAMETER SiteCode
        Site code of which the server specified by -SiteServer belongs to.

        You only need to use this parameter once for any function of PSCMContentMgmt that also has a -SiteCode parameter. PSCMContentMgmt remembers the site code for subsequent commands, unless you specify the parameter again to change site code.
    .INPUTS
        System.Management.Automation.PSObject
    .OUTPUTS
        System.Management.Automation.PSObject
    .EXAMPLE 
        PS C:\> Get-DPGroupContent -DistributionPointGroup "Asia DPs" | Remove-DPGroupContent -WhatIf

        Removes all content from the distribution point group Asia DPs.
    .EXAMPLE
        PS C:\> Remove-DPGroupContent -ObjectID "17014765" -ObjectType "Application" -DistributionPointGroup "Asia DPs" -WhatIf

        Removes application with CI_ID value of 17014765 from distribution point group Asia DPs.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
    [OutputType([PSCustomObject])]
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
        [String]$SiteServer,
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SiteCode
    )
    begin {
        Set-SiteServerAndSiteCode -SiteServer $Local:SiteServer -SiteCode $Local:SiteCode

        $TargetDPGroup = $DistributionPointGroup

        if ($PSCmdlet.ParameterSetName -ne "InputObject") {
            $InputObject = [PSCustomObject]@{
                ObjectID               = $ObjectID
                ObjectType             = $ObjectType
                DistributionPointGroup = $TargetDPGroup
            }
        }
        
        $OriginalLocation = (Get-Location).Path

        if($null -eq (Get-PSDrive -Name $Script:SiteCode -PSProvider "CMSite" -ErrorAction "SilentlyContinue")) {
            $null = New-PSDrive -Name $Script:SiteCode -PSProvider "CMSite" -Root $Script:SiteServer -ErrorAction "Stop"
        }

        Set-Location ("{0}:\" -f $Script:SiteCode) -ErrorAction "Stop"
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
                            Resolve-DPGroup -Name $TargetDPGroup -SiteServer $Script:SiteServer -SiteCode $Script:SiteCode
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
