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

    Write-Host "PWD is = " (Get-Location).Path #D:\a\1\s 
     
    Write-Host "Package Helm library chart"
    helm package $HelmLibraryPath 

    $currentVersion = "4.0.1"
    $packageName = Split-Path $HelmLibraryPath -Leaf
    $packageNameWithVersion = "$packageName-$currentVersion.tgz"

    Move-Item -Path $packageNameWithVersion -Destination ../ADPHelmRepository

    Write-Host "Set-Location to ADPHelmRepository"
    Set-Location ../ADPHelmRepository

    Write-Host "List all files Get-ChildItem in ADPHelmRepository and confirm .tgz file"
    Get-ChildItem 

    git config user.email "ganesh.b.ghadge@capgemini.com"
    git config user.name "Devops"

    git checkout -b main
    git add $packageNameWithVersion
    git commit -am "Add new version $currentVersion" --author="ADO Devops <ado@noemail.com>"
    # git push --set-upstream origin main 
    $aa = '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'
    git push "https://$aa@github.com/defra-adp-sandpit/adp-helm-repository.git"

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