<#
    .SYNOPSIS
        This script verifies, tests, builds and packages this application
#>
param (
    # Target architecture: amd64 (default) or 386
    [ValidateSet("amd64", "386")]
    [string]$arch="amd64",
    [string]$version="0.0.0"
)

$target = $(Split-Path -Leaf $PSScriptRoot)
$targetName = "$target.exe"

# verifying version number format
$v = $version.Split(".")

if ($v.Length -ne 3) {
    Write-Output "-version must follow a numeric major.minor.patch semantic versioning schema (received: $version)"
    exit -1
}

$wrong = $v | ? { (-Not [System.Int32]::TryParse($_, [ref]0)) -or ( $_.Length -eq 0) -or ([int]$_ -lt 0)} | % { 1 }
if ($wrong.Length  -ne 0) {
    Write-Output "-version major, minor and patch must be valid positive integers (received: $version)"
    exit -1
}

Write-Output "--- Checking dependencies"

Write-Output "Checking Go..."
go version
if (-not $?)
{
    Write-Output "Can't find Go"
    exit -1
}

Write-Output "--- Checking MSBuild.exe..."
$msBuild = (Get-ItemProperty hklm:\software\Microsoft\MSBuild\ToolsVersions\4.0).MSBuildToolsPath
if ($msBuild.Length -eq 0) {
    Write-Output "Can't find MSBuild tool. .NET Framework 4.0.x must be installed"
    exit -1
}
# Write-Output $msBuild

$env:GOOS="windows"
$env:GOARCH=$arch

Write-Output "--- Collecting files"

$goFiles = go list ./...

Write-Output "--- Check that go-bindata has generated the data"
$EmbeddedFileName="Data.go"
if ((Test-Path "src\$EmbeddedFileName" -PathType Leaf) -eq $False) {
    go-bindata -o "./src/$EmbeddedFileName" data/
    Write-Output "data file was created."
}

Write-Output "--- Format check"

$wrongFormat = go fmt $goFiles

if ($wrongFormat -and ($wrongFormat.Length -gt 0))
{
    Write-Output "ERROR: Wrong format for files:"
    Write-Output $wrongFormat
    exit -1
}

Write-Output "--- Running Build"

#go build -v $goFiles
if (-not $?)
{
    Write-Output "Failed building files"
    exit -1
}

Write-Output "--- Collecting Go main files"

$packages = go list -f "{{.ImportPath}} {{.Name}}" ./...  | ConvertFrom-String -PropertyNames Path, Name
$mainPackage = $packages | ? { $_.Name -eq 'main' } | % { $_.Path }

Write-Output "--- Generating $target package"
go generate $mainPackage

$fileName = ([io.fileinfo]$mainPackage).BaseName

Write-Output "--- Creating $targetName"
go build -ldflags "-X main.buildVersion=$version" -o ".\build\windows_$arch\$targetName" $mainPackage


Pop-Location
