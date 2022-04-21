function Export-DPContent {
    <#
    .SYNOPSIS
        Exports distribution point content to .pkgx files.
    .DESCRIPTION
        Exports distribution point content to .pkgx files.

        This is also no more than just an extensive wrapper for the Configuration Mananager cmdlet Publish-CMPrestageContent. Export-DPContent adds value by accepting pipeline support for an easy workflow.

        Export-DPContent can be useful if you want to migrate the content library of one distribution point to another by also using Import-DPContent. If this is your intent, please read the CONTENT LIBRARY MIRATION section in the About help topic about_PSCMContentMgmt_ExportImport.
    .PARAMETER InputObject
        A PSObject type "PSCMContentMgmt" generated by Get-DPContent
    .PARAMETER DistributionPoint
        Name of distribution point (as it appears in Configuration Manager, usually FQDN) you want to export content from.
    .PARAMETER ObjectID
        Unique ID of the content object you want to export.

        For Applications the ID must be the CI_ID value whereas for all other content objects the ID is PackageID.

        When using this parameter you must also use ObjectType.
    .PARAMETER ObjectType
        Object type of the content object you want to export.

        Can be one of the following values: "Package", "DriverPackage", "DeploymentPackage", "OperatingSystemImage", "OperatingSystemInstaller", "BootImage", "Application".

        When using this parameter you must also use ObjectID.
    .PARAMETER Folder
        The target directory to store the generated .pkgx files in.
    .PARAMETER SiteServer
        FQDN address of the site server (SMS Provider). 
        
        You only need to use this parameter once for any function of PSCMContentMgmt that also has a -SiteServer parameter. PSCMContentMgmt remembers the site server for subsequent commands, unless you specify the parameter again to change site server.
    .PARAMETER SiteCode
        Site code of which the server specified by -SiteServer belongs to.

        You only need to use this parameter once for any function of PSCMContentMgmt that also has a -SiteCode parameter. PSCMContentMgmt remembers the site code for subsequent commands, unless you specify the parameter again to change site code.
    .INPUTS
        System.Management.Automation.PSObject
    .OUTPUTS
        System.Management.Automation.PSObject
    .EXAMPLE
        PS C:\> Get-DPContent -DistributionPoint "dp1.contoos.com" | Export-DPContent -Folder "E:\prestaged"

        Gathers all content objects on dp1.contoso.com and exports them to .pkgx files in E:\prestaged, overwriting any files that already exist with the same name.
    .EXAMPLE
        PS C:\> Compare-DPContent -Source "dp1.contoso.com" -Target "dp2.contoso.com" | Export-DPContent -Folder "E:\prestaged"

        Compares the missing content objects on dp2.contoso.com compared to dp1.contoso.com, and exports them to "E:\prestaged".
    .EXAMPLE
        PS C:\> Export-DPContent -DistributionPoint "dp1.contoso.com" -ObjectID "P01000F6" -ObjectType "Package" -Folder "E:\prestaged"

        Exports package item P01000F6 from dp1.contoos.com and saves the exported .pkgx file in E:\prestaged.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Low")]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName="InputObject")]
        [PSTypeName('PSCMContentMgmt')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory, ParameterSetName="SpecifyProperties")]
        [ValidateNotNullOrEmpty()]
        [String]$ObjectID,

        [Parameter(Mandatory, ParameterSetName="SpecifyProperties")]
        [ValidateSet("Package","DriverPackage","DeploymentPackage","OperatingSystemImage","OperatingSystemInstaller","BootImage","Application")]
        [SMS_DPContentInfo]$ObjectType,

        [Parameter(Mandatory)]
        [ValidateScript({
            if (!([System.IO.Directory]::Exists($_))) {
                throw "Invalid path or access denied"
            } elseif (!($_ | Test-Path -PathType Container)) {
                throw "Value must be a directory, not a file"
            } else {
                return $true
            }
        })]
        [String]$Folder,

        [Parameter(Mandatory, ParameterSetName="SpecifyProperties")]
        [ValidateNotNullOrEmpty()]
        [String]$DistributionPoint,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SiteServer,
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SiteCode
    )
    begin {
        Set-SiteServerAndSiteCode -SiteServer $Local:SiteServer -SiteCode $Local:SiteCode

        $TargetDP = $DistributionPoint

        if ($PSCmdlet.ParameterSetName -ne "InputObject") {
            $InputObject = [PSCustomObject]@{
                ObjectID          = $ObjectID
                ObjectType        = $ObjectType
                DistributionPoint = $TargetDP
            }
        }

        $OriginalLocation = (Get-Location).Path

        if($null -eq (Get-PSDrive -Name $Script:SiteCode -PSProvider "CMSite" -ErrorAction "SilentlyContinue")) {
            $null = New-PSDrive -Name $Script:SiteCode -PSProvider "CMSite" -Root $Script:SiteServer -ErrorAction "Stop"
        }

        Set-Location ("{0}:\" -f $Script:SiteCode) -ErrorAction "Stop"
    }
    process {
        try {
            foreach ($Object in $InputObject) {
                switch ($true) {
                    ($LastDP -ne $Object.DistributionPoint -And -not $PSBoundParameters.ContainsKey("DistributionPoint")) {
                        $TargetDP = $Object.DistributionPoint
                    }
                    ($LastDP -ne $TargetDP) {
                        try {
                            Resolve-DP -Name $TargetDP -SiteServer $Script:SiteServer -SiteCode $Script:SiteCode
                        }
                        catch {
                            Write-Error -ErrorRecord $_
                            return
                        }
                        
                        $LastDP = $TargetDP
                    }
                    default {
                        $LastDP = $TargetDP
                    }
                }

                $File = "{0}_{1}.pkgx" -f [int][SMS_DPContentInfo]$Object.ObjectType, $Object.ObjectID
                $Path = Join-Path -Path $Folder -ChildPath $File
        
                $result = @{ 
                    PSTypeName = "PSCMContentMgmtPrestage"
                    ObjectID   = $Object.ObjectID
                    ObjectType = $Object.ObjectType
                    Message    = $null
                }
        
                $Command = 'Publish-CMPrestageContent -{0} "{1}" -DistributionPointName "{2}" -FileName "{3}"' -f [SMS_DPContentInfo_CMParameters][SMS_DPContentInfo]$Object.ObjectType, $Object.ObjectID, $TargetDP, $Path
                $ScriptBlock = [ScriptBlock]::Create($Command)
                try {
                    if ($PSCmdlet.ShouldProcess(
                        ("Would export '{0}' ({1}) to '{2}'" -f $Object.ObjectID, $Object.ObjectType, $Folder),
                        "Are you sure you want to continue?",
                        ("Exporting '{0}' ({1}) to '{2}'" -f $Object.ObjectID, $Object.ObjectType, $Folder))) {
                            Invoke-Command -ScriptBlock $ScriptBlock -ErrorAction "Stop"
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
