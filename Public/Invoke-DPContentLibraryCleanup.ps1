function Invoke-DPContentLibraryCleanup {
    <#
    .SYNOPSIS
        Short description
    .DESCRIPTION
        Long description
    .EXAMPLE
        PS C:\> <example usage>
        Explanation of what the example does
    .INPUTS
        Inputs (if any)
    .OUTPUTS
        Output (if any)
    .NOTES
        General notes
    #>
    [CmdletBinding()]
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
        [Bool]$Confirm = $true,

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
                $Exception = [Exception]::new("Must run as administrator")
                $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $Exception,
                    "2",
                    [System.Management.Automation.ErrorCategory]::PermissionDenied,
                    $null
                )
                $PSCmdlet.ThrowTerminatingError($ErrorRecord)
            }
        }

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

        $OriginalLocation = (Get-Location).Path

        if($null -eq (Get-PSDrive -Name $SiteCode -PSProvider "CMSite" -ErrorAction "SilentlyContinue")) {
            $null = New-PSDrive -Name $SiteCode -PSProvider "CMSite" -Root $SiteServer -ErrorAction "Stop"
        }

        Set-Location ("{0}:\" -f $SiteCode) -ErrorAction "Stop"

        try {
            $SiteInstallPath = (Get-CMSite -SiteCode $SiteCode -ErrorAction "Stop").InstallDir
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
            $Exception = [Exception]::new("Could not find ContentLibraryCleanup.exe, please use -ContentLibraryCleanupExe parameter")
            $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
                $Exception,
                "2",
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                $null
            )
            $PSCmdlet.ThrowTerminatingError($ErrorRecord)
        }

        $User = "{0}\{1}" -f $env:USERDOMAIN, $env:USERNAME
        try {
            $CMUserObj = Get-CMAdministrativeUser -Name $User -ErrorAction "Stop"
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }

        if (-not $CMUserObj -Or $CMUserObj.RoleNames -notcontains "Full Administrator") {
            $Message = "You user account is not a ConfigMgr Full Administrative in site '{0}'" -f $SiteCode
            $Exception = [Exception]::new($Message)
            $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
                $Exception,
                "2",
                [System.Management.Automation.ErrorCategory]::PermissionDenied,
                $null
            )
            $PSCmdlet.ThrowTerminatingError($ErrorRecord)
        }

        $CMUserScopes = $CMUserObj.Permissions | Where-Object { $_.CategoryTypeID -eq 29 }

        if (-not $CMUserScopes.CategoryName -contains "All") {
            $Message = "You ConfigMgr user does not have the Security Scope 'All' delegated to it" -f $SiteCode
            $Exception = [Exception]::new($Message)
            $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
                $Exception,
                "2",
                [System.Management.Automation.ErrorCategory]::PermissionDenied,
                $null
            )
            $PSCmdlet.ThrowTerminatingError($ErrorRecord)
        }

        Set-Location $OriginalLocation
    }
    process {
        $pArgs = @("/dp", $DistributionPoint)
        if ($Confirm -eq $false) {
            $pArgs += "/q"
        }
        & $Path $pArgs
    }
    end {
    }
}