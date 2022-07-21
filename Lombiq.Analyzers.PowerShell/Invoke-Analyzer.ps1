param(
    $SettingsPath = (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'PSScriptAnalyzerSettings.psd1'),
    [Switch] $ForGitHubActions,
    [Switch] $ForMsBuild,
    [Switch] $IncludeTestSolutions
)

# This is like Get-ChildItem -Recurse -Include $IncludeFile | ? { $_.FullName -notlike "*\$ExcludeDirectory\*" } but
# much faster. For example, this is relevant for ignoring node_modules.
# - Measure-Command { Find-Recursively -Path . -IncludeFile *.ps1 -ExcludeDirectory node_modules } => 3.83s
# - Measure-Command { Get-ChildItem -Recurse -Force -Include $IncludeFile | ? { $_.FullName -notlike "*\$ExcludeDirectory\*" } } => 111.27s
function Find-Recursively([string] $Path = '.', [string[]] $IncludeFile, [string] $ExcludeDirectory)
{
    $ExcludeDirectory = $ExcludeDirectory.ToUpperInvariant()

    function Find-Inner([System.IO.DirectoryInfo] $Here)
    {
        if ($Here.Name -like $ExcludeDirectory)
        {
            return
        }

        # The -Force switch is necessary to show hidden results, especially on Linux where entries starting with dot
        # are hidden by default.
        foreach ($child in (Get-ChildItem $Here.FullName -Force))
        {
            if ($child -is [System.IO.DirectoryInfo]) { Find-Inner $child }
            elseif (($IncludeFile | ? { $child.name -like $_ }).Count) { $child }
        }
    }

    Find-Inner (Get-Item .)
}

function Write-FileError([string] $Message, [string] $Path, [int] $Line = 0, [int] $Column = 0)
{
    if ($Path) { $Path = Get-Item $Path }

    if ($ForGitHubActions)
    {
        $Message = $Message -replace '\s*(\r?\n\s*)+', ' '
        Write-Output "::error$(if ($Path) { " file=$Path,line=$Line,col=$Column::$Message" } else { "::$Message" })"
    }
    elseif ($ForMsBuild)
    {
        if (-not $Message.Contains(":")) { $Message = ": $Message" }

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
    $SettingsPath = Get-Item $SettingsPath
}
else
{
    Write-FileError "The settings file `"$SettingsPath`" does not exist."
    exit -1
}

$installVersion = "1.20.0"
if ((Get-InstalledModule PSScriptAnalyzer -ErrorAction SilentlyContinue).Version -ne [Version]$installVersion)
{
    try
    {
        # Attempt to install it automatically. This will fail on Windows PowerShell because you have to be admin.
        Install-Module -Name PSScriptAnalyzer -Force -RequiredVersion $installVersion
    }
    catch
    {
        $infoUrl = "https://docs.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/overview?view=ps-modules#installing-psscriptanalyzer"
        Write-FileError ("Unable to detect Invoke-ScriptAnalyzer and failed to install PSScriptAnalyzer. If you " +
            "are on Windows Powershell, open an administrator shell and type `"Install-Module -Name " +
            "PSScriptAnalyzer -Force -RequiredVersion $installVersion`". Otherwise see $infoUrl to learn more.")
        exit -2
    }
}

$results = Find-Recursively -IncludeFile "*.ps1", "*.psm1", "*.psd1" -ExcludeDirectory node_modules |
    ? { # Exclude /TestSolutions/Violate-Analyzers.ps1 and /TestSolutions/*/Violate-Analyzers.ps1
        $IncludeTestSolutions -or -not (
            $_.Name -eq 'Violate-Analyzers.ps1' -and
            ($_.Directory.Name -eq 'TestSolutions' -or $_.Directory.Parent.Name -eq 'TestSolutions')) } |
    % { Invoke-ScriptAnalyzer $_.FullName -Settings $SettingsPath.FullName } |
    # Only Warning and above (ignore "Information" type results).
    ? { $_.Severity -ge [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticSeverity]::Warning }

foreach ($result in $results)
{
    $message = $result.RuleName + ": " + $result.Message
    Write-FileError -Path $result.ScriptPath -Line $result.Line -Column $result.Column $message
}

exit $results.Count
