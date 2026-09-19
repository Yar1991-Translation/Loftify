param(
  [int]$X = 100,
  [int]$Y = 100,
  [Parameter(Mandatory=$true)][int]$Width,
  [Parameter(Mandatory=$true)][int]$Height
)
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class WinResize {
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr a, int x, int y, int cx, int cy, uint f);
}
"@
$h = (Get-Process Loftify | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1).MainWindowHandle
if (-not $h) { Write-Error "no window"; exit 1 }
[WinResize]::SetWindowPos($h, [IntPtr]::Zero, $X, $Y, $Width, $Height, 0x0040) | Out-Null
Write-Output "resized to ${Width}x${Height}"
