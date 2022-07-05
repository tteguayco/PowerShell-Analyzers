@{
    ExcludeRules =
    @(
        # This rule expects us to implement a feature we will unlikely use in the majority of cases. Although
        # ShouldProcess support should be implemented in cases where it makes sense.
        'PSUseShouldProcessForStateChangingFunctions',
        # This rule causes too many false positives because parameters that are only used in script blocks are
        # considered unused. It should be re-enabled https://github.com/PowerShell/PSScriptAnalyzer/issues/1472 is
        # resolved.
        'PSReviewUnusedParameter'
    )
    'Rules' =
    @{
        'PSAvoidUsingCmdletAliases' =
        @{
            'allowlist' = @('%', '?')
        }
    }
}
