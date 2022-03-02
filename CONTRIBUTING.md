# Contributing

Kindly adhere to the principles detailed in this document while contributing.

This project leverages [GitVersion](https://gitversion.net) and tries to adhere to [SemVer](https://semver.org/). 

## Issues

### Bug reports

Raise issues and bug reports with regards to this product in the Issues tab of this project. If an issue exists that might have something to do with yours, e.g. is the basis for something your are requesting, please link this issue to yours.

Provide as much detail as possible. Spare no detail when it comes to logs, console output, or screenshots.

### Fixing an issue

If you're interested in fixing an issue in this project, firstly, thank you! 

1. Contact or discussion ahead of your contribution is encouraged, even if it is just to soundboard. Reach me via email or on [Twitter](https://twitter.com/codaamok), or simply raise an issue or comment on an existing one.
2. Fork the repository and create a branch off of `main`/`master`
   1. If you're creating a new feature, name your branch `feature/<InsertAppropriateDescriptionHere>`. If you're fixing a bug, name your branch `fix/<InsertAppropriateDescriptionHere>`.
3. Write your code
4. Update CHANGELOG.md with your changes (preferably using the [ChangeLogManagement](https://www.powershellgallery.com/packages/ChangelogManagement) PowerShell module for formatting consistency)
5. For good measure, check for any changes to the repo:
```powershell
git remote add upstream https://github.com/codaamok/<NameOfRepo>
git fetch upstream
# If there are changes, pull and work on merge conflicts
git pull --rebase upstream develop
```
6. Make sure you have pushed your commits to your new branch and then create a pull request
