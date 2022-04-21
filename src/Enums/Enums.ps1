enum SMS_DPContentInfo {
    Package
    DriverPackage               = 3
    TaskSequence                = 4
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
    DISTRIBUTED
    DISTRIBUTION_PENDING        = 1
    DISTRIBUTION_RETRYING       = 2
    DISTRIBUTION_FAILED         = 3
    REMOVAL_PENDING             = 4
    REMOVAL_RETRYING            = 5
    REMOVAL_FAILED              = 6
    CONTENT_UPDATING            = 7
    CONTENT_MONITORING          = 8
}

enum SMS_Collection {
    OtherCollection
    UserCollection              = 1
    DeviceCollection            = 2
}

enum SMS_ConfigurationItemLatest_CIType_ID {
    ConfigurationBaseline       = 2
    ConfigurationItem           = 3
}