try {
    $CMSiteServer = Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Microsoft\ConfigMgr10\AdminUI\Connection" -ErrorAction Stop | Select-Object -ExpandProperty Server
    try {
        $CMSiteCode = Get-CimInstance -ClassName "SMS_ProviderLocation" -Name "ROOT\SMS" -ComputerName $CMSiteServer -ErrorAction Stop | Select-Object -ExpandProperty SiteCode
    }
    catch {
        $CMSiteCode = $null
    }
}
catch {
    $CMSiteServer = $null
}

# These are named as per parameters for Publish-CMPrestageContent and Start-CMContentDistribution and values line up with what's in SMS_DPContentInfo for content object types
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

enum SMS_PackageStatusDistPointsSummarizer {
    Package
    DriverPackage               = 3
    DeploymentPackage           = 5
    Application                 = 8
    OperatingSystemImage        = 257
    OperatingSystemInstaller    = 259
    BootImage                   = 258
}
