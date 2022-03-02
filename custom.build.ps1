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

}

task PostBuild {

}

task PreRelease {

}

task PostRelease {

}
