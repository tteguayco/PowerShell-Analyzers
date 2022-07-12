using CliWrap;
using CliWrap.Buffered;
using Lombiq.HelpfulLibraries.Cli.Helpers;
using Shouldly;
using System;
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
            @"The command [^\n]+Invoke-Analyzer.ps1 -ForMsBuild -IncludeTestSolutions[^\n]+exited with code 4\.",
            "The Invoke-Analyzer script's exit code should've been 4 because that's the number of expected violations.");

        MessageShouldContainViolationCodes(exception.Message);
    }

    private static async Task<bool> IsPowerShellCoreInstalledAsync()
    {
        try
        {
            await _powerShell.WithArguments("-?").ExecuteBufferedAsync();
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
