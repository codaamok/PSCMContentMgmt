function Set-DPAllowPrestagedContent {
    <#
    .SYNOPSIS
        Set a distribution point to only receive prestaged content
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String[]]$DistributionPoint,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SiteServer = $CMSiteServer,
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SiteCode = $CMSiteCode
    )
    begin {
        $OriginalLocation = (Get-Location).Path

        if($null -eq (Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue)) {
            New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $SiteServer -ErrorAction Stop | Out-Null
        }

        Set-Location ("{0}:\" -f $SiteCode) -ErrorAction "Stop"
    }
    process {
        try {
            Resolve-DP -DistributionPoint $DistributionPoint
        }
        catch {
            Write-Error -ErrorRecord $_
            return
        }

        $result = [ordered]@{ DistributionPoint = $DistributionPoint }
        try {
            Set-CMDistributionPoint -SiteSystemServerName $DistributionPoint -AllowPreStaging $true
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
