#Requires -Module "ChangelogManagement", "PlatyPS"
[CmdletBinding()]
param (
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [String]$ModuleName = $env:GH_PROJECTNAME,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [String]$Author = $env:GH_USERNAME,

    [Parameter()]
    [Switch]$UpdateDocs,

    [Parameter()]
    [Switch]$NewRelease
)

# Synopsis: Initiate the entire build process
task . Clean, GetPSGalleryVersionNumber, CopyChangeLog, GetChangelog, GetReleaseNotes, GetVersionToBuild, UpdateChangeLog, GetFunctionsToExport, CreateRootModule, CopyFormatFiles, CopyLicense, CreateProcessScript, CopyAboutHelp, CopyModuleManifest, UpdateModuleManifest, CreateReleaseAsset, UpdateDocs

# Synopsis: Empty the contents of the build and release directories. If not exist, create them.
task Clean {
    $Paths = @(
        "{0}\build\{1}" -f $BuildRoot, $Script:ModuleName
        "{0}\release" -f $BuildRoot
    )

    foreach ($Path in $Paths) {
        if (Test-Path $Path) {
            Remove-Item -Path $Path\* -Recurse -Force
        }
        else {
            $null = New-Item -Path $Path -ItemType "Directory" -Force
        }
    }
}

# Synopsis: Get current version number of module in PowerShell Gallery (if published)
task GetPSGalleryVersionNumber {
    try {
        $Script:PSGalleryModuleInfo = Find-Module -Name $Script:ModuleName -ErrorAction "Stop"
    }
    catch {
        if ($_.Exception.Message -notmatch "No match was found for the specified search criteria") {
            throw $_
        }
    }

    if (-not $Script:PSGalleryModuleInfo) {
        $Script:PSGalleryModuleInfo = [PSCustomObject]@{
            "Name"    = $Script:ModuleName
            "Version" = "0.0"
        }
    }

    Write-Output ("PowerShell Gallery verison: {0}" -f $Script:PSGalleryModuleInfo.Version)
}

# Synopsis: Copy CHANGELOG.md (must exist)
task CopyChangeLog {
    Copy-Item -Path $BuildRoot\CHANGELOG.md -Destination $BuildRoot\build\$Script:ModuleName\CHANGELOG.md
}

# Synopsis: Get change log
task GetChangelog {
    $Script:ChangeLog = Get-ChangeLogData -Path $BuildRoot\CHANGELOG.md
    Write-Output ("Last released version: {0}" -f $Script:ChangeLog.Released[0].Version)
}

# Synopsis: Read change log for Unreleased release notes and create releasenotes.txt in release directory
task GetReleaseNotes {
    $EmptyChangeLog = $true

    $Script:ReleaseNotes = foreach ($Property in $Script:ChangeLog.Unreleased[0].Data.PSObject.Properties.Name) {
        $Data = $Script:ChangeLog.Unreleased[0].Data.$Property

        if ($Data) {
            $EmptyChangeLog = $false

            Write-Output $Property

            foreach ($item in $Data) {
                Write-Output ("- {0}" -f $item)
            }
        }
    }

    if ($EmptyChangeLog -eq $true -Or $Script:ReleaseNotes.Count -eq 0) {
        if ($NewRelease.IsPresent) {
            throw "Can not build with empty Unreleased section in the change log"
        }
        else {
            $Script:ReleaseNotes = "None"
        }
    }

    Write-Output "Release notes:"
    Write-Output $Script:ReleaseNotes

    Set-Content -Value $Script:ReleaseNotes -Path $BuildRoot\release\releasenotes.txt -Force
}

# Synopsis: Determine version number to build blish with by evaluating versions in PowerShell Gallery and in the change log
task GetVersionToBuild {
    if ($NewRelease.IsPresent) {
        $Date = Get-Date -Format 'yyyyMMdd'

        # If the last released version in the change log and latest version available in the PowerShell gallery don't match, throw an exception - get them level!
        if ($null -ne $Script:ChangeLog.Released[0].Version -And $Script:ChangeLog.Released[0].Version -ne $Script:PSGalleryModuleInfo.Version) {
            throw "The latest released version in the changelog does not match the latest released version in the PowerShell gallery"
        }
        # If module isn't yet published in the PowerShell gallery, and there's no Released section in the change log, set initial version
        elseif ($Script:PSGalleryModuleInfo.Version -eq "0.0" -And $Script:ChangeLog.Released.Count -eq 0) {
            $Script:VersionToBuild = [System.Version]::New(1, 0, $Date, 0)
        }
        # If module isn't yet published in the PowerShell gallery, and there is a Released section in the change log, update version
        elseif ($Script:PSGalleryModuleInfo.Version -eq "0.0" -And $Script:ChangeLog.Released.Count -ge 1) {
            $CurrentVersion        = [System.Version]$Script:ChangeLog.Released[0].Version
            $Script:VersionToBuild = [System.Version]::New($CurrentVersion.Major, $CurrentVersion.Minor + 1, $Date, 0)
        }
        # If the last Released verison in the change log and currently latest verison in the PowerShell gallery are in harmony, update version
        elseif ($Script:ChangeLog.Released[0].Version -eq $Script:PSGalleryModuleInfo.Version) {
            $CurrentVersion        = [System.Version]$Script:PSGalleryModuleInfo.Version
            $Script:VersionToBuild = [System.Version]::New($CurrentVersion.Major, $CurrentVersion.Minor + 1, $Date, 0)
        }
        else {
            Write-Output ("Latest release version from change log: {0}" -f $Script:ChangeLog.Released[0].Version)
            Write-Output ("Latest release version from PowerShell gallery: {0}" -f $Script:PSGalleryModuleInfo.Version)
            throw "Can not determine next version number"
        }
    
        # Suss out unlisted packages
        for ($i = $Script:VersionToBuild.Revision; $i -le 100; $i++) {
            if ($i -eq 100) {
                throw "You have 100 unlisted packages under the same build number? Sort your life out."
            }
    
            try {
                $Script:PSGalleryModuleInfo = Find-Module -Name $Script:ModuleName -RequiredVersion $Script:VersionToBuild
                if ($Script:PSGalleryModuleInfo) {
                    $Script:VersionToBuild = [System.Version]::New($Script:VersionToBuild.Major, $Script:VersionToBuild.Minor, $Script:VersionToBuild.Build, $i)
                }
                else {
                    throw "Unusual no object or exception caught from Find-Module"
                }
            }
            catch {
                if ($_.Exception.Message -match "No match was found for the specified search criteria") {
                    # Found next available version to use
                    break
                }
                else {
                    throw $_
                }
            }
        }
    }
    else {
        $ModuleManifest = Import-PowerShellDataFile -Path $BuildRoot\$Script:ModuleName\$Script:ModuleName.psd1
        if ($Script:ChangeLog.Released[0].Version -eq $ModuleManifest.ModuleVersion) {
            $Script:VersionToBuild = [System.Version]::New(([System.Version]$ModuleManifest.ModuleVersion).Major, ([System.Version]$ModuleManifest.ModuleVersion).Minor, ([System.Version]$ModuleManifest.ModuleVersion).Build, ([System.Version]$ModuleManifest.ModuleVersion).Revision + 1)
        }
        else {
            throw "Can not build with unmatching module version numbers in the change log and module manifest"
        }
    }

    Write-Output ("Version to build: {0}" -f $Script:VersionToBuild)
    Write-Output ("::set-env name=VersionToBuild::{0}" -f $Script:VersionToBuild)
}

# Synopsis: Update CHANGELOG.md if building a new release (-NewRelease switch parameter)
task UpdateChangeLog -If ($NewRelease.IsPresent) {
    $LinkPattern   = @{
        FirstRelease  = "https://github.com/{0}/{1}/tree/{{CUR}}" -f $Script:Author, $Script:ModuleName
        NormalRelease = "https://github.com/{0}/{1}/compare/{{PREV}}..{{CUR}}" -f $Script:Author, $Script:ModuleName
        Unreleased    = "https://github.com/{0}/{1}/compare/{{CUR}}..HEAD" -f $Script:Author, $Script:ModuleName
    }

    Update-Changelog -Path $BuildRoot\build\$Script:ModuleName\CHANGELOG.md -ReleaseVersion $Script:VersionToBuild -LinkMode Automatic -LinkPattern $LinkPattern
}

# Synopsis: Gather all exported functions to populate manifest with
task GetFunctionsToExport {
    $Files = @(Get-ChildItem $BuildRoot\$Script:ModuleName\Public -Filter *.ps1)

    $Script:FunctionsToExport = foreach ($File in $Files) {
        try {
            $tokens = $errors = @()
            $Ast = [System.Management.Automation.Language.Parser]::ParseFile(
                $File.FullName,
                [ref]$tokens,
                [ref]$errors
            )

            if ($errors[0].ErrorId -eq 'FileReadError') {
                throw [InvalidOperationException]::new($errors[0].Message)
            }

            Write-Output $Ast.EndBlock.Statements.Name
        }
        catch {
            Write-Error -Exception $_.Exception -Category "OperationStopped"
        }
    }
}

# Synopsis: Creates a single .psm1 file of all private and public functions of the to-be-built module
task CreateRootModule {
    $RootModule = New-Item -Path $BuildRoot\build\$Script:ModuleName\$Script:ModuleName.psm1 -ItemType "File" -Force

    foreach ($FunctionType in "Private","Public") {
        '#region {0} functions' -f $FunctionType | Add-Content -Path $RootModule

        $Files = @(Get-ChildItem $BuildRoot\$Script:ModuleName\$FunctionType -Filter *.ps1)

        foreach ($File in $Files) {
            Get-Content -Path $File.FullName | Add-Content -Path $RootModule

            # Add new line only if the current file isn't the last one (minus 1 because array indexes from 0)
            if ($Files.IndexOf($File) -ne ($Files.Count - 1)) {
                Write-Output "" | Add-Content -Path $RootModule
            }
        }

        '#endregion' -f $FunctionType | Add-Content -Path $RootModule
        Write-Output "" | Add-Content -Path $RootModule
    }
}

# Synopsis: Create a single Process.ps1 script file for all script files under ScriptsToProcess\* (if any)
task CreateProcessScript {
    $ScriptsToProcessFolder = "{0}\{1}\ScriptsToProcess" -f $BuildRoot, $Script:ModuleName

    if (Test-Path $ScriptsToProcessFolder) {
        $Script:ProcessFile = New-Item -Path $BuildRoot\build\$Script:ModuleName\Process.ps1 -ItemType "File" -Force
        $Files = @(Get-ChildItem $ScriptsToProcessFolder -Filter *.ps1)
    }

    foreach ($File in $Files) {
        Get-Content -Path $File.FullName | Add-Content -Path $Script:ProcessFile

        # Add new line only if the current file isn't the last one (minus 1 because array indexes from 0)
        if ($Files.IndexOf($File) -ne ($Files.Count - 1)) {
            Write-Output "" | Add-Content -Path $Script:ProcessFile
        }
    }
}

# Synopsis: Copy format files (if any)
task CopyFormatFiles {
    $Script:FormatFiles = Get-ChildItem $BuildRoot\$Script:ModuleName -Filter "*format.ps1xml" | Copy-Item -Destination $BuildRoot\build\$Script:ModuleName
}

# Synopsis: Copy LICENSE file (must exist)
task CopyLicense {
    Copy-Item -Path $BuildRoot\LICENSE -Destination $BuildRoot\build\$Script:ModuleName\LICENSE
}

# Synopsis: Copy "About" help files (must exist)
task CopyAboutHelp {
    Copy-Item -Path $BuildRoot\$Script:ModuleName\en-US -Destination $BuildRoot\build\$Script:ModuleName -Recurse
}

# Synopsis: Copy module manifest files (must exist)
task CopyModuleManifest {
    $Script:ManifestFile = Copy-Item -Path $BuildRoot\$Script:ModuleName\$Script:ModuleName.psd1 -Destination $BuildRoot\build\$Script:ModuleName\$Script:ModuleName.psd1 -PassThru
}

# Synopsis: Copy and update the manifest in build directory. If successfully, replace manifest in the module directory
task UpdateModuleManifest {  
    $UpdateModuleManifestSplat = @{
        Path = $Script:ManifestFile
    }

    $UpdateModuleManifestSplat["ModuleVersion"] = $Script:VersionToBuild

    $UpdateModuleManifestSplat["ReleaseNotes"] = $Script:ReleaseNotes

    if ($Script:FormatFiles) {
        $UpdateModuleManifestSplat["FormatsToProcess"] = $Script:FormatFiles.Name
    }

    if ($Script:ProcessFile) {
        # Use this instead of Updatet-ModuleManifest due to https://github.com/PowerShell/PowerShellGet/issues/196
        (Get-Content -Path $Script:ManifestFile.FullName) -replace '(#? ?ScriptsToProcess.+)', ('ScriptsToProcess = "{0}"' -f $Script:ProcessFile.Name) | Set-Content -Path $ManifestFile
    }

    if ($Script:FunctionsToExport) {
        $UpdateModuleManifestSplat["FunctionsToExport"] = $Script:FunctionsToExport
    }
    
    Update-ModuleManifest @UpdateModuleManifestSplat

    # Arguably a moot point as Update-MooduleManifest obviously does some testing to ensure a valid manifest is there first before updating it
    # However with the regex replace for ScriptsToProcess, I want to be sure
    $null = Test-ModuleManifest -Path $Script:ManifestFile
}

# Synopsis: Create release asset (archived module)
task CreateReleaseAsset {
    $ReleaseAsset = "{0}_{1}.zip" -f $Script:ModuleName, $Script:VersionToBuild
    Compress-Archive -Path $BuildRoot\build\$Script:ModuleName\* -DestinationPath $BuildRoot\release\$ReleaseAsset -Force
}

# Synopsis: Update documentation (-NewRelease or -UpdateDocs switch parameter)
task UpdateDocs -If ($NewRelease.IsPresent -Or $UpdateDocs.IsPresent) {
    Import-Module -Name $BuildRoot\build\$Script:ModuleName -Force -ErrorAction "Stop"
    New-MarkdownHelp -Module $Script:ModuleName -OutputFolder $BuildRoot\docs -Force
}
