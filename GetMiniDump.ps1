<#
.SYNOPSIS
Retrieves last mini dump informations from Act Nexthink action.

.DESCRIPTION
Retrieves last mini dump informations
Tools analyzer should be available in C:\Program Files\Debugging Tools for Windows\ or script should be adapt
BlueScreenWiew from NirSoft http://www.nirsoft.net/utils/blue_screen_view.html
Optionnaly, dumpchk from Microsoft WDK

.FUNCTIONALITY
On demand
Should be run as LocalSystem

.OUTPUTS
MiniDumpsInformation: List of Informations for the last minidump

.LINK
https://github.com/ltaupiac/GetMiniDump

.NOTES
Context: LocalSystem
Version 1.0.0.1
Author Laurent
#>
Add-Type -Path $env:NEXTHINK\RemoteActions\nxtremoteactions.dll

# Adapt this if needed
$DumpFolder = 'c:\Windows\MiniDump\'
$outputAnalysis='C:\Windows\temp\MinidumpAnalysis.txt'
$toolsFolder = 'C:\Program Files\Debugging Tools for Windows\'


$dumpAnalyseCmd = $toolsFolder+'BlueScreenView.exe'
$params = "/LoadFrom 3 /stext $outputAnalysis /SingleDumpFile "

function as_local_system() {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    return $id.User.ToString() -eq "S-1-5-18"
}


try {
    # Check user 
    if (-not $(as_local_system)) {
        throw [System.ApplicationException] "This script must be run as LocalSystem"
    }

    # Check if minidump available
    if(-not(Test-Path -Path $DumpFolder)) {
        throw [System.IO.FileNotFoundException] "No dump available"
    }

    # Check if tool is available
    $dumpFile = Get-ChildItem $DumpFolder -Filter *.dmp | Sort-Object LastWriteTime | select -Last 1 Name
    $params += $DumpFolder + $dumpFile
    if(-not(Test-Path $dumpAnalyseCmd)) {
        throw [System.ApplicationException] "Dump util is not installed"
    }

    # Analyse dump and read result
    Start-Process $dumpAnalyseCmd -ArgumentList $params -Wait
    $text = (Get-Content -path $outputAnalysis) -join "`n"
}
catch {
    $text = "Error:" + $_.Exception.Message 
}
finally {
    # Remove file result generated by tool
    Remove-Item -Path $outputAnalysis -Force -ErrorAction SilentlyContinue
}

[Nxt]::WriteOutputString("MiniDumpsInformation",$text)
