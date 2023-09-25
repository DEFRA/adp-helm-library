<#
.SYNOPSIS
Publish Helm library chart to github repo 'Defra/adp-helm-repository'.

.DESCRIPTION
Package Helm library chart.
Publish Helm library chart to github repo 'Defra/adp-helm-repository' and updates index.yaml file in that repo.

.PARAMETER HelmLibraryPath
Helm library folder root path. requires to package helm library into .tgz package.

.PARAMETER ChartVersion
Current Helm library ChartVersion.

.PARAMETER HelmChartRepoPublic
Helm chart publich url. Requires to index.yaml file.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] 
    [string]$HelmLibraryPath,
    [Parameter(Mandatory)] 
    [string]$ChartVersion,
    [Parameter(Mandatory)] 
    [string]$HelmChartRepoPublic
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
Write-Debug "${functionName}:ChartVersion=$ChartVersion"
Write-Debug "${functionName}:HelmChartRepoPublic=$HelmChartRepoPublic"

try {
    Write-Host "Package Helm library chart"
    helm package $HelmLibraryPath 

    $packageName = Split-Path $HelmLibraryPath -Leaf
    $packageNameWithVersion = "$packageName-$ChartVersion.tgz"

    Move-Item -Path $packageNameWithVersion -Destination ../ADPHelmRepository

    Write-Host "Set-Location to ADPHelmRepository"
    Set-Location ../ADPHelmRepository

    helm repo index . --url $HelmChartRepoPublic

    Write-Host "Configure git credentials"
    git config user.email "ado@noemail.com"
    git config user.name "Devops"

    Write-Host "git push package to adp-helm-repository"
    git checkout -b main
    git add $packageNameWithVersion
    git commit -am "Add new version $ChartVersion" --author="ADO Devops <ado@noemail.com>"
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