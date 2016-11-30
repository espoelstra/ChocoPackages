
#Reread Environment In Case JDK dependency just ran
Update-SessionEnvironment
$url = 'https://jfrog.bintray.com/artifactory-pro/org/artifactory/pro/jfrog-artifactory-pro/4.10.0/jfrog-artifactory-pro-4.10.0.zip'
#$url = 'https://bintray.com/artifact/download/jfrog/artifactory-pro/jfrog-artifactory-pro-4.10.0.zip'
$checksum = '8c9f110c8f0e0bfe2ce3855e4563ea8c7ed380eddebf5fc01e781bbf4409b757'
$checksumtype = 'sha256'
$validExitCodes = @(0)

$packageName= 'artifactory-pro'
$versionedfolder = 'artifactory-pro-4.10.0'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

$OSBits = Get-ProcessorBits

#On 64-bit, always favor 64-bit Program Files no matter what our execution is now (works back past XP / Server 2003)
If ($env:ProgramFiles.contains('x86'))
{
  $PF = $env:ProgramFiles.replace(' (x86)','')
}
Else
{
  $PF = $env:ProgramFiles
}

$packageFolder = 'artifactory'
# Not sure the wisdom of putting an app in a path with spaces
$TargetFolder = "$PF\$packageFolder"
$ExtractFolder = "$env:temp\jfrogtemp"
$servicename = 'artifactory'

If ([bool](Get-Service $servicename -ErrorAction SilentlyContinue))
{
  Write-Warning "Artifactory is already present, shutting it down so that we can upgrade it."
  Stop-Service $servicename -force
  $commandForCmd = "/c `"$TargetFolder\bin\uninstallservice.bat`""
  Start-ChocolateyProcessAsAdmin $commandForCmd cmd -validExitCodes $validExitCodes
}

Install-ChocolateyZipPackage -PackageName $packageName -unziplocation "$ExtractFolder" -url $url -checksum $checksum -checksumtype $checksumtype -url64 $url -checksum64 $checksum -checksumtype64 $checksumtype

Rename-Item "$ExtractFolder\$versionedfolder" "$ExtractFolder\$packageFolder"
Copy-Item "$ExtractFolder\$packageFolder" "$PF" -Force -Recurse
Remove-Item "$ExtractFolder\$packageFolder" -Force -Recurse

#remove the pause from installservice.bat
((Get-Content "$TargetFolder\bin\installservice.bat") -replace '& pause', '') -replace 'pause', ''| Set-Content "$TargetFolder\bin\installservice.bat"

$commandForCmd = "/c `"$TargetFolder\bin\installservice.bat`""
Start-ChocolateyProcessAsAdmin $commandForCmd cmd -validExitCodes $validExitCodes

Install-ChocolateyEnvironmentVariable 'ARTIFACTORY_HOME' "$TargetFolder\bin"

Start-Service $servicename

Write-Warning "`r`n"
Write-Warning "***************************************************************************"
Write-Warning "*  You can manage the repository by visiting http://localhost:8081/artifactory"
Write-Warning "*  The default user is 'admin' with password 'password'"
Write-Warning "*  Artifactory availability is controlled via the service `"$servicename`""
Write-Warning "***************************************************************************"
