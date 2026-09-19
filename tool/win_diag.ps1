Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WinDiag {
  [DllImport("user32.dll")] public static extern IntPtr WindowFromPoint(POINT p);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, System.Text.StringBuilder sb, int max);
  [DllImport("user32.dll")] public static extern bool GetCursorPos(out POINT p);
  [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
}
"@
$p = New-Object WinDiag+POINT
[WinDiag]::GetCursorPos([ref]$p) | Out-Null
$under = [WinDiag]::WindowFromPoint($p)
$fg = [WinDiag]::GetForegroundWindow()
$sb1 = New-Object System.Text.StringBuilder 256
[WinDiag]::GetWindowTextW($under, $sb1, 256) | Out-Null
$sb2 = New-Object System.Text.StringBuilder 256
[WinDiag]::GetWindowTextW($fg, $sb2, 256) | Out-Null
Write-Output "cursor=($($p.X),$($p.Y)) under='$($sb1.ToString())' foreground='$($sb2.ToString())'"
