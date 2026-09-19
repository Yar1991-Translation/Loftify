param(
  [Parameter(Mandatory=$true)][int]$X,
  [Parameter(Mandatory=$true)][int]$Y
)
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WinMsg {
  [DllImport("user32.dll")] public static extern bool PostMessageW(IntPtr hWnd, uint msg, UIntPtr wParam, IntPtr lParam);
  [DllImport("user32.dll")] public static extern IntPtr ChildWindowFromPoint(IntPtr hWnd, POINT p);
  [DllImport("user32.dll")] public static extern bool ScreenToClient(IntPtr hWnd, ref POINT p);
  [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
}
"@
$parent = (Get-Process Loftify -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1).MainWindowHandle
if (-not $parent) { Write-Error "no window"; exit 1 }
# Client coordinates relative to the top-level window; Flutter's view is a child.
$pt = New-Object WinMsg+POINT
$pt.X = [int]$X; $pt.Y = [int]$Y
$child = [WinMsg]::ChildWindowFromPoint($parent, $pt)
$target = if ($child -ne [IntPtr]::Zero) { $child } else { $parent }
if ($child -ne [IntPtr]::Zero) {
  # Convert to the child's client space.
  $scr = New-Object WinMsg+POINT
  $scr.X = [int]$X; $scr.Y = [int]$Y
  [WinMsg]::ScreenToClient($parent, [ref]$scr) | Out-Null
}
$lparam = [IntPtr](($pt.Y -shl 16) -bor ($pt.X -band 0xFFFF))
$mk = [UIntPtr]::new(1)  # MK_LBUTTON
[WinMsg]::PostMessageW($target, 0x0200, $mk, $lparam) | Out-Null  # WM_MOUSEMOVE
Start-Sleep -Milliseconds 60
[WinMsg]::PostMessageW($target, 0x0201, $mk, $lparam) | Out-Null  # WM_LBUTTONDOWN
Start-Sleep -Milliseconds 90
[WinMsg]::PostMessageW($target, 0x0202, [UIntPtr]::new(0), $lparam) | Out-Null  # WM_LBUTTONUP
Write-Output "posted click to child=$($target) at $X,$Y"
