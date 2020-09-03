# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]
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

[Unreleased]: https://github.com/codaamok/PSCMContentMgmt/compare/1.4.20200903.0..HEAD
[1.4.20200903.0]: https://github.com/codaamok/PSCMContentMgmt/compare/1.3.20200821.4..1.4.20200903.0
[1.4.20200902.1]: https://github.com/codaamok/PSCMContentMgmt/compare/1.3.20200821.4..1.4.20200902.1
[1.4.20200902.0]: https://github.com/codaamok/PSCMContentMgmt/compare/1.3.20200821.4..1.4.20200902.0
[1.3.20200821.4]: https://github.com/codaamok/PSCMContentMgmt/compare/1.2..1.3.20200821.4
[1.2]: https://github.com/codaamok/PSCMContentMgmt/tree/1.2