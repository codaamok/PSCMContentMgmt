# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

## [2.0.1] - 2022-04-22
### Changed
- Removed the auto-import of `ConfigurationManager` module, and instead made it a required module in the manifest. This is to better define the dependency and provide a more "traditional" experience. Therefore, you must import the `ConfigurationManager` module before you can use PSCMContentMgmt. 
- Previously, users did not need to specify `-SiteServer` and `-SiteCode` parameters. This is because variables `$CMSiteServer` and `$CMSiteCode` were automatically defined upon import of PSCMContentMgmt (from attempting to read the registry and WMI to determine where the SMS Provider was and the site code). This behaviour has now changed. You must specify `-SiteServer` and `-SiteCode`, but only for at least one command. The same parameter values are remembered for subsequent commands within the same session. See `README.md` for more details.

## [1.8.20201016.0] - 2020-10-16
### Fixed
- Create PS drive for site code and server if it does not exist upon importing the module

## [1.7.20200925.0] - 2020-09-25
### Fixed
- Corrected `Invoke-DPContentLibraryCleanup` to use correct .exe path

## [1.6.20200908.0] - 2020-09-08
### Added
- More properties added to the module manifest

### Changed
- Updated various help content to better describe -ObjectID parameter and ObjectID property

### Fixed
- Corrected CIM query in `Start-DPContentRedistribution` so it actually works. Added error handling to in the event an object is not found to be already distributed to a distribution point.
- More accurate error ID to reflect a win32 error code for access denied in `Import-DPContent`

## [1.5.20200903.0] - 2020-09-03
### Fixed
- Typo in comment based help get Get-DPDistributionStatus

## [1.4.20200903.0] - 2020-09-03
### Added
- New Get-DP function
- New Get-DPGroup function
- New Start-DPContentRedistribution function
- New About help topics, run `Get-Help about_PSCMContentMgmt*`

### Changed
- Get-DPDistributionStatus now accepts value from pipeline or an array of distribution points

### Fixed
- Unable to pipe result of some functions to other functions due to ObjectType property often being an enum rather than string

## [1.3.20200821.4] - 2020-08-21
### Added
- Bundled license file and change log with payload
- Implemented build process to streamline deployment
- Added DeploymentId to Find-CMObject

## [1.2] - 2020-07-30
### Added
- Birth of change log

[Unreleased]: https://github.com/codaamok/PSCMContentMgmt/compare/2.0.1..HEAD
[2.0.1]: https://github.com/codaamok/PSCMContentMgmt/compare/1.8.20201016.0..2.0.1
[1.8.20201016.0]: https://github.com/codaamok/PSCMContentMgmt/compare/1.7.20200925.0..1.8.20201016.0
[1.7.20200925.0]: https://github.com/codaamok/PSCMContentMgmt/compare/1.6.20200908.0..1.7.20200925.0
[1.6.20200908.0]: https://github.com/codaamok/PSCMContentMgmt/compare/1.5.20200903.0..1.6.20200908.0
[1.5.20200903.0]: https://github.com/codaamok/PSCMContentMgmt/compare/1.4.20200903.0..1.5.20200903.0
[1.4.20200903.0]: https://github.com/codaamok/PSCMContentMgmt/compare/1.3.20200821.4..1.4.20200903.0
[1.3.20200821.4]: https://github.com/codaamok/PSCMContentMgmt/compare/1.2..1.3.20200821.4
[1.2]: https://github.com/codaamok/PSCMContentMgmt/tree/1.2