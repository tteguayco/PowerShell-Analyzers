@{
    ExcludeRules =
    @(
        # This rule expects us to implement a feature we will be unlikely to use in the majority of cases. Although
        # ShouldProcess support should be implemented in cases where it makes sense.
        'PSUseShouldProcessForStateChangingFunctions'
    )
}
