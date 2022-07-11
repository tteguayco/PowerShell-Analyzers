function Violate-Analyzers()
{
    "This file is intended made to verify that PSScriptAnalyzer works and contains intentionally bad code."
}

try { echo Violate-Analyzers } catch { }

Get-ChildItem . | % { "This is permitted by our settings file." }
