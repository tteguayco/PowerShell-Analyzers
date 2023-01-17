function Violate-Analyzers()
{
    Write-Host 'This file contains intentionally bad code to verify that PSScriptAnalyzer works correctly.'
}

try { Violate-Analyzers } catch { }

"Lombiq", `
'Orchard', 'Hastlayer' | % { $_ }
