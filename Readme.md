# Lombiq PowerShell Analyzers

[![Lombiq.Analyzers.PowerShell NuGet](https://img.shields.io/nuget/v/Lombiq.Analyzers.PowerShell?label=Lombiq.Analyzers.PowerShell)](https://www.nuget.org/packages/Lombiq.Analyzers.PowerShell/)

## About

PowerShell static code analysis via [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) and [Lombiq's recommended configuration for it](Lombiq.Analyzers.PowerShell/PSScriptAnalyzerSettings.psd1). Use it from the CLI, in GitHub Actions, or integrated into MSBuild builds.

Looking for .NET static code analysis? Check out our [.NET Analyzers project](https://github.com/Lombiq/.NET-Analyzers).

Do you want to quickly try out this project and see it in action? Check it out in our [Open-Source Orchard Core Extensions](https://github.com/Lombiq/Open-Source-Orchard-Core-Extensions) full Orchard Core solution and also see our other useful Orchard Core-related open-source projects!

## Documentation

### Pre-requisites

The *PSScriptAnalyzer* module must be installed. The script will attempt to auto-install it, however if this fails (e.g. on Windows PowerShell you have to be admin to install modules) follow the steps [here](https://docs.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/overview?view=ps-modules#installing-psscriptanalyzer).

Note that if you are usnig this in GitHub Actions, the common images (`windows-latest` and `ubuntu-latest`) already have it so you don't need to install anything.

### Usage

#### PowerShell CLI

Use the script like this to output the analyzer violations with `Write-Error`:

```pwsh
./Invoke-Analyzer.ps1 -SettingsPath PSScriptAnalyzerSettings.psd1
```

The `-SettingsPath` can be omitted, in this case the *PSScriptAnalyzerSettings.psd1* in the same directory as the *Invoke-Analyzer.ps1* will be used.

#### GitHub Actions

You can invoke it from an *action.yml* file like this:

```yaml
    - name: Analyze PowerShell scripts
      shell: pwsh
      run: ${{ github.action_path }}/Invoke-Analyzer.ps1 -ForGitHubAction
```

The `-ForGitHubAction` optional displays the results using [error workflow commands](https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#setting-an-error-message). These create file annotations pointing to the exact script path and line number provided by PSScriptAnalyzer. You can review the results in the workflow summary page. If the violating files aren't in a submodule then they will be marked in the related pull request's Files tab as well.

If you are using our `build-dotnet` action or build-related reusable workflows from [Lombiq GitHub Actions](https://github.com/Lombiq/GitHub-Actions), PowerShell linting is already included.

Just set the value of the `powershell-analyzer-path` to the path of the *Invoke-Analyzer.ps1* file relative to your repository root. In case it's *./tools/Lombiq.Analyzers.PowerShell/Invoke-Analyzer.ps1* you don't need additional configuration.

#### MSBuild

This way you associate the analyzer with a .NET project and MSBuild automatically invokes analysis before building. If the analysis passes, it creates a timestamp and won't perform the analysis again until a new script file has been added or an existing one modified.

If this project is included via a submodule, edit the *csproj* file of your primary project(s) and add the following:

```xml
<Import Project="path\to\Lombiq.Analyzers.PowerShell\Lombiq.Analyzers.PowerShell.targets" />
```

You don't need to `<ProjectReference>` *Lombiq.Analyzers.PowerShell.csproj*.

If you include the project as a NuGet package, it will work as-is.

Additionally, you can set these properties in the importing project's `<PropertyGroup>`:

- `<PowerShellAnalyzersRootDirectory>`: The analysis root directory, only files recursively found here are checked. If not specified, it uses the solution directory if present (if you are building the whole solution), otherwise the project directory (if you are building just the project).
- `<PowerShellAnalyzersArguments>`: Set it to customize the arguments passed to the script. This is useful if you want to provide your own rules configuration by setting it to `-ForMsBuild -SettingsPath path/to/settings.psd1`. If not specified, its value is `-ForMsBuild` unless a GitHub Actions environment is detected (via the `$GITHUB_ENV` variable) in which case the default value is `-ForGitHubAction`.

#### Visual Studio Code

Live analysis is outside of the scope of this project, however you can use the Visual Studio Code extension:

1. Install it from the [Marketplace](https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell).
2. Go to Settings and paste `powershell.scriptAnalysis.settingsPath` into the search bar.
3. Set it to the path of the *PSScriptAnalyzerSettings.psd1* file to use our settings.

### Suppressing PSScriptAnalyzer rules

Occasionally there is good reason to ignore an analyzer warning. In this case add the `[Diagnostics.CodeAnalysis.SuppressMessage('Rule Code', '', Justification = 'Explain reason.')]` attribute to the cmdlet's `param()`. For more information, see the module's [documentation](https://docs.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer?view=ps-modules#suppressing-rules).

Suppressing a specific line or range (like `#pragma warning disable` in C#) is not currently supported. See [the associated PSScriptAnalyzer issue](https://github.com/PowerShell/PSScriptAnalyzer/issues/849).

## Contributing and support

Bug reports, feature requests, comments, questions, code contributions and love letters are warmly welcome. Please do so via GitHub issues and pull requests. Please adhere to our [open-source guidelines](https://lombiq.com/open-source-guidelines) while doing so.

This project is developed by [Lombiq Technologies](https://lombiq.com/). Commercial-grade support is available through Lombiq.
