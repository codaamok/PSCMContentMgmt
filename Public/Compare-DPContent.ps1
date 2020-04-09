function Compare-DPContent {
    <#
    .SYNOPSIS
        Returns a list of content objects missing from the given target distribution point or distribution point group, comapred to the source distribution point or distribution point group.
    .PARAMETER SourceDistributionPoint
        Name of the referencing distribution point (as it appears in ConfigMgr, usually FQDN) you want to query.
    .PARAMETER TargetDistributionPoint
        Name of the differencing distribution point (as it appears in ConfigMgr, usually FQDN) you want to query.
    .PARAMETER SourceDistributionPointGroup
        Name of the referencing distribution point group you want to query.
    .PARAMETER TargetDistributionPointGroup
        Name of the differencing distribution point group you want to query.
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
    .EXAMPLE
        PS C:\> Compare-DPContent -SourceDistributionPoint dp1.contos.com -TargetDistributionPointGroup "Asia DPs"

        Returns content objects which are missing from the "Asia DPs" distribution point group compared to dp1.contoso.com.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName="SourceDPTargetDP")]
        [Parameter(Mandatory, ParameterSetName="SourceDPTargetDPG")]
        [String]$SourceDistributionPoint,

        [Parameter(Mandatory, ParameterSetName="SourceDPGTargetDP")]
        [Parameter(Mandatory, ParameterSetName="SourceDPTargetDP")]
        [String]$TargetDistributionPoint,

        [Parameter(Mandatory, ParameterSetName="SourceDPGTargetDP")]
        [Parameter(Mandatory, ParameterSetName="SourceDPGTargetDPG")]
        [String]$SourceDistributionPointGroup,

        [Parameter(Mandatory, ParameterSetName="SourceDPTargetDPG")]
        [Parameter(Mandatory, ParameterSetName="SourceDPGTargetDPG")]
        [String]$TargetDistributionPointGroup,

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
    }
    process {
        try {
            switch ($PSBoundParameters.Keys) {
                "SourceDistributionPoint" {
                    Resolve-DP -Name $SourceDistributionPoint -SiteServer $SiteServer -SiteCode $SiteCode
                    $SourceContent = Get-DPContent -DistributionPoint $SourceDistributionPoint
                }
                "SourceDistributionPointGroup" {
                    Resolve-DPGroup -Name $SourceDistributionPointGroup -SiteServer $SiteServer -SiteCode $SiteCode
                    $SourceContent = Get-DPContent -DistributionPointGroup $SourceDistributionPointGroup
                }
                "TargetDistributionPoint" {
                    Resolve-DP -Name $TargetDistributionPoint -SiteServer $SiteServer -SiteCode $SiteCode
                    $TargetContent = Get-DPContent -DistributionPoint $TargetDistributionPoint
                }
                "TargetDistributionPointGroup" {
                    Resolve-DPGroup -Name $TargetDistributionPointGroup -SiteServer $SiteServer -SiteCode $SiteCode
                    $TargetContent = Get-DPContent -DistributionPointGroup $TargetDistributionPointGroup
                }
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    
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
    }    
}