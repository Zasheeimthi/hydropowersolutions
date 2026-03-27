$ErrorActionPreference = "Stop"
$root = "c:\Users\Imthi\OneDrive\Documents\GitHub\hydropowersolutions"
$indexPath = Join-Path $root "index.html"
$indexContent = Get-Content -Path $indexPath -Raw
$footerMatch = [regex]::Match($indexContent, "<!-- Footer area start here -->[\s\S]*?<!-- Footer area end here -->")
if (-not $footerMatch.Success) { throw "Footer block not found" }
$footerBlock = $footerMatch.Value

$cssBlock = @"
<style>
/* Footer Form UI Sync */
#footerMsg {
  margin-top: 16px;
  padding: 12px 16px;
  border-radius: var(--radius);
  font-size: 13px;
  font-weight: 400;
  display: none;
}

#footerMsg.success {
  background: rgba(200,240,100,0.1);
  border: 1px solid rgba(200,240,100,0.25);
  color: #fff;
}

#footerMsg.error {
  background: rgba(255,90,90,0.08);
  border: 1px solid rgba(255,90,90,0.2);
  color: #fff;
}

#footerSubmitBtn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  transform: none;
}

.footer-spinner {
  width: 16px;
  height: 16px;
  border: 2px solid rgba(0,0,0,0.2);
  border-top-color: #000;
  border-radius: 50%;
  animation: spin 0.7s linear infinite;
  display: none;
}

.main-footer .footer-widget.about-widget form {
  width: 100%;
}

.main-footer .footer-widget.about-widget .input-feild {
  position: static;
  display: grid;
  grid-template-columns: 1fr auto;
  gap: 10px;
  align-items: center;
  width: 100%;
}

.main-footer .footer-widget.about-widget .input-feild input {
  width: 100%;
  min-width: 0;
  height: 54px;
  padding: 0 16px;
  border: 1px solid rgba(255, 255, 255, 0.16);
  border-radius: 10px;
  color: #1f2a1f;
  box-sizing: border-box;
}

.main-footer .footer-widget.about-widget .input-feild input::placeholder {
  color: #6e746e;
}

.main-footer .footer-widget.about-widget .input-feild button {
  position: static;
  min-width: 170px;
  width: auto;
  height: 54px;
  line-height: 1;
  padding: 0 20px;
  border-radius: 30px;
  border: 0;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  white-space: nowrap;
}

.main-footer .footer-widget.about-widget .input-feild button .footer-spinner {
  flex: 0 0 auto;
}

@media (max-width: 575.98px) {
  .main-footer .footer-widget.about-widget .input-feild {
    grid-template-columns: 1fr;
  }

  .main-footer .footer-widget.about-widget .input-feild button {
    width: 100%;
    min-width: 0;
  }
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}
</style>
"@

$files = Get-ChildItem -Path $root -Recurse -Filter "*.html" | Where-Object {
  $_.FullName -notmatch "\\(images|fonts|js)\\"
}

$footerCount = 0
$cssCount = 0
$changedCount = 0

foreach ($file in $files) {
  $content = Get-Content -Path $file.FullName -Raw
  $orig = $content

  if ($file.FullName -ne $indexPath) {
    $newContent = [regex]::Replace($content, "<!-- Footer area start here -->[\s\S]*?<!-- Footer area end here -->", [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $footerBlock }, 1)
    if ($newContent -ne $content) { $footerCount++ }
    $content = $newContent
  }

  if ($content -match "<style>\s*/\* Footer Form UI Sync \*/[\s\S]*?</style>") {
    $content = [regex]::Replace($content, "<style>\s*/\* Footer Form UI Sync \*/[\s\S]*?</style>", [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $cssBlock }, 1)
    $cssCount++
  } elseif ($content -match "</head>") {
    $content = $content -replace "</head>", ($cssBlock + "`r`n</head>")
    $cssCount++
  }

  if ($content -ne $orig) {
    Set-Content -Path $file.FullName -Value $content -NoNewline
    $changedCount++
  }
}

Write-Output "Total target files: $($files.Count)"
Write-Output "Footer replaced: $footerCount"
Write-Output "CSS updated/inserted: $cssCount"
Write-Output "Files changed: $changedCount"