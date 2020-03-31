function Set-DPAllowPrestagedContent {
    <#
    .SYNOPSIS
        Configure the allow prestage content setting for a distribution point
    .PARAMETER DistributionPoint
        Name of distribution point (as it appears in ConfigMgr, usually FQDN) you want to change the setting on.
    .PARAMETER State
        A boolean value, $true configures the distribution point to allow prestage contet whereas $false removes the config.

        This is the equivilant of checking the box in the distribution point's properties for "Enables this distribution point for prestaged content". Checked = $true, unchecked = $false.
    .PARAMETER Confirm
        Suppress the prompt to continue.
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
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]$DistributionPoint,

        [Parameter()]
        [Bool]$State = $true,

        [Parameter()]
        [Bool]$Confirm = $true,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SiteServer = $CMSiteServer,
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SiteCode = $CMSiteCode
    )
    begin {
        try {
            Resolve-DP -Name $DistributionPoint
        }
        catch {
            Write-Error -ErrorRecord $_
            return
        }

        if ($Confirm -eq $true) {
            $Title = "Changing allow prestage setting for '{0}'" -f $DistributionPoint
            $Question = "`nDo you want to change the allow prestage content to '{0}' for distribution point '{1}'?" -f $State, $DistributionPoint
            $Choices = "&Yes", "&No"
            $Decision = $Host.UI.PromptForChoice($title, $question, $choices, 0)
            if ($Decision -eq 1) {
                return
            }
        }

        $OriginalLocation = (Get-Location).Path

        if($null -eq (Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue)) {
            New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $SiteServer -ErrorAction Stop | Out-Null
        }

        Set-Location ("{0}:\" -f $SiteCode) -ErrorAction "Stop"
    }
    process {
        $result = [ordered]@{ DistributionPoint = $DistributionPoint }
        try {
            Set-CMDistributionPoint -SiteSystemServerName $DistributionPoint -AllowPreStaging $State
            $result["Result"] = "Success"
        }
        catch {
            Write-Error -ErrorRecord $_
            $result["Result"] = "Failed: {0}" -f $_.Exception.Message
        }
        [PSCustomObject]$result
    }
    end {
        Set-Location $OriginalLocation
    }
}
