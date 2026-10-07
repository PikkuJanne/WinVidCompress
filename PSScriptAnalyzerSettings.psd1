@{
    IncludeDefaultRules = $true
    Severity = @('Error')
    # Whole-tree error gate. test-static.ps1 adds selected safety rules on changed files.
    # Existing warning/style debt does not require an application formatting rewrite.
}
