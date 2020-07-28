param (
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [String]$ModuleName = ([Regex]::Match((Get-Content -Path $BuildRoot\.git\config -ErrorAction Stop), "url = https://github\.com/.+/(.+)\.git")).Groups[1].Value
)



# Synopsis: Initiate the entire build process
task . Clean, GetFunctionsToExport, CreateRootModule, CopyFormatFiles, CopyLicense, CreateProcessScript, UpdateModuleManifest, TestManifest

# Synopsis: Cleans the build directory (except .gitkeep)
task Clean {
    Remove-Item -Path $BuildRoot\build\* -Exclude ".gitkeep" -Recurse -Force
}

task GetFunctionsToExport {
    $Files = @(Get-ChildItem $BuildRoot\$ModuleName\Public -Filter *.ps1)

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

# Synopsis: Creates a single .psm1 file of all private and public functions of the to-be-published module
task CreateRootModule {
    $RootModule = New-Item -Path $BuildRoot\build\$ModuleName\$ModuleName.psm1 -ItemType "File" -Force

    foreach ($FunctionType in "Private","Public") {
        '#region {0} functions' -f $FunctionType | Add-Content -Path $RootModule

        $Files = @(Get-ChildItem $BuildRoot\$ModuleName\$FunctionType -Filter *.ps1)

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
    $ScriptsToProcessFolder = "{0}\{1}\ScriptsToProcess" -f $BuildRoot, $ModuleName

    if (Test-Path $ScriptsToProcessFolder) {
        $Script:ProcessFile = New-Item -Path $BuildRoot\build\$ModuleName\Process.ps1 -ItemType "File" -Force
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
    $Script:FormatFiles = Get-ChildItem $BuildRoot\$ModuleName -Filter "*format.ps1xml" | Copy-Item -Destination $BuildRoot\build\$ModuleName
}

task CopyLicense {
    Copy-Item -Path $BuildRoot\LICENSE -Destination $BuildRoot\build\$ModuleName
}

# Synopsis: Copy and update the manifest
task UpdateModuleManifest {
    $Script:ManifestFile = Copy-Item -Path $BuildRoot\$ModuleName\$ModuleName.psd1 -Destination $BuildRoot\build\$ModuleName -PassThru
    
    # Understand that if module isn't currently in the gallery, Invoke-Build will produce a terminating error and the build will fail!
    $PSGallery = Find-Module $ModuleName

    $UpdateModuleManifestSplat = @{
        Path = $Script:ManifestFile
    }

    # Only ever increments the minor, I wonder how I could handle major. Maybe just trigger workflow based on releases and use the version from that instead?
    if ($PSGallery) {
        $UpdateModuleManifestSplat["ModuleVersion"] = '{0}.{1}.{2}' -f ([System.Version]$PSGallery.Version).Major, (([System.Version]$PSGallery.Version).Minor + 1), (Get-Date -Format "yyyyMMdd")
    }

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
}

# Synopsis: Test manifest
task TestManifest {
    # Arguably a moot point as Update-MooduleManifest obviously does some testing to ensure a valid manifest is there first before updating it
    # However with the regex replace for ScriptsToProcess, I want to be sure
    $null = Test-ModuleManifest -Path $Script:ManifestFile
}