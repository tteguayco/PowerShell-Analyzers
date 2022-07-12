using CliWrap;
using CliWrap.Buffered;
using Lombiq.HelpfulLibraries.Cli.Helpers;
using Shouldly;
using System;
using System.Globalization;
using System.IO;
using System.Linq;
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
        if (!await IsPowerShellCoreInstalledAsync()) return;

        var result = await _powerShell
            .WithWorkingDirectory(Path.GetFullPath(_testSolutions.FullName))
            .WithArguments(new[] { "-c", "../Lombiq.Analyzers.PowerShell/Invoke-Analyzer.ps1 -IncludeTestSolutions" })
            .WithValidation(CommandResultValidation.None)
            .ExecuteBufferedAsync();

        result.ExitCode.ShouldNotBe(0);
        MessageShouldContainViolationCodes(result.StandardError);
    }

    [Theory]
    [InlineData("Lombiq.Analyzers.PowerShell.PackageReference")]
    [InlineData("Lombiq.Analyzers.PowerShell.ProjectReference")]
    public async Task BuildShouldDisplayWarnings(string directory)
    {
        if (!await IsPowerShellCoreInstalledAsync()) return;

        var solutionDirectory = _testSolutions.GetDirectories(directory).Single().Name;
        var solutionPath = Path.Combine("..", "..", "..", "..", "TestSolutions", solutionDirectory, solutionDirectory + ".sln");

        var exception = (InvalidOperationException)await Should.ThrowAsync(
            () => DotnetBuildHelper.ExecuteStaticCodeAnalysisAsync(solutionPath),
            typeof(InvalidOperationException));

        exception.Message.ShouldMatch(
            @"The command [^\n]+pwsh[^\n]+Invoke-Analyzer.ps1 -ForMsBuild -IncludeTestSolutions[^\n]+exited with code 4\.",
            "The Invoke-Analyzer script's exit code should've been 4 because that's the number of expected violations.");

        MessageShouldContainViolationCodes(exception.Message);
    }

    // Ideally this method should skip the test programmatically instead of returning a value. Once XUnit 2.4.2-pre.19
    // or newer is available, we will have Assert.Skip(skipMessage) which does the same thing however it's not up. See
    // commit https://github.com/xunit/assert.xunit/commit/e6a6d5d22bbc7097f8decad5b3c8cac8cf3fb386 for implementation
    // and issue https://github.com/xunit/xunit/issues/2073 for more information.
    private static async Task<bool> IsPowerShellCoreInstalledAsync()
    {
        try
        {
            // In MSBuild Windows Powershell will return 1 for any nonzero exit code, so an alias from powershell to
            // pwsh is not suitable for these tests. We need actual Powershell 7+ for correct diagnostics.
            var result = await _powerShell.WithArguments(new[] { "-c", "$host.Version.Major" }).ExecuteBufferedAsync();
            var output = result.StandardOutput;

            var major = int.Parse(output, NumberStyles.Integer, CultureInfo.InvariantCulture);
            return major >= 7;
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
