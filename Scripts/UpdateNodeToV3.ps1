param (
    [Parameter(Mandatory=$true)]
    [ValidateScript({Get-Service $_ -ErrorAction SilentlyContinue})]
    [string]$mongoServiceName,
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_ })]
    [string]$mongoBinDirectory,    
    [string]$mongoUpgradeZip = ".\mongodb-win32-x86_64-enterprise-windows-64-3.0.11.zip"
)

function Unzip
{
    param([string]$zipFilePath, [string]$outPath)

    New-Item -ItemType Directory -Path $outPath -Force | Out-Null

    $source = (Get-ChildItem $zipFilePath).FullName

    $shell = new-object -com shell.application
    $zipfile = $shell.namespace($source)

    $destination = $shell.namespace($outPath)
    $destination.Copyhere($zipfile.items(), 0x14)
}

function UpgradeMongo
{
    param([string]$serviceName, [string]$sourcePath, [string]$destPath)

    $sourceFiles = Join-Path $sourcePath "*"

    Write-Host "Upgrading Mongo from binaries at $sourceFiles to $destPath"
    Write-Host "Stopping service $serviceName"
    Stop-Service $serviceName -ErrorAction Stop

    Write-Host "Copying files"
    Copy-Item -Path $sourceFiles -Destination $destPath -ErrorAction Stop

    Write-Host "Starting service $serviceName" -ErrorAction Stop
    Start-Service $serviceName
}

if(-Not { Join-Path $mongoBinDirectory "mongod.exe" | Test-Path })
{
    Write-Error "$mongoBinDirectory doesn't contain the mongod.exe please check the supplied value is correct"
    return
}

if(-Not ((Test-Path $mongoUpgradeZip) -and ([System.IO.Path]::GetExtension($mongoUpgradeZip) -eq ".zip")))
{
    Write-Error "$mongoUpgradeZip isn't a zip file or the file does not exist"
    return
}

$unzippedDestination = Join-Path $env:TEMP "mongodb_3.0.11_unpacked\"
Unzip $mongoUpgradeZip $unzippedDestination

$binDirectory = Join-Path $unzippedDestination mongodb-win32-x86_64-enterprise-windows-64-3.0.11\bin

if(-Not { Test-Path $binDirectory })
{
    Write-Error "File unzipped at $unzippedDestination doesn't contain the expected structure, verify you pointed it to a Mongo 3.0.11 zip"
    return
}

UpgradeMongo $mongoServiceName $binDirectory $mongoBinDirectory
Write-Warning "Mongo upgraded and service started, please verify everything is ok!"