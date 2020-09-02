function Set-DPAllowPrestagedContent {
    <#
    .SYNOPSIS
        Configure the allow prestage content setting for a distribution point.
    .DESCRIPTION
        Configure the allow prestage content setting for a distribution point.

        This can be useful if you are intending to use Export-DPContent and Import-DPContent for a distribution point content library migration. If this is your intent, ensure you first configure your distribution point to allow prestage content using this function, distribute the content objects you want to import (see Start-DPContentDistribution) and then you should use Import-DPContent.
    .PARAMETER DistributionPoint
        Name of distribution point (as it appears in Configuration Manager, usually FQDN) you want to change the setting on.
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
    .INPUTS
        This function does not accept pipeline input.
    .OUTPUTS
        System.Management.Automation.PSObject
    .EXAMPLE
        PS C:\> Set-DPAllowPrestageContent -DistributionPoint "dp1.contoso.com" -State $true -WhatIf

        Enables dp1.contoso.com to allow prestaged content.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    [OutputType([PSCustomObject])]
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
