@{
    ExcludeRules =
    @(
        'PSDscExamplesPresent',
        'PSDscTestsPresent',
        'PSReturnCorrectTypesForDSCFunctions',
        'PSProvideCommentHelp',
        # This rule expects us to implement a feature we will be unlikely to use in the majority of cases. Although
        # ShouldProcess support should be implemented in cases where it makes sense.
        'PSUseShouldProcessForStateChangingFunctions'
    )
    Rules = @{
        PSAvoidSemicolonsAsLineTerminators = @{
            Enable = $true
        }
        PSAvoidUsingDoubleQuotesForConstantString = @{
            Enable = $true
        }
        PSPlaceCloseBrace = @{
            Enable = $true
            IgnoreOneLineBlock = $true
            NewLineAfter = $true
            NoEmptyLineBefore = $false
        }
        PSPlaceOpenBrace = @{
            Enable = $true
            IgnoreOneLineBlock = $true
            NewLineAfter = $true
            OnSameLine = $false
        }
        PSUseConsistentIndentation = @{
            Enable = $true
            IndentationSize = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            Kind = 'space'
        }
        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckInnerBrace = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator = $true
            CheckPipe = $true
            CheckPipeForRedundantWhitespace = $true
            CheckSeparator = $true
            CheckParameter = $false
            IgnoreAssignmentOperatorInsideHashTable = $false
        }
        # PSUseCorrectCasing is not enabled yet due to https://github.com/PowerShell/PSScriptAnalyzer/issues/1881.
        # PSUseCorrectCasing = @{
        #     Enable = $true
        # }
    }
}
