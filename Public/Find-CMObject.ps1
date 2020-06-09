function Find-CMOBject {
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
        [String[]]$ID,

        # TODO: switch to not return CMObject property (quicker)
        # TODO: put application & deployment type actions in to a child function

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SiteServer = $CMSiteServer,
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SiteCode = $CMSiteCode
    )
    begin {
        #region Define functions
        function Find-CMApplication {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory, ParameterSetName="ModelName")]
                [String]$ModelName,
                [Parameter(Mandatory, ParameterSetName="CI_ID")]
                [String]$CIID,
                [Parameter(Mandatory)]
                [Hashtable]$CimParams
            )
            $Query = "SELECT CI_ID,LocalizedDisplayName,LocalizedDescription FROM SMS_ApplicationLatest WHERE {0} = '{1}'" -f $PSCmdlet.Mandatory, ParameterSetName, $ID
            Get-CimInstance -Query $Query @CimParams | Select-Object -Property @(
                "LocalizedDisplayName"
                "LocalizedDescription"
                @{Label="ObjectType";Expression={"Application"}}
                "CI_ID"
            )
        }

        function Find-CMDeploymentType {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory, ParameterSetName="ModelName")]
                [String]$ModelName,
                [Parameter(Mandatory, ParameterSetName="CI_ID")]
                [String]$CIID,
                [Parameter(Mandatory)]
                [Hashtable]$CimParams
            )
            $Query = "SELECT AppModelName,CI_ID,LocalizedDisplayName FROM SMS_DeploymentType WHERE IsLatest = 'True' AND {0} = '{1}'" -f $PSCmdlet.ParameterSetNAme, $ID
            Get-CimInstance -Query $Query @CimParams | Select-Object -Property @(
                "LocalizedDisplayName"
                "LocalizedDescription"
                @{Label="ObjectType";Expression={"DeploymentType"}}
                "CI_ID"
                @{Label="AppCIID";Expression={ConvertTo-ModelNameCIID -ModelName $_.AppModelName -SiteServer $SiteServer -SiteCode $SiteCode}}
            )
        }

        function Find-CMDriver {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory)]
                [String]$CIID,
                [Parameter(Mandatory)]
                [Hashtable]$CimParams
            )
            $Query = "SELECT CI_ID,LocalizedDisplayName FROM SMS_Driver WHERE CI_ID = '{0}'" -f $CIID
            Get-Ciminstance -query $Query @CimParams | Select-Object -Property @(
                "LocalizedDisplayName"
                @{Label="ObjectType";Expression={"Driver"}}
                "CI_ID"
            )
        }
        #endregion

        switch ($null) {
            $SiteCode {
                Write-Error -Message "Please supply a site code using the -SiteCode parameter" -Category "InvalidArgument" -ErrorAction "Stop"
            }
            $SiteServer {
                Write-Error -Message "Please supply a site server FQDN address using the -SiteServer parameter" -Category "InvalidArgument" -ErrorAction "Stop"
            }
        }

        $GetCimInstanceSplat = @{
            ComputerName    = $SiteServer
            Namespace       = "ROOT/SMS/Site_{0}" -f $SiteCode 
        }

        $OriginalLocation = (Get-Location).Path

        if ($null -eq (Get-PSDrive -Name $SiteCode -PSProvider "CMSite" -ErrorAction "SilentlyContinue")) {
            $null = New-PSDrive -Name $SiteCode -PSProvider "CMSite" -Root $SiteServer -ErrorAction "Stop"
        }

        Set-Location ("{0}:\" -f $SiteCode) -ErrorAction "Stop"
    }
    process {
        :parent switch -Regex ($ID) {
            "^ScopeId_[\w-]+\/Application_[\w-]+$" { # likely modelname for application
                Find-CMApplication -ModelName $_ -CimParams $GetCimInstanceSplat
            }
            "^ScopeId_[\w-]+\/DeploymentType_[\w-]+$" { # likely modelname for deployment type
                Find-CMDeploymentType -ModelName $_ -CimParams $GetCimInstanceSplat
            }
            "^[0-9]{8}$" { # likely CI_ID for application or deployment type or driver
                if ($null -eq (Find-CMApplication -CIID $_ -CimParams $GetCimInstanceSplat)) {
                    if ($null -eq (Find-CMDeploymentType -CIID $_ -CimParams $GetCimInstanceSplat)) {
                        Find-CMDriver -CIID $_ -CimParams $GetCimInstanceSplat
                    }
                }
            }
            "^[a-z0-9]{8}$" {
                $Classes = @(
                    "SMS_Package"
                    "SMS_DriverPackage"
                    "SMS_ImagePackage" # OS Images
                    "SMS_OperatingSystemInstallPackage" # OS Upgrade Packages
                    "SMS_BootImagePackage"
                    "SMS_SoftwareUpdatesPackage"
                    "SMS_ApplicationLatest" # lazy property
                )
                foreach ($Class in $Classes) {
                    $Query = "SELECT PackageID, Name, Description, PackageType FROM {0} WHERE PackageID = '{1}'" -f $Class, $_
                    $result = Get-Ciminstance -Query $Query @GetCimInstanceSplat | Select-Object @(
                        "Name"
                        "Description"
                        @{Label="ObjectType";Expression={[SMS_DPContentInfo]$_.PackageType}}
                        "PackageID"
                    )

                    if ($result -is [object] -and $result.Count -gt 0) {
                        $result
                        continue parent
                    }

                    if ($Class -eq "SMS_ApplicationLatest") {
                        $Query = "SELECT * SMS_ApplicationLaest"
                        $AllApplications = Get-CimInstance -Query $Query @GetCimInstanceSplat
                        foreach ($Application in $AllApplications) {
                            $Properties = $Application | Get-CimInstance
                            if ($Properties.PackageID -eq $_) {
                                $Application
                                continue parent
                            }
                        }
                    }
                }
            }
            default {
                # don't know
            }
        }
    }
    end {
        Set-Location $OriginalLocation
    }
}