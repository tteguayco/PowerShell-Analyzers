[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    "PSReviewUnusedParameter",
    "ForGitHubActions",
    Justification = "False positive (see https://github.com/PowerShell/PSScriptAnalyzer/issues/1472).")]
param(
    [Parameter(Mandatory = $True)] $SettingsPath,
    [Switch] $ForGitHubActions
)

function Write-FileError([string] $Message, [string] $Path, [int] $Line = 0)
{
    if ($Path) { $Path = Get-ChildItem $Path }

    if ($ForGitHubActions)
    {
        $Message = $Message -replace '\s*(\r?\n\s*)+', ' '
        Write-Output $(if ($Path) { "::error file=$Path,line=$Line::$Message" } else { "::error::$Message" })
    }
    else
    {
        Write-Error $(if ($Path) { "[$Path|ln $Line] $Message" } else { $Message })
    }
}

if (Test-Path $SettingsPath)
{
    $SettingsPath = Get-ChildItem $SettingsPath
}
else
{
    Write-FileError "The settings file `"$SettingsPath`" does not exist."
    exit -1
}

$results = Get-ChildItem -Recurse -Force -Include *.ps1 |
    % { Invoke-ScriptAnalyzer $_ -Settings $SettingsPath.FullName }

foreach ($result in $results)
{
    $message = $result.RuleName + ": " + $result.Message
    Write-FileError -Path $result.ScriptPath -Line $result.Line $message
}

exit $results.Count