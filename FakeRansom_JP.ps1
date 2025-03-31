
$desktop = [Environment]::GetFolderPath("Desktop")

# デスクトップ上の .txt ファイルに .locked をつけて名前変更
Get-ChildItem -Path $desktop -Filter *.txt | ForEach-Object {
    Rename-Item $_.FullName ($_.Name + ".locked")
}

# 警告メッセージ作成（日本語）
$warning = @"
!!! ファイルは暗号化されました !!!

これは教育目的での模擬ランサムウェア実行です。
実際には暗号化されていませんが、ファイル名が変更されました。

速やかにインシデント対応チームへ連絡してください。

--- ハンズオン演習用デモ ---
"@

Set-Content -Path "$desktop\README_復号方法について.txt" -Value $warning

# 警告ポップアップを表示（日本語）
Add-Type -AssemblyName PresentationFramework
[System.Windows.MessageBox]::Show("ファイルは暗号化されました。\n復号方法についてのファイルをデスクトップ上で確認してください。", "ランサムウェア警告", 0, 'Warning')
