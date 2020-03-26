function Compare-DPContent {
    <#
    .SYNOPSIS
        Returns a list of all content objects missing from the given target server
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]$Source,

        [Parameter(Mandatory)]
        [String]$Target,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SiteServer = $CMSiteServer,
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SiteCode = $CMSiteCode
    )
    begin {
        try {
            Resolve-DP -DistributionPoint $Source, $Target
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
        
        $OriginalLocation = (Get-Location).Path

        if($null -eq (Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue)) {
            New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $SiteServer -ErrorAction Stop | Out-Null
        }

        Set-Location ("{0}:\" -f $SiteCode) -ErrorAction "Stop"
    }
    process {
        $SourceContent = Get-DPContent -DistributionPoint $Source
        $TargetContent = Get-DPContent -DistributionPoint $Target
    
        Compare-Object -ReferenceObject $SourceContent -DifferenceObject $TargetContent -Property ObjectID -PassThru | ForEach-Object {
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
        Set-Location $OriginalLocation
    }    
}