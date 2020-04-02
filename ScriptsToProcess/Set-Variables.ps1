try {
    $CMSiteServer = Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Microsoft\ConfigMgr10\AdminUI\Connection" -ErrorAction "Stop" | Select-Object -ExpandProperty Server
    try {
        $CMSiteCode = Get-CimInstance -ClassName "SMS_ProviderLocation" -Name "ROOT\SMS" -ComputerName $CMSiteServer -ErrorAction "Stop" | Select-Object -ExpandProperty SiteCode
    }
    catch {
        Write-Warning ('Could not auto-populate variable $CMSiteCode, either set this yourself or pass -SiteCode to all functions for this module ({0})' -f $_.Exception.Message)
        $CMSiteCode = $null
    }
}
catch {
    Write-Warning ('Could not auto-populate variable $CMSiteServer, either set this yourself or pass -SiteServer to all functions for this module ({0})' -f $_.Exception.Message)
    $CMSiteServer = $null
}

enum SMS_DPContentInfo {
    Package
    DriverPackage               = 3
    DeploymentPackage           = 5
    OperatingSystemImage        = 257
    OperatingSystemInstaller    = 259
    BootImage                   = 258
    Application                 = 512
}

enum SMS_DPContentInfo_CMParameters {
    PackageID
    DriverPackageID             = 3
    DeploymentPackageID         = 5
    OperatingSystemImageId      = 257
    OperatingSystemInstallerId  = 259
    BootImageId                 = 258
    ApplicationId               = 512
}

enum SMS_PackageStatusDistPointsSummarizer_PackageType {
    Package
    DriverPackage               = 3
    DeploymentPackage           = 5
    Application                 = 8
    OperatingSystemImage        = 257
    OperatingSystemInstaller    = 259
    BootImage                   = 258
}

enum SMS_PackageStatusDistPointsSummarizer_State {
    DISTRIBUTED	                = 0
    DISTRIBUTION_PENDING	    = 1
    DISTRIBUTION_RETRYING	    = 2
    DISTRIBUTION_FAILED	        = 3
    REMOVAL_PENDING	            = 4
    REMOVAL_RETRYING	        = 5
    REMOVAL_FAILED	            = 6
    CONTENT_UPDATING	        = 7
    CONTENT_MONITORING	        = 8
}
