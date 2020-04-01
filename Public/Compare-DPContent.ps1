function Compare-DPContent {
    <#
    .SYNOPSIS
        Returns a list of content objects missing from the given target server comapred to the source server.
    .PARAMETER Source
        Name of the referencing distribution point (as it appears in ConfigMgr, usually FQDN) you want to query.
    .PARAMETER Target
        Name of the differencing distribution point (as it appears in ConfigMgr, usually FQDN) you want to query.
    .PARAMETER SiteServer
        Query SMS_DPContentInfo on this server.

        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteServer variable which is the default value for this parameter.

        Specify this to query an alternative server, or if the module import process was unable to auto-detect and set $CMSiteServer.
    .PARAMETER SiteCode
        Site code of which the server specified by -SiteServer belongs to.

        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteCode variable which is the default value for this parameter.
        
        Specify this to query an alternative site, or if the module import process was unable to auto-detect and set $CMSiteCode.
    .EXAMPLE
        PS C:\> Compare-DPContent -Source dp1.contoso.com -Target dp2.contoso.com

        Return content objects which are missing from dp2.contoso.com compared to dp1.contoso.com.
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
        switch ($null) {
            $SiteCode {
                Write-Error -Message "Please supply a site code using the -SiteCode parameter" -Category "InvalidArgument" -ErrorAction "Stop"
            }
            $SiteServer {
                Write-Error -Message "Please supply a site server FQDN address using the -SiteServer parameter" -Category "InvalidArgument" -ErrorAction "Stop"
            }
        }

        try {
            Resolve-DP -Name $Source -SiteServer $SiteServer -SiteCode $SiteCode
            Resolve-DP -Name $Target -SiteServer $SiteServer -SiteCode $SiteCode
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
        
        $OriginalLocation = (Get-Location).Path

        if($null -eq (Get-PSDrive -Name $SiteCode -PSProvider "CMSite" -ErrorAction "SilentlyContinue")) {
            $null = New-PSDrive -Name $SiteCode -PSProvider "CMSite" -Root $SiteServer -ErrorAction "Stop"
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