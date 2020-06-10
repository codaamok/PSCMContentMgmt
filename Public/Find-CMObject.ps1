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
                [String]$CI_ID,
                [Parameter(Mandatory)]
                [Hashtable]$CimParams
            )

            $Query = "SELECT CI_ID,LocalizedDisplayName,LocalizedDescription FROM SMS_ApplicationLatest WHERE {0} = '{1}'" -f $PSCmdlet.ParameterSetName, (Get-Variable -Name $PSCmdlet.ParameterSetName).Value
            Get-CimInstance -Query $Query @CimParams | Select-Object -Property @(
                @{Label="Name";Expression={$_.LocalizedDisplayName}}
                @{Label="Description";Expression={$_.LocalizedDescription}}
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
                [String]$CI_ID,
                [Parameter(Mandatory)]
                [Hashtable]$CimParams
            )
            $Query = "SELECT AppModelName,CI_ID,LocalizedDisplayName FROM SMS_DeploymentType WHERE IsLatest = 'True' AND {0} = '{1}'" -f $PSCmdlet.ParameterSetNAme, (Get-Variable -Name $PSCmdlet.ParameterSetName).Value
            Get-CimInstance -Query $Query @CimParams | Select-Object -Property @(
                @{Label="Name";Expression={$_.LocalizedDisplayName}}
                @{Label="Description";Expression={$_.LocalizedDescription}}
                @{Label="ObjectType";Expression={"DeploymentType"}}
                "CI_ID"
                @{Label="AppCIID";Expression={ConvertTo-ModelNameCIID -ModelName $_.AppModelName -SiteServer $SiteServer -SiteCode $SiteCode}}
            )
        }

        function Find-CMDriver {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory, ParameterSetName="ModelName")]
                [String]$ModelName,
                [Parameter(Mandatory, ParameterSetName="CI_ID")]
                [String]$CI_ID,
                [Parameter(Mandatory)]
                [Hashtable]$CimParams
            )
            $Query = "SELECT CI_ID,LocalizedDisplayName FROM SMS_Driver WHERE {0} = '{1}'" -f $PSCmdlet.ParameterSetNAme, (Get-Variable -Name $PSCmdlet.ParameterSetName).Value
            Get-Ciminstance -Query $Query @CimParams | Select-Object -Property @(
                @{Label="Name";Expression={$_.LocalizedDisplayName}}
                @{Label="Description";Expression={$_.LocalizedDescription}}
                @{Label="ObjectType";Expression={"Driver"}}
                "CI_ID"
            )
        }

        function Find-CMCICB {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory, ParameterSetName="ModelName")]
                [String]$ModelName,
                [Parameter(Mandatory, ParameterSetName="CI_ID")]
                [String]$CI_ID,
                [Parameter(Mandatory)]
                [Hashtable]$CimParams
            )
            $Query = "SELECT CI_ID,LocalizedDisplayName,CIType_ID FROM SMS_ConfigurationItemLatest WHERE {0} = '{1}'" -f $PSCmdlet.ParameterSetName, (Get-Variable -Name $PSCmdlet.ParameterSetName).Value
            Get-CimInstance -Query $Query @CimParams | Select-Object -Property @(
                @{Label="Name";Expression={$_.LocalizedDisplayName}}
                @{Label="Description";Expression={$_.LocalizedDescription}}
                @{Label="ObjectType";Expression={[SMS_ConfigurationItemLatest_CIType_ID]$_.CIType_ID}}
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
            "^ScopeId_[\w-]+\/DRIVER_[\w_]+$" {
                Find-CMDriver -ModelName $_ -CimParams $GetCimInstanceSplat
            }
            "^ScopeId_[\w-]+\/LogicalName_[\w-]+$" {
                Find-CMCICB -ModelName $_ -CimParams $GetCimInstanceSplat
            }
            "^[0-9]{8}$" { # likely CI_ID for application or deployment type or driver
                $r = Find-CMCICB -CI_ID $_ -CimParams $GetCimInstanceSplat
                if ($r -is [Object]) { $r; continue parent }
                $r = Find-CMApplication -CI_ID $_ -CimParams $GetCimInstanceSplat
                if ($r -is [Object]) { $r; continue parent }
                $r = Find-CMDeploymentType -CI_ID $_ -CimParams $GetCimInstanceSplat
                if ($r -is [Object]) { $r; continue parent }
                $r = Find-CMDriver -CI_ID $_ -CimParams $GetCimInstanceSplat
                if ($r -is [Object]) { $r; continue parent }
            }
            ("^({0}|SMS)(\w){{5}}$" -f $SiteCode) {
                $ObjectId = $_
                $Classes = @(
                    "SMS_Package"
                    "SMS_DriverPackage"
                    "SMS_ImagePackage"
                    "SMS_OperatingSystemInstallPackage"
                    "SMS_BootImagePackage"
                    "SMS_SoftwareUpdatesPackage"
                    "SMS_Collection"
                    "SMS_ApplicationLatest"
                )
                switch ($Classes) {
                    "SMS_ApplicationLatest" {
                        $Query = "SELECT * FROM {0}" -f $_
                        $AllApplications = Get-CimInstance -Query $Query @GetCimInstanceSplat
                        
                        foreach ($Application in $AllApplications) {
                            $Properties = $Application | Get-CimInstance
                            
                            if ($Properties.PackageID -eq $ObjectId) {
                                $Application | Select-Object -Property @(
                                    @{Label="Name";Expression={$_.LocalizedDisplayName}}
                                    @{Label="Description";Expression={$_.LocalizedDescription}}
                                    @{Label="ObjectType";Expression={"Application"}}
                                    "CI_ID"
                                )
                                continue parent
                            }
                        }
                    }
                    "SMS_Collection" {
                        $Query = "SELECT Name, CollectionID, Comment, CollectionType FROM {0} WHERE CollectionID = '{1}'" -f $_, $ObjectId

                        Get-CimInstance -Query $Query @GetCimInstanceSplat | Select-Object -Property @(
                            "Name",
                            @{Label="Description";Expression={$_.Comment}}
                            @{Label="ObjectType";Expression={[SMS_DPContentInfo]$_.CollectionType}}
                            "CollectionID"
                        )
                    }
                    default {
                        $Query = "SELECT PackageID, Name, Description, PackageType FROM {0} WHERE PackageID = '{1}'" -f $_, $ObjectId
                        
                        Get-Ciminstance -Query $Query @GetCimInstanceSplat | Select-Object -Property @(
                            "Name"
                            "Description"
                            @{Label="ObjectType";Expression={[SMS_DPContentInfo]$_.PackageType}}
                            "PackageID"
                        )
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