# Lombiq PowerShell Analyzers



## About

Powershell static code analysis via [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) and [our configuration for it](PSScriptAnalyzerSettings.psd1).

Do you want to quickly try out this project and see it in action? Check it out in our [Open-Source Orchard Core Extensions](https://github.com/Lombiq/Open-Source-Orchard-Core-Extensions) full Orchard Core solution and also see our other useful Orchard Core-related open-source projects!


## Documentation

### Pre-requisites

The PSScriptAnalyzer module must be installed. Follow the steps [here](https://docs.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/overview?view=ps-modules#installing-psscriptanalyzer). Note that if you are usnig this in GitHub Actions, the common images (`windows-latest` and `ubuntu-latest`) already have it so you don't need to do anything.

### Usage

Use the script like this:

```pwsh
./Invoke-Analyzer.ps1 -SettingsPath PSScriptAnalyzerSettings.psd1
```

The `-SettingsPath` can be omitted, in this case the _PSScriptAnalyzerSettings.psd1_ in the same directory as the _Invoke-Analyzer.ps1_ will be used.

You can invoke it from a GitHub action file like this:
```yaml
    - name: Lint PowerShell scripts
      shell: pwsh
      run: ${{ github.action_path }}/Invoke-Analyzer.ps1 -ForGitHubAction
```

The `-ForGitHubAction` optional switch replaces the normal `Write-Error` messages with [error workflow commands](https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#setting-an-error-message). These create file annotations pointing to the exact script path and line number provided by PSScriptAnalyzer. You can review the results in the workflow summary and in the pull request's Files tab.


## Contributing and support

Bug reports, feature requests, comments, questions, code contributions, and love letters are warmly welcome, please do so via GitHub issues and pull requests. Please adhere to our [open-source guidelines](https://lombiq.com/open-source-guidelines) while doing so.

This project is developed by [Lombiq Technologies](https://lombiq.com/). Commercial-grade support is available through Lombiq.
