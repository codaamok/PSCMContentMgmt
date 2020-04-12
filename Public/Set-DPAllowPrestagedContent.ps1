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
        Query SMS_DPContentInfo on this server.
        
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteServer variable which is the default value for this parameter.
        
        Specify this to query an alternative server, or if the module import process was unable to auto-detect and set $CMSiteServer.
    .PARAMETER SiteCode
        Site code of which the server specified by -SiteServer belongs to.
        
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteCode variable which is the default value for this parameter.
        
        Specify this to query an alternative site, or if the module import process was unable to auto-detect and set $CMSiteCode.
    .EXAMPLE
        PS C:\> Set-DPAllowPrestageContent -DistributionPoint "dp1.contoso.com", "dp2.contoso.com" -State $true -Confirm:$false

        Enables both distribution points to allow prestaged content and suppresses the confirmation prompt.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param (
        [Parameter(Mandatory)]
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
    end {
        Set-Location $OriginalLocation
    }
}
