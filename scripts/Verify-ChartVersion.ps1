[CmdletBinding()]
param(
    [Parameter(Mandatory)] 
    [string]$HelmLibraryPath
)

Set-StrictMode -Version 3.0

[string]$functionName = $MyInvocation.MyCommand
[datetime]$startTime = [datetime]::UtcNow

[int]$exitCode = -1
[bool]$setHostExitCode = (Test-Path -Path ENV:TF_BUILD) -and ($ENV:TF_BUILD -eq "true")
[bool]$enableDebug = (Test-Path -Path ENV:SYSTEM_DEBUG) -and ($ENV:SYSTEM_DEBUG -eq "true")

Set-Variable -Name ErrorActionPreference -Value Continue -scope global
Set-Variable -Name InformationPreference -Value Continue -Scope global

if ($enableDebug) {
    Set-Variable -Name VerbosePreference -Value Continue -Scope global
    Set-Variable -Name DebugPreference -Value Continue -Scope global
}

Write-Host "${functionName} started at $($startTime.ToString('u'))"
Write-Debug "${functionName}:HelmLibraryPath=$HelmLibraryPath"

try {
    
    if (-not (Get-Module -ListAvailable -Name 'powershell-yaml')) {
        Write-Host "powershell-yaml Module does not exists. Installing now.."
        Install-Module powershell-yaml -Force -Scope CurrentUser
        Write-Host "powershell-yaml Installed Successfully."
    } 
    else {
        Write-Host "powershell-yaml Module exist"
    }

    Write-Host "PWD is = " (Get-Location).Path

    [version]$currentVersion = (Get-Content $HelmLibraryPath/Chart.yaml | ConvertFrom-Yaml).version
    Write-Debug "currentVersion: $currentVersion"

    # Fetch origin
    git fetch origin

    [version]$previousVersion = (git show origin/main:adp-helm-library/Chart.yaml | ConvertFrom-Yaml).version
    Write-Debug "previousVersion: $previousVersion"

    if($currentVersion -gt $previousVersion){
        Write-Host "Version increment valid '$previousVersion' -> '$currentVersion'."

        Write-Host "##vso[task.setvariable variable=$ChartCurrentVersion]$currentVersion" 

        $exitCode = 0
    }
    else{
        Write-Error "Version increment invalid '$previousVersion' -> '$currentVersion'."
    }
}
catch {
    $exitCode = -2
    Write-Error $_.Exception.ToString()
    throw $_.Exception
}
finally {
    [DateTime]$endTime = [DateTime]::UtcNow
    [Timespan]$duration = $endTime.Subtract($startTime)

    Write-Host "${functionName} finished at $($endTime.ToString('u')) (duration $($duration -f 'g')) with exit code $exitCode"
    if ($setHostExitCode) {
        Write-Debug "${functionName}:Setting host exit code"
        $host.SetShouldExit($exitCode)
    }
    exit $exitCode
}