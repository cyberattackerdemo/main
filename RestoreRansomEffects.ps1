# エラー時も継続
$ErrorActionPreference = "SilentlyContinue"

# ======== 🔄 拡張子を元に戻す処理 ========
$targetFolder = "$env:USERPROFILE\Desktop"
$extensionToRemove = ".locked"

Get-ChildItem -Path $targetFolder -Recurse -Filter "*$extensionToRemove" | ForEach-Object {
    $originalName = $_.FullName -replace [regex]::Escape($extensionToRemove) + "$", ""
    try {
        Rename-Item -Path $_.FullName -NewName $originalName -Force
    } catch {
        Write-Host "ファイルの復元に失敗しました: $($_.FullName)"
    }
}

# ======== 🎨 壁紙をデフォルトに戻す処理 ========
$defaultWallpaperPath = "$env:windir\Web\Wallpaper\Windows\img0.jpg"
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name Wallpaper -Value $defaultWallpaperPath

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class NativeMethods {
  [DllImport("user32.dll", SetLastError = true)]
  public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
[NativeMethods]::SystemParametersInfo(20, 0, $defaultWallpaperPath, 3)

# ======== ✅ 完了メッセージ表示 ========
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show("ファイルと壁紙の復元が完了しました。", "復元完了", 0, 'Information')
