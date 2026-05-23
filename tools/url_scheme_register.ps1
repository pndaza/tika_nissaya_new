$exe = "C:\Projects\tika_nissaya_new\build\windows\arm64\runner\Debug\tika_nissaya_new.exe"
$scheme = "tikanissaya"

Write-Host "Registering $scheme:// URL scheme..." -ForegroundColor Green
reg add "HKCU\Software\Classes\$scheme" /v "URL Protocol" /d "" /f
reg add "HKCU\Software\Classes\$scheme\shell\open\command" /ve /d "`"$exe`" `"%1`"" /f
Write-Host "Done. Test with: $scheme://mm.pndaza.tikanissaya/open?id=tika_di_01_02&page=42" -ForegroundColor Green
