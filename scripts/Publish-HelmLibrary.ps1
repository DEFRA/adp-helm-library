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

    Write-Host "List all files Get-ChildItem"
    Get-ChildItem

    Write-Host "List all files Get-ChildItem .."
    Get-ChildItem ..
    
    Write-Host "PWD is ="
    Get-Location

    Write-Host "Set-Location is ="
    Set-Location ../ADPHelmRepository

    Write-Host "Get-ChildItem is"
    Get-ChildItem

    # helm package $repoName    

    # git checkout  -b master
    # echo 'This is a test' > data.txt
    # git add -A
    # git commit -m "deployment $(Build.BuildNumber)"
    # git push --set-upstream origin master 

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