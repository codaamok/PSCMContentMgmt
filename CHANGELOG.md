# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

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

[Unreleased]: https://github.com/codaamok/PSCMContentMgmt/compare/1.7.20200925.0..HEAD
[1.7.20200925.0]: https://github.com/codaamok/PSCMContentMgmt/compare/1.6.20200908.0..1.7.20200925.0
[1.6.20200908.0]: https://github.com/codaamok/PSCMContentMgmt/compare/1.5.20200903.0..1.6.20200908.0
[1.5.20200903.0]: https://github.com/codaamok/PSCMContentMgmt/compare/1.4.20200903.0..1.5.20200903.0
[1.4.20200903.0]: https://github.com/codaamok/PSCMContentMgmt/compare/1.3.20200821.4..1.4.20200903.0
[1.3.20200821.4]: https://github.com/codaamok/PSCMContentMgmt/compare/1.2..1.3.20200821.4
[1.2]: https://github.com/codaamok/PSCMContentMgmt/tree/1.2