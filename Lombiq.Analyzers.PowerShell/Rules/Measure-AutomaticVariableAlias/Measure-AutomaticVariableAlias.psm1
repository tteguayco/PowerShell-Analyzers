<#
.SYNOPSIS
    Replaces usages of the alias of the automatic variable ($_) with its original form ($PSItem).
.DESCRIPTION
    Replaces usages of the alias of the automatic variable ($_) with its original form ($PSItem), similarly to the
    AvoidUsingCmdletAliases rule.
.EXAMPLE
    Measure-AutomaticVariableAlias -Token $Token
.INPUTS
    [System.Management.Automation.Language.Token[]]
.OUTPUTS
    [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
.NOTES
    Copied from
    https://github.com/PowerShell/PSScriptAnalyzer/blob/master/Tests/Engine/CommunityAnalyzerRules/CommunityAnalyzerRules.psm1#L613.
#>
function Measure-AutomaticVariableAlias
{
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.Token[]]
        $Token
    )

    Process
    {
        $results = @()

        try
        {
            # Finds the usages of the alias ($_) of the automatic variable ($PSItem).
            $lcTokens = $Token | Where-Object { $PSItem.GetType().Name -eq "VariableToken" -and $PSItem.Name -eq "_" }

            foreach ($lcToken in $lcTokens)
            {
                $correctionTypeName = "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent"
                $correctionExtent = New-Object -TypeName $correctionTypeName -ArgumentList @(
                    $lcToken.Extent.StartLineNumber
                    $lcToken.Extent.EndLineNumber
                    $lcToken.Extent.StartColumnNumber
                    $lcToken.Extent.EndColumnNumber
                    "`$PSItem"
                    "Replaced the alias of the automatic variable (`$_) with `"`$PSItem`"."
                )

                $suggestedCorrections = New-Object System.Collections.ObjectModel.Collection[$correctionTypeName]
                $suggestedCorrections.add($correctionExtent) | Out-Null

                $results += [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                    "Message"              = "Use the full name of the automatic variable (`$PSItem) instead of `"`$_`"!"
                    "Extent"               = $lcToken.Extent
                    "RuleName"             = $PSCmdlet.MyInvocation.InvocationName
                    "Severity"             = "Warning"
                    "RuleSuppressionID"    = "PSAvoidAutomaticVariableAlias"
                    "SuggestedCorrections" = $suggestedCorrections
                }
            }

            return $results
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}
