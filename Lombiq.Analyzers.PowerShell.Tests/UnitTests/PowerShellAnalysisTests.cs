using CliWrap;
using CliWrap.Buffered;
using Lombiq.HelpfulLibraries.Cli.Helpers;
using Shouldly;
using System;
using System.Diagnostics.CodeAnalysis;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Xunit;

namespace Lombiq.Analyzers.PowerShell.Tests.UnitTests;

[SuppressMessage("Usage", "xUnit1004:Test methods should not be skipped", Justification = "Temporary.")]
public class PowerShellAnalysisTests
{
    private static readonly Command _powerShell = Cli.Wrap("pwsh");

    private static readonly DirectoryInfo _testSolutions = new(Path.Combine("..", "..", "..", "..", "TestSolutions"));

    [Fact(Skip = "Performance evaluation")]
    public async Task DirectScriptInvocationShouldDisplayWarnings()
    {
        if (!await IsPsScriptAnalyzerInstalledAsync()) return;

        var result = await _powerShell
            .WithWorkingDirectory(Path.GetFullPath(_testSolutions.FullName))
            .WithArguments(new[] { "-c", "../Lombiq.Analyzers.PowerShell/Invoke-Analyzer.ps1 -IncludeTestSolutions" })
            .WithValidation(CommandResultValidation.None)
            .ExecuteBufferedAsync();

        result.ExitCode.ShouldNotBe(0);
        MessageShouldContainViolationCodes(result.StandardError);
    }

    [Theory(Skip = "Performance evaluation")]
    [InlineData("Lombiq.Analyzers.PowerShell.PackageReference")]
    [InlineData("Lombiq.Analyzers.PowerShell.ProjectReference")]
    public async Task BuildShouldDisplayWarnings(string directory)
    {
        if (!await IsPsScriptAnalyzerInstalledAsync()) return;

        var solutionDirectory = _testSolutions.GetDirectories(directory).Single().Name;
        var solutionPath = Path.Combine("..", "..", "..", "..", "TestSolutions", solutionDirectory, solutionDirectory + ".sln");

        var exception = (InvalidOperationException)await Should.ThrowAsync(
            () => DotnetBuildHelper.ExecuteStaticCodeAnalysisAsync(solutionPath),
            typeof(InvalidOperationException));

        exception.Message.ShouldMatch(
            @"The command [^\n]+Invoke-Analyzer.ps1 -ForMsBuild -IncludeTestSolutions[^\n]+exited with code 4\.",
            "The Invoke-Analyzer script's exit code should've been 4 because that's the number of expected violations.");

        MessageShouldContainViolationCodes(exception.Message);
    }

    // Ideally this method should skip the test programmatically instead of returning a value. Once XUnit 2.4.2-pre.19
    // or newer is available, we will have Assert.Skip(skipMessage). See commit
    // https://github.com/xunit/assert.xunit/commit/e6a6d5d22bbc7097f8decad5b3c8cac8cf3fb386 for implementation
    // and issue https://github.com/xunit/xunit/issues/2073 for more information.
    private static async Task<bool> IsPsScriptAnalyzerInstalledAsync()
    {
        try
        {
            await _powerShell
                // The test should only run if PSScriptAnalyzer is installed. Even though it can install itself in PS7
                // we should avoid relying on that as it harms testing performance on CI. It should be pre-installed.
                .WithArguments(new[] { "-c", "Invoke-ScriptAnalyzer -ScriptDefinition 'Write-Output 1'" })
                .ExecuteBufferedAsync();
            return true;
        }
        catch
        {
            return false;
        }
    }

    private static void MessageShouldContainViolationCodes(string message)
    {
        message.ShouldContain("PSAvoidUsingEmptyCatchBlock");
        message.ShouldContain("PSAvoidUsingCmdletAliases");
        message.ShouldContain("PSUseApprovedVerbs");
        message.ShouldContain("PSUseSingularNouns");
    }
}
