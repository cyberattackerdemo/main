# RestoreRansomEffects.ps1 改善版

# エラー発生時に表示させる
$ErrorActionPreference = "Continue"

# ======== 🔄 拡張子を元に戻す処理 ========
$targetFolder = "$env:USERPROFILE\Desktop"
$extensionToRemove = ".locked"

Write-Host "対象フォルダ: $targetFolder"
Write-Host "拡張子: $extensionToRemove を削除します"

Get-ChildItem -Path $targetFolder -Filter "*$extensionToRemove" -File | ForEach-Object {
    Write-Host "処理中: $($_.FullName)"
    $originalName = [System.IO.Path]::Combine($_.DirectoryName, ($_.BaseName))
    try {
        Rename-Item -Path $_.FullName -NewName $originalName -Force -Verbose
        Write-Host "復元成功: $($_.Name) -> $($originalName)"
    } catch {
        Write-Host "❌ ファイルの復元に失敗しました: $($_.FullName) - $($_.Exception.Message)"
    }
}

# ======== 🎨 壁紙をデフォルトに戻す処理 ========
$defaultWallpaperPath = "$env:windir\Web\Wallpaper\Windows\img0.jpg"
try {
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
    Write-Host "壁紙をデフォルトに戻しました"
} catch {
    Write-Host "❌ 壁紙復元でエラー: $($_.Exception.Message)"
}

# ======== ✅ 完了メッセージ表示 ========
try {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("ファイルと壁紙の復元が完了しました。", "復元完了", 0, 'Information')
} catch {
    Write-Host "メッセージボックス表示でエラー: $($_.Exception.Message)"
}

Write-Host "RestoreRansomEffects.ps1 完了"
