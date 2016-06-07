param (
    [Parameter(Mandatory=$true)]
    [ValidateScript({Get-Service $_ -ErrorAction SilentlyContinue})]
    [string]$mongoServiceName,
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_ })]
    [string]$mongoDirectory,    
    [string]$mongoUpgradeMsi = ".\mongodb-win32-x86_64-enterprise-windows-64-3.0.12-signed.msi",
    [ValidateScript({Test-Path $_ })]
    [string]$configFileSource = ".\configs\mongoconfig.conf",
    [ValidateScript({Test-Path $_ })]
    [string]$configFileToUpgrade = (Join-Path $mongoDirectory  "mongodb.conf")
)

function ReplaceConfiguration()
{
    param([string]$source, [string]$configFileToUpgrade)

    Write-Host "Copying configuration from $source to $configFileToUpgrade"
    Copy-Item $source $configFileToUpgrade
    
}

function StopMongo()
{
    param([string]$serviceName)

    Write-Host "Stopping service $serviceName"

    if(Get-Service $serviceName | Where { $_.Status -eq "Running" })
    {
        Stop-Service $serviceName -ErrorAction Stop
    }
}

function StartMongo
{
    param([string]$serviceName)

    Write-Host "Starting service $serviceName" -ErrorAction Stop
    Start-Service $serviceName        
}

function InstallMsi
{
    param([string] $msiPath, $installDir)

    Write-Host "Installing Mongo"
        
    $fullMsiPath = Resolve-Path $msiPath
    $fullInstallLocation = Resolve-Path $installDir
    $arguments = "/qr /i `"$fullMsiPath`" INSTALLLOCATION=`"$fullInstallLocation`" ADDLOCAL=`"all`""
    $process = Start-Process msiexec.exe $arguments -Wait -PassThru

    return $process.ExitCode -eq 0        
}

if(-Not ((Test-Path $mongoUpgradeMsi) -and ([System.IO.Path]::GetExtension($mongoUpgradeMsi) -eq ".msi")))
{
    Write-Error "$mongoUpgradeMsi isn't an MSI file or the file does not exist"
    return
}

if(!(Join-Path $mongoDirectory "bin\mongod.exe" | Test-Path))
{
    Write-Error "$mongoDirectory doesn't contain a bin directory with mongo binaries please check the supplied value is correct"
    return
}

StopMongo $mongoServiceName

if(InstallMsi $mongoUpgradeMsi $mongoDirectory)
{
    ReplaceConfiguration $configFileSource $configFileToUpgrade
    StartMongo $mongoServiceName
    Write-Warning "Mongo upgraded and service started, please verify everything is ok!"
}