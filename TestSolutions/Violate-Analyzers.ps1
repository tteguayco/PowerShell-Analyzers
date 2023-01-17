function Violate-Analyzers()
{
    Write-Host 'This file is intended to verify that PSScriptAnalyzer works and contains intentionally bad code.'
}

try { Violate-Analyzers } catch { }

"Lombiq", `
'Orchard', 'Hastlayer' | % { $_ }
