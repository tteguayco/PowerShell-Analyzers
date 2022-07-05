using CliWrap;
using CliWrap.Buffered;
using Shouldly;
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
        result.StandardError.ShouldContain("PSAvoidUsingEmptyCatchBlock");
        result.StandardError.ShouldContain("PSAvoidUsingCmdletAliases");
        result.StandardError.ShouldContain("PSUseApprovedVerbs");
        result.StandardError.ShouldContain("PSUseSingularNouns");
    }

    [Theory]
    public async Task BuildWithPackageReferenceShouldDisplayWarnings(string directory)
    {
        if (!await IsPowerShellCoreInstalledAsync()) return;

        var result = await _powerShell
            .WithWorkingDirectory(Path.GetFullPath(_testSolutions.GetDirectories(directory).Single().FullName))
            .WithArguments(new[] { "-c", "../Lombiq.Analyzers.PowerShell/Invoke-Analyzer.ps1 -IncludeTestSolutions" })
            .WithValidation(CommandResultValidation.None)
            .ExecuteBufferedAsync();

        result.ExitCode.ShouldNotBe(0);
        result.StandardError.ShouldContain("PSAvoidUsingEmptyCatchBlock");
        result.StandardError.ShouldContain("PSAvoidUsingCmdletAliases");
        result.StandardError.ShouldContain("PSUseApprovedVerbs");
        result.StandardError.ShouldContain("PSUseSingularNouns");
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
}
