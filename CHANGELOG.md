# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]
### Added
- Added Get-DP function
- Added Get-DPGroup function
- Added Start-DPContentRedistribution function
- Added About help topics, run `Get-Help about_PSCMContentMgmt*`

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

[Unreleased]: https://github.com/codaamok/PSCMContentMgmt/compare/1.3.20200821.4..HEAD
[1.3.20200821.4]: https://github.com/codaamok/PSCMContentMgmt/compare/1.2..1.3.20200821.4
[1.2]: https://github.com/codaamok/PSCMContentMgmt/tree/1.2