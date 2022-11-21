using CliWrap;
using CliWrap.Buffered;
using Shouldly;
using System.IO;
using System.Threading.Tasks;
using Xunit;

namespace Lombiq.Analyzers.PowerShell.Tests.UnitTests;

public class PowerShellAnalysisTests
{
    private static readonly Command _powerShell = Cli.Wrap("pwsh");

    private static readonly DirectoryInfo _testSolutions = new(Path.Combine("..", "..", "..", "..", "TestSolutions"));

    [Fact]
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
        message.ShouldContain("PSAvoidAutomaticVariableAlias");
        message.ShouldContain("PSAvoidUsingEmptyCatchBlock");
        message.ShouldContain("PSAvoidUsingCmdletAliases");
        message.ShouldContain("PSUseApprovedVerbs");
        message.ShouldContain("PSUseSingularNouns");
    }
}
