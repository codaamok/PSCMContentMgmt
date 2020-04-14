function Invoke-DPContentLibraryCleanup {
    <#
    .SYNOPSIS
        Invoke the ContentLibraryCleanup.exe utility against a distribution point.
        #TODO: Add secondary site support when Aaron confirms this in the docs: https://github.com/MicrosoftDocs/SCCMdocs/issues/2298
    .DESCRIPTION
        Invoke the ContentLibraryCleanup.exe utility against a distribution point.

        This is essentially just a wrapper for the binary.

        Worth noting that omitting the -Delete parameter is the equivilant of omitting the "/delete" parameter for the binary too. In other words, without -Delete it will just report on orphaned content and not delete it.
    .PARAMETER DistributionPoint
        Name of the distribution point (as it appears in ConfigMgr, usually FQDN) you want to clean up.
    .PARAMETER ContentLibraryCleanupExe
        Absolute path to ContentLibraryCleanup.exe.

        The function attempts to discover the location of this exe, however if it is unable to find it you will receive a terminating error and asked to use this parameter.
    .PARAMETER Delete
        Deletes orphaned content.
    .PARAMETER SiteServer        
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteServer variable which is the default value for this parameter.
        
        Specify this to query an alternative server, or if the module import process was unable to auto-detect and set $CMSiteServer.
    .PARAMETER SiteCode
        Site code of which the server specified by -SiteServer belongs to.
        
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteCode variable which is the default value for this parameter.
        
        Specify this to query an alternative site, or if the module import process was unable to auto-detect and set $CMSiteCode.
    .EXAMPLE
        PS C:\> Invoke-DPContentLibraryCleanup.ps1 -DistributionPoint "dp1.contoso.com"

        Queries "dp1.contoso.com" for orphaned content. Because of the missing -Delete parameter, data will not be deleted.
    .EXAMPLE
        PS C:\> Invoke-DPContentLibraryCleanup.ps1 -DistributionPoint "dp1.contoso.com" -ContentLibraryCleanupExe "C:\Sources\ContentLibraryCleanup.exe" -Delete

        Deletes orphaned content on "dp1.contoso.com". Uses binary "C:\Sources\ContentLibraryCleanup.exe".
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$DistributionPoint,

        [Parameter()]
        [ValidateScript({
            if (([System.IO.File]::Exists($_) -And ($_ -like "*ContentLibraryCleanup.exe"))) {
                return $true
            } else {
                throw "Invalid path or given file is not named ContentLibraryCleanup.exe"
            }
        })]
        [String]$ContentLibraryCleanupExe,

        [Parameter()]
        [Switch]$Delete,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SiteServer = $CMSiteServer,
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SiteCode = $CMSiteCode
    )
    begin {
        if ($DistributionPoint.StartsWith($env:ComputerName)) {
            if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator") -eq $false) {
                $Exception = [UnauthorizedAccessException]::new("Must run as administrator")
                $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $Exception,
                    "2",
                    [System.Management.Automation.ErrorCategory]::PermissionDenied,
                    $null
                )
                $PSCmdlet.ThrowTerminatingError($ErrorRecord)
            }
        }

        try {
            Resolve-DP -Name $DistributionPoint -SiteServer $SiteServer -SiteCode $SiteCode
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }

        $Namespace = "ROOT/SMS/Site_{0}" -f $SiteCode
        $Query = "SELECT InstallDir FROM SMS_Site WHERE SiteCode = '{0}'" -f $SiteCode

        try {
            $SiteInstallPath = (Get-CimInstance -ComputerName $SiteServer -Namespace $Namespace -Query $Query -ErrorAction "Stop").InstallDir
        }
        catch {
            Write-Error -ErrorRecord $_
        }

        $Paths = @(
            "\\{0}\SMS_{1}\cd.latest\SMSSETUP\TOOLS\ContentLibraryCleanup\ContentLibraryCleanup.exe" -f $SiteServer, $SiteCode
            "{0}\cd.latest\SMSSETUP\TOOLS\ContentLibraryCleanup\ContentLibraryCleanup.exe" -f $SiteInstallPath
        )
        
        foreach ($Path in $Paths) {
            try {
                if (Test-Path $Path -ErrorAction "Stop") {
                    $ContentLibraryCleanupExe = $Path
                }
            }
            catch [System.UnauthorizedAccessException] {
                Write-Error -Message ("Access denied finding ContentLibraryCleanup.exe in {0}" -f (Split-Path -Parent $Path)) -Category "PermissionDenied" -CategoryTargetName $Path
            }
            catch {
                Write-Error -ErrorRecord $_
            }
        }

        if (-not $ContentLibraryCleanupExe) {
            $Exception = [System.IO.FileNotFoundException]::new("Could not find ContentLibraryCleanup.exe, please use -ContentLibraryCleanupExe parameter")
            $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
                $Exception,
                "2",
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                $null
            )
            $PSCmdlet.ThrowTerminatingError($ErrorRecord)
        }
    }
    process {
        if ($Delete.IsPresent) {
            if ($PSCmdlet.ShouldProcess(
                ("Would perform content library cleanup on '{0}'" -f $DistributionPoint),
                "Are you sure you want to continue?",
                ("Warning: calling ContentLibraryCleanup.exe against '{0}' with /delete parameter" -f $DistributionPoint))) {
                    $pArgs = "/dp", $DistributionPoint, "/q", "/delete"
                    & $Path $pArgs
            }
        }
        else {
            $pArgs = "/dp", $DistributionPoint, "/q" 
            & $Path $pArgs
        }
    }
    end {
    }
}