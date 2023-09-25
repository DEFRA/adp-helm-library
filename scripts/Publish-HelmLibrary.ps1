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
    Write-Host "Package Helm library chart"
    helm package $HelmLibraryPath 

    $currentVersion = "4.0.3"
    $packageName = Split-Path $HelmLibraryPath -Leaf
    $packageNameWithVersion = "$packageName-$currentVersion.tgz"

    Move-Item -Path $packageNameWithVersion -Destination ../ADPHelmRepository

    Write-Host "Set-Location to ADPHelmRepository"
    Set-Location ../ADPHelmRepository

    git config user.email "ado@noemail.com"
    git config user.name "Devops"

    Write-Host "git push package to adp-helm-repository"
    git checkout -b main
    git add $packageNameWithVersion
    git commit -am "Add new version $currentVersion" --author="ADO Devops <ado@noemail.com>"
    git push --set-upstream origin main

    $exitCode = 0
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