name: "CI/CD Pipeline"

on: 
  push:
    paths:
      - 'src/**'
    branches:
      - main
      - master
  schedule:
    - cron: '33 8 * * *'
  workflow_dispatch:

jobs:
  job-main:
    name: main
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v2.3.1
        with:
          fetch-depth: 0

      - name: Install GitVersion
        uses: gittools/actions/gitversion/setup@v0.9.10
        with:
          versionSpec: '5.x'

      - name: Determine Version
        id: gitversion
        uses: gittools/actions/gitversion/execute@v0.9.10
        with:
          useConfigFile: true

      - name: Install codaamok.build and dependent modules, and set environment variables
        run: |
          Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
          Install-Module "InvokeBuild" -Force
          $Username, $ProjectName = $env:GITHUB_REPOSITORY -split "/"
          Invoke-Build -File "invoke.build.ps1" -ModuleName $ProjectName -Author $Username -Task "InstallDependencies","ImportBuildModule","SetGitHubActionEnvironmentVariables"
        shell: pwsh

      - name: Build
        run: |
          $Params = @{
            ModuleName = $env:GH_PROJECTNAME
            Author     = $env:GH_USERNAME
            Version    = $env:GitVersion_SemVer
            NewRelease = ('push','workflow_dispatch' -contains $env:EVENT_NAME)
          }
          Invoke-Build -File "custom.build.ps1" @Params -Task PreBuild
          Invoke-Build -File "invoke.build.ps1" @Params
          Invoke-Build -File "custom.build.ps1" @Params -Task PostBuild
        shell: pwsh
        env:
          EVENT_NAME: ${{ github.event_name }}

      - name: Pester Tests
        if: hashFiles('tests/invoke.tests.ps1') != ''
        run: pwsh -File "tests/invoke.tests.ps1"

      - name: Custom pre-release tasks
        if: ${{ github.event_name == 'push' || github.event_name == 'workflow_dispatch' }}
        run: Invoke-Build -File "custom.build.ps1" -ModuleName $env:GH_PROJECTNAME -Author $env:GH_USERNAME -Version $env:GitVersion_SemVer -NewRelease $true -Task PreRelease
        shell: pwsh

      - name: Publish to PowerShell Gallery
        if: ${{ github.event_name == 'push' || github.event_name == 'workflow_dispatch' }}
        run: Invoke-Build -File "invoke.build.ps1" -ModuleName $env:GH_PROJECTNAME -Task "PublishModule"
        shell: pwsh
        env:
          PSGALLERY_API_KEY: ${{ secrets.PSGALLERY_API_KEY }}

      - name: Create release
        if: ${{ github.event_name == 'push' || github.event_name == 'workflow_dispatch' }}
        id: create_release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: v${{ env.GitVersion_SemVer }}
          release_name: v${{ env.GitVersion_SemVer }}
          body_path: release/releasenotes.txt
          draft: false
          prerelease: false

      - name: Upload release asset
        if: ${{ github.event_name == 'push' || github.event_name == 'workflow_dispatch' }}
        id: upload_release_asset
        uses: actions/upload-release-asset@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          upload_url:  ${{ steps.create_release.outputs.upload_url }}
          asset_path: release/${{ env.GH_PROJECTNAME }}_${{ env.GitVersion_SemVer }}.zip
          asset_name: ${{ env.GH_PROJECTNAME }}_${{ env.GitVersion_SemVer }}.zip
          asset_content_type: application/zip

      - name: Commit CHANGELOG.md and module manifest
        if: ${{ github.event_name == 'push' || github.event_name == 'workflow_dispatch' }}
        run: |
          git config --global user.email "action@github.com"
          git config --global user.name "GitHub Action"
          git add CHANGELOG.md src/${GH_PROJECTNAME}.psd1 docs
          git commit -m "Released ${{ env.GitVersion_SemVer }}"
      
      - name: Push commit
        if: ${{ github.event_name == 'push' || github.event_name == 'workflow_dispatch' }}
        uses: ad-m/github-push-action@master
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}

      - name: Custom post-release tasks
        if: ${{ github.event_name == 'push' || github.event_name == 'workflow_dispatch' }}
        run: Invoke-Build -File "custom.build.ps1" -ModuleName $env:GH_PROJECTNAME -Author $env:GH_USERNAME -Version $env:GitVersion_SemVer -NewRelease $true -Task PostRelease
        shell: pwsh