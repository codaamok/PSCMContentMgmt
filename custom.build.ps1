<#
.SYNOPSIS
    Build script which leverages the InvokeBuild module. 
.DESCRIPTION
    Build script which leverages the InvokeBuild module.
    This build script is used in the build pipeline and local development for building this project.
    Invoked by invoke.build.ps1 in this project where its intent is to implement project-specific custom pre/post build actions during the build pipeline andds local development.
#>
[CmdletBinding()]
param (
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [String]$ModuleName,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [String]$Author,

    [Parameter()]
    [String]$Version,

    [Parameter()]
    [Bool]$NewRelease
)

task PreBuild {
    if (-not (Get-Module 'ConfigurationManager' -ListAvailable)) {
        Invoke-BuildClean -Path $BuildRoot\misc
        New-Item -Path $BuildRoot\misc\ConfigurationManager\ConfigurationManager.psm1 -ItemType File -Force
        $Params = @{
            Path = '{0}\misc\ConfigurationManager\ConfigurationManager.psd1' -f $BuildRoot
            Guid = (New-Guid).Guid
            RootModule = '{0}\misc\ConfigurationManager\ConfigurationManager.psm1' -f $BuildRoot
        }
        New-ModuleManifest @Params

        $SuccessfullyCopiedModule = $false
        foreach ($ModulePath in $env:PSModulePath.Split([System.IO.Path]::PathSeparator)) {
            try {
                $Params = @{
                    Path        = '{0}\misc\ConfigurationManager' -f $BuildRoot
                    Destination = $ModulePath
                    Recurse     = $true
                    Force       = $true
                    PassThru    = $true
                    ErrorAction = 'Stop'
                }
                Copy-Item @Params
                $SuccessfullyCopiedModule = $true
                break
            }
            catch {
                Write-Warning -Message ('Failed to copy dummy ConfigurationManager module to "{0}" ({1})' -f $ModuleName, $_.Exception.Message)
            }
        }

        if (-not $SuccessfullyCopiedModule) {
            Write-Error "Failed to copy dummy ConfigurationManager module to a PSModulePath folder" -ErrorAction "Stop"
        }
    }
}

task PostBuild {
    Invoke-BuildClean -Path $BuildRoot\misc

    Get-Module 'ConfigurationManager' -ListAvailable | ForEach-Object {
        if ($_ -notmatch 'AdminConsole\\bin') {
            Remove-Item -Path $_.ModuleBase -Recurse -Force -ErrorAction 'Stop'
        }
    }
}

task PreRelease {

}

task PostRelease {

}
