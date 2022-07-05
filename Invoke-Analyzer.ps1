[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    "PSReviewUnusedParameter",
    "ForGitHubActions",
    Justification = "False positive (see https://github.com/PowerShell/PSScriptAnalyzer/issues/1472).")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "ForMsBuild", Justification = "Same.")]
param(
    $SettingsPath = (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'PSScriptAnalyzerSettings.psd1'),
    [Switch] $ForGitHubActions,
    [Switch] $ForMsBuild
)

# This is like Get-ChildItem -Recurse -Include $IncludeFile | ? { $_.FullName -notlike "*\$ExcludeDirectory\*" } but
# much faster. For example this is relevant for ignoring node_modules.
# - Measure-Command { Find-Recursively -Path . -IncludeFile *.ps1 -ExcludeDirectory node_modules } => 3.83s
# - Measure-Command { Get-ChildItem -Recurse -Include $IncludeFile | ? { $_.FullName -notlike "*\$ExcludeDirectory\*" } } => 111.27s
function Find-Recursively([string] $Path = '.', [string] $IncludeFile, [string] $ExcludeDirectory)
{
    $ExcludeDirectory = $ExcludeDirectory.ToUpperInvariant()

    function Find-Inner([System.IO.DirectoryInfo] $Here)
    {
        if ($Here.Name -like $ExcludeDirectory)
        {
            return
        }

        Get-ChildItem $Here |
            % {
                if ($_ -is [System.IO.DirectoryInfo]) { Find-Inner $_ }
                elseif ($_.Name -like $IncludeFile) { $_ }
            }
    }

    Find-Inner (Get-Item .)
}

$outputCache = New-Object "System.Text.StringBuilder"

function Write-FileError([string] $Message, [string] $Path, [int] $Line = 0, [int] $Column = 0)
{
    if ($Path) { $Path = Get-ChildItem $Path }

    if ($ForGitHubActions)
    {
        $Message = $Message -replace '\s*(\r?\n\s*)+', ' '
        $outputCache.AppendLine(
            "::error$(if ($Path) { " file=$Path,line=$Line,col=$Column::$Message" } else { "::$Message" })")
    }
    elseif ($ForMsBuild)
    {
        if (-not $Message.Contains(":")) { $Message = ": $Message" }

        echo "IS FILE:  $(-not -not $Path)"

        if ($Path)
        {
            [Console]::Error.WriteLine("$Path($Line,$Column): error $Message")
        }
        else
        {
            [Console]::Error.WriteLine(": error $Message")
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
    Write-Output $outputCache.ToString()
    exit -1
}

$results = Find-Recursively -IncludeFile *.ps1 -ExcludeDirectory node_modules |
    % { Invoke-ScriptAnalyzer $_ -Settings $SettingsPath.FullName }

foreach ($result in $results)
{
    Write-Output "item of total $($results.Count)"
    $message = $result.RuleName + ": " + $result.Message
    Write-FileError -Path $result.ScriptPath -Line $result.Line -Column $result.Column $message
}

Write-Output "Do we even reach this point?"

# Printing out all the errors at once on GH, becuase otherwise it will stop after the first one in Linux.
Write-Output $outputCache.ToString()
exit $results.Count
