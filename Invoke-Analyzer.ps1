[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    "PSReviewUnusedParameter",
    "ForGitHubActions;ForMsBuild",
    Justification = "False positive (see https://github.com/PowerShell/PSScriptAnalyzer/issues/1472).")]
param(
    $SettingsPath = (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'PSScriptAnalyzerSettings.psd1'),
    [Switch] $ForGitHubActions,
    [Switch] $ForMsBuild
)

function Write-FileError([string] $Message, [string] $Path, [int] $Line = 0, [int] $Column = 0)
{
    if ($Path) { $Path = Get-ChildItem $Path }

    if ($ForGitHubActions)
    {
        $Message = $Message -replace '\s*(\r?\n\s*)+', ' '
        Write-Output $(if ($Path) { "::error file=$Path,line=$Line,col=$Column::$Message" } else { "::error::$Message" })
    }
    elseif ($ForMsBuild)
    {
        if (-not $Message.Contains(":")) { $Message = ": $Message" }

        echo "IS FILE:  $(-not -not $Path)"

        if ($Path)
        {
            Write-Output ("$Path($Line,$Column): error $Message")
        }
        else
        {
            Write-Output ": error $Message"
        }
    }
    else
    {
        Write-Error $(if ($Path) { "[$Path|ln ${Line}:${Column}] $Message" } else { $Message })
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
    Write-FileError -Path $result.ScriptPath -Line $result.Line -Column $result.Column $message
}

exit $results.Count
