# remove_comments.ps1
# This script recursively removes single-line (//) and multi-line (/* */) comments 
# from all .dart files in the current directory and subdirectories.

$files = Get-ChildItem -Recurse -Filter *.dart

foreach ($file in $files) {
    Write-Host "Cleaning comments from: $($file.FullName)"
    
    $content = Get-Content -Raw $file.FullName
    
    # 1. Remove multi-line comments: /* ... */
    # Options: Singleline (s) allows . to match newlines
    $noMulti = $content -replace '(?s)/\*.*?\*/', ''
    
    # 2. Remove single-line comments: // ... (excluding those inside strings is hard with pure regex, 
    # but this is a common approach for simple cleanup)
    $noSingle = $noMulti -replace '//.*', ''
    
    # 3. Trim trailing whitespace on lines and remove excess empty lines
    $cleaned = $noSingle -split "`r?`n" | ForEach-Object { $_.TrimEnd() } | Where-Object { $_.Trim() -ne "" }
    
    Set-Content -Path $file.FullName -Value $cleaned
}

Write-Host "Done! All .dart files have been cleaned."
