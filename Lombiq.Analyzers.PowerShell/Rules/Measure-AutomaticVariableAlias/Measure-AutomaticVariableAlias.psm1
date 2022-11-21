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
    Copied (and modified version of)
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
            # Filter down tokens to just variable tokens with the name "_".
            foreach ($automaticVariableAliasToken in $Token | Where-Object { $PSItem.GetType().Name -eq "VariableToken" -and $PSItem.Name -eq "_" })
            {
                $correctionTypeName = "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent"
                $correctionExtent = New-Object -TypeName $correctionTypeName -ArgumentList @(
                    $automaticVariableAliasToken.Extent.StartLineNumber
                    $automaticVariableAliasToken.Extent.EndLineNumber
                    $automaticVariableAliasToken.Extent.StartColumnNumber
                    $automaticVariableAliasToken.Extent.EndColumnNumber
                    "`$PSItem"
                    "Replaced the alias of the automatic variable '`$_' with '`$PSItem'."
                )

                $suggestedCorrections = New-Object System.Collections.ObjectModel.Collection[$correctionTypeName]
                $suggestedCorrections.add($correctionExtent) | Out-Null

                $results += [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                    "Extent"               = $automaticVariableAliasToken.Extent
                    "Message"              = "'`$_' is an alias of '`$PSItem'."
                    "RuleName"             = "PSAvoidUsingAutomaticVariableAlias"
                    "RuleSuppressionID"    = "PSAvoidUsingAutomaticVariableAlias"
                    "Severity"             = "Warning"
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
