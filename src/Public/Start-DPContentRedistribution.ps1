function Start-DPContentRedistribution {
    <#
    .SYNOPSIS
        Initiates redistribution for objects to a given distribution point. 
    .DESCRIPTION
        Initiates redistribution for objects to a given distribution point. 

        Start-DPContentRedistribution can accept input object from Get-DPContent or Get-DPDistributionStatus.
    .PARAMETER InputObject
        A PSObject type "PSCMContentMgmt" generated by Get-DPContent
    .PARAMETER DistributionPoint
        Name of distribution point (as it appears in Configuration Manager, usually FQDN) you want to distribute objects to.
    .PARAMETER ObjectID
        Unique ID of the content object you want to distribute.

        For Applications the ID must be the CI_ID value whereas for all other content objects the ID is PackageID.

        When using this parameter you must also use ObjectType.
    .PARAMETER ObjectType
        Object type of the content object you want to distribute.

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
        PS C:\> Get-DP | Get-DPDistributionStatus -DistributionFailed | Start-DPContentRedistribution

        Return all distribution points, their associated failed distribution tasks and initiate redistribution for them.
    .EXAMPLE
        PS C:\> Get-DP | Get-DPDistributionStatus -DistributionFailed | Start-DPContentRedistribution

        Initiate the redistribution task for  all content objects in a state of DistributionFailed on all distribution points.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    [OutputType([PSCustomObject])]
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

        [Parameter(ParameterSetName="InputObject")]
        [Parameter(Mandatory, ParameterSetName="Properties")]
        [ValidateNotNullOrEmpty()]
        [String]$DistributionPoint,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SiteServer,
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SiteCode
    )
    begin {
        Set-SiteServerAndSiteCode -SiteServer $Local:SiteServer -SiteCode $Local:SiteCode

        $TargetDP = $DistributionPoint

        if ($PSCmdlet.ParameterSetName -ne "InputObject") {
            $InputObject = [PSCustomObject]@{
                ObjectID          = $ObjectID
                ObjectType        = $ObjectType
                Distributionpoint = $TargetDP
            }
        }
    }
    process {
        foreach ($Object in $InputObject) {
            switch ($true) {
                ($LastDP -ne $Object.DistributionPoint -And -not $PSBoundParameters.ContainsKey("DistributionPoint")) {
                    $TargetDP = $Object.DistributionPoint
                }
                ($LastDP -ne $TargetDP) {
                    try {
                        Resolve-DP -Name $TargetDP -SiteServer $Script:SiteServer -SiteCode $Script:SiteCode
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

            # Need PackageID to redistribute as that's how SMS_DistributionPoint class is indexed
            if ($Object.ObjectType -eq "Application") {
                $ObjectIDToProcess = ConvertTo-CIIDPackageId -CIID $Object.ObjectID -SiteServer $CMSiteServer -SiteCode $CMSiteCode
            }
            else {
                $ObjectIDToProcess = $Object.ObjectID
            }

            $Namespace = "ROOT/SMS/Site_{0}" -f $Script:SiteCode
            $Query = "SELECT * FROM SMS_DistributionPoint WHERE PackageID='{0}' AND ServerNALPath LIKE '%{1}%'" -f $ObjectIDToProcess, $TargetDP

            $result = @{
                PSTypeName = "PSCMContentMgmtRedistribute" 
                ObjectID   = $Object.ObjectID
                ObjectType = $Object.ObjectType
                Message    = $null
            }
            
            try {
                $CimObj = Get-CimInstance -ComputerName $Script:SiteServer -Namespace $Namespace -Query $Query -ErrorAction "Stop"

                if ($CimObj -isnot [Microsoft.Management.Infrastructure.CimInstance] -Or $null -eq $CimObj) {
                    $Message = "Object '{0}' does not exist on '{1}' to initiate redistribution" -f $Object.ObjectID, $TargetDP
                    $Exception = [InvalidOperationException]::new($Message)
                    
                    $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
                        $Exception,
                        "3",
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        $Object.ObjectID
                    )

                    throw $ErrorRecord
                }
                else {
                    if ($PSCmdlet.ShouldProcess(
                        ("Would redistribute '{0}' ({1}) to '{2}'" -f $Object.ObjectID, $Object.ObjectType, $TargetDP),
                        "Are you sure you want to continue?",
                        ("Redistributing '{0}' ({1}) to '{2}'" -f $Object.ObjectID, $Object.ObjectType, $TargetDP))) {
                            Set-CimInstance -ComputerName $Script:SiteServer -Namespace $Namespace -Query $Query -Property @{ RefreshNow = $true } -ErrorAction "Stop"
                            $result["Result"] = "Success"
                    }
                    else {
                        $result["Result"] = "No change"
                    }
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
    }
}
