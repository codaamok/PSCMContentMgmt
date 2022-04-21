function Set-DPAllowPrestagedContent {
    <#
    .SYNOPSIS
        Configure the allow prestage content setting for a distribution point.
    .DESCRIPTION
        Configure the allow prestage content setting for a distribution point.

        This can be useful if you are intending to use Export-DPContent and Import-DPContent for a distribution point content library migration. If this is your intent, please read the CONTENT LIBRARY MIRATION section in the About help topic about_PSCMContentMgmt_ExportImport.
    .PARAMETER DistributionPoint
        Name of distribution point (as it appears in Configuration Manager, usually FQDN) you want to change the setting on.
    .PARAMETER State
        A boolean value, $true configures the distribution point to allow prestage contet whereas $false removes the config.

        This is the equivilant of checking the box in the distribution point's properties for "Enables this distribution point for prestaged content". Checked = $true, unchecked = $false.
    .PARAMETER SiteServer
        FQDN address of the site server (SMS Provider). 
        
        You only need to use this parameter once for any function of PSCMContentMgmt that also has a -SiteServer parameter. PSCMContentMgmt remembers the site server for subsequent commands, unless you specify the parameter again to change site server.
    .PARAMETER SiteCode
        Site code of which the server specified by -SiteServer belongs to.

        You only need to use this parameter once for any function of PSCMContentMgmt that also has a -SiteCode parameter. PSCMContentMgmt remembers the site code for subsequent commands, unless you specify the parameter again to change site code.
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
        [String]$SiteServer,
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SiteCode    )
    begin {
        Set-SiteServerAndSiteCode -SiteServer $Local:SiteServer -SiteCode $Local:SiteCode

        try {
            Resolve-DP -Name $DistributionPoint -SiteServer $Script:SiteServer -SiteCode $Script:SiteCode
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }

        $Action = switch ($State) {
            $true { "enable" }
            $false { "disable" }
        }

        $OriginalLocation = (Get-Location).Path

        if($null -eq (Get-PSDrive -Name $Script:SiteCode -PSProvider "CMSite" -ErrorAction "SilentlyContinue")) {
            $null = New-PSDrive -Name $Script:SiteCode -PSProvider "CMSite" -Root $Script:SiteServer -ErrorAction "Stop"
        }

        Set-Location ("{0}:\" -f $Script:SiteCode) -ErrorAction "Stop"
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
