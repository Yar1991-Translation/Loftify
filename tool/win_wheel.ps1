param(
  [Parameter(Mandatory=$true)][double]$X,
  [Parameter(Mandatory=$true)][double]$Y,
  [int]$Delta = -120,
  [int]$Count = 30,
  [int]$IntervalMs = 60
)
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class WinWheel {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint dwFlags, uint dx, uint dy, int dwData, UIntPtr dwExtraInfo);
  public const uint WHEEL = 0x0800;
}
"@
$hwnd = (Get-Process Loftify -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1).MainWindowHandle
if (-not $hwnd) { Write-Error "no window"; exit 1 }
[WinWheel]::SetForegroundWindow($hwnd) | Out-Null
Start-Sleep -Milliseconds 200
$rect = New-Object System.Drawing.Rectangle
Add-Type -AssemblyName System.Drawing
# resolve window origin via GetWindowRect through a variant of the click helper
$origin = & "$PSScriptRoot\win_click.ps1" -X 0 -Y 0 -Rect
$left = 0; $top = 0
if ($origin -match 'win=(-?\d+),(-?\d+)') { $left = [int]$Matches[1]; $top = [int]$Matches[2] }
[WinWheel]::SetCursorPos([int]($left + $X), [int]($top + $Y)) | Out-Null
Start-Sleep -Milliseconds 150
for ($i = 0; $i -lt $Count; $i++) {
  [WinWheel]::mouse_event([WinWheel]::WHEEL, 0, 0, $Delta, [UIntPtr]::Zero)
  Start-Sleep -Milliseconds $IntervalMs
}
Write-Output "wheeled $Count x $Delta at $X,$Y"
