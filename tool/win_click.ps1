param(
  [Parameter(Mandatory=$true)][double]$X,
  [Parameter(Mandatory=$true)][double]$Y,
  [switch]$Rect
)
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32Click {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr hWnd, out RECT rect);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint dwData, UIntPtr dwExtraInfo);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindowW(string lpClassName, string lpWindowName);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
  public const uint LEFTDOWN = 0x0002; public const uint LEFTUP = 0x0004;
}
"@
$hwnd = (Get-Process Loftify -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1).MainWindowHandle
if (-not $hwnd -or $hwnd -eq 0) { Write-Error "Loftify window not found"; exit 1 }
if ($Rect) {
  $wr = New-Object Win32Click+RECT
  [Win32Click]::GetWindowRect($hwnd, [ref]$wr) | Out-Null
  $cr = New-Object Win32Click+RECT
  [Win32Click]::GetClientRect($hwnd, [ref]$cr) | Out-Null
  Write-Output "win=$($wr.Left),$($wr.Top),$($wr.Right),$($wr.Bottom) client=$($cr.Right - $cr.Left)x$($cr.Bottom - $cr.Top)"
  exit 0
}
[Win32Click]::SetForegroundWindow($hwnd) | Out-Null
Start-Sleep -Milliseconds 300
$wrect = New-Object Win32Click+RECT
[Win32Click]::GetWindowRect($hwnd, [ref]$wrect) | Out-Null
$absX = $wrect.Left + $X
$absY = $wrect.Top + $Y
[Win32Click]::SetCursorPos([int]$absX, [int]$absY) | Out-Null
Start-Sleep -Milliseconds 120
[Win32Click]::mouse_event([Win32Click]::LEFTDOWN, 0, 0, 0, [UIntPtr]::Zero)
Start-Sleep -Milliseconds 60
[Win32Click]::mouse_event([Win32Click]::LEFTUP, 0, 0, 0, [UIntPtr]::Zero)
Write-Output "clicked $X,$Y (abs $absX,$absY)"
