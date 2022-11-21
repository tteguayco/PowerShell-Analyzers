function Violate-Analyzers()
{
    "This file is intended made to verify that PSScriptAnalyzer works and contains intentionally bad code."
}

try { Violate-Analyzers } catch { }

Get-ChildItem . | % { $_ }
