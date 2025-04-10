@echo off
chcp 437 >nul
echo Detecting local IP address...

:: Get local IPv4 address (English Windows)
for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    set ip=%%A
)
set ip=%ip:~1%
echo Local IP Address: %ip%

:: Test connectivity to the printer
echo.
echo Pinging Ricoh printer at 192.168.0.220...
ping -n 2 192.168.0.220 >nul
if %errorlevel%==0 (
    echo SUCCESS: Printer is reachable!
) else (
    echo ERROR: Cannot reach printer at 192.168.0.220.
)

echo.
@echo off
chcp 437 >nul

echo === Configuring SMB Scan Folder for Ricoh IM 4500 ===

:: Create scan folder
echo Creating folder C:\scan...
mkdir C:\scan 2>nul

:: Grant full access to Everyone
echo Granting folder permission to Everyone...
icacls C:\scan /grant Everyone:(OI)(CI)F

:: Share folder
echo Sharing folder as 'scan'...
net share scan=C:\scan /GRANT:Everyone,FULL

:: Enable SMB 1.0/2.0/3.0
echo Enabling SMB protocols...
dism /online /Enable-Feature /FeatureName:SMB1Protocol /NoRestart >nul 2>&1
dism /online /Enable-Feature /FeatureName:SMB2Protocol /NoRestart >nul 2>&1

:: Start required services
echo Starting Workstation and Server services...
sc config lanmanworkstation start= auto
sc config lanmanserver start= auto
net start workstation >nul 2>&1
net start server >nul 2>&1

:: Enable firewall rules
echo Enabling firewall rules for File and Printer Sharing...
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes

:: Disable Password Protected Sharing
echo Disabling Password Protected Sharing...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LimitBlankPasswordUse /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v restrictnullsessaccess /t REG_DWORD /d 0 /f
net stop server >nul
net start server >nul

echo.
echo === SMB scan folder successfully configured at C:\scan ===
pause

echo Disabling Windows Defender Firewall (Private and Public)...
netsh advfirewall set privateprofile state off
netsh advfirewall set publicprofile state off

echo Opening printer page in your default browser...
start http://192.168.0.220

:: Build the shared folder path using computer name
SET share=\\%COMPUTERNAME%\scan

:: Copy to clipboard
echo %share% | clip

echo.
echo ===============================
echo The shared folder path %share% has been copied to the clipboard!
echo You can now paste it into the scanner settings on the printer.
echo ===============================
pause