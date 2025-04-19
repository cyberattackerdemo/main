try {
    # Defenderのリアルタイム保護を無効化
    Set-MpPreference -DisableRealtimeMonitoring $true

    # ファイアウォール無効化
    netsh advfirewall set allprofiles state off

    # ユーザーアカウント制御 (UAC) を無効化
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0

    # Office Deployment Tool のダウンロードと展開
    $odtPath = "C:\ODT"
    Invoke-WebRequest -Uri "https://download.microsoft.com/download/0/1/B/01BE1D1F-AB7B-4A02-A4B8-3A64E4F64F8C/Officedeploymenttool.exe" -OutFile "C:\ODTSetup.exe"
    Start-Process -FilePath "C:\ODTSetup.exe" -ArgumentList "/quiet /extract:$odtPath" -Wait

    # Wordのみの構成ファイル作成
    $configXml = @"
<Configuration>
  <Add OfficeClientEdition="64" Channel="Current">
    <Product ID="O365ProPlusRetail">
      <Language ID="ja-jp" />
      <ExcludeApp ID="Access" />
      <ExcludeApp ID="Excel" />
      <ExcludeApp ID="OneNote" />
      <ExcludeApp ID="Outlook" />
      <ExcludeApp ID="PowerPoint" />
      <ExcludeApp ID="Publisher" />
      <ExcludeApp ID="Teams" />
    </Product>
  </Add>
  <Display Level="None" AcceptEULA="TRUE" />
</Configuration>
"@
    Set-Content -Path "$odtPath\config.xml" -Value $configXml

    # タイムゾーンを日本時間に設定
    Set-TimeZone -Id "Tokyo Standard Time"

    # NTP同期
    w32tm /config /manualpeerlist:"ntp.nict.jp" /syncfromflags:manual /update
    w32tm /resync

    # Wordインストール開始
    Start-Process -FilePath "$odtPath\setup.exe" -ArgumentList "/configure $odtPath\config.xml" -Wait

    # Wordマクロ設定
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\Word' -Force | Out-Null
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\Word\Security' -Force | Out-Null
    New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\Word\Security' -Name 'VBAWarnings' -PropertyType DWord -Value 1 -Force

    # Chromeインストール
    Invoke-WebRequest -Uri 'https://dl.google.com/chrome/install/latest/chrome_installer.exe' -OutFile 'C:\chrome_installer.exe'
    Start-Process -FilePath 'C:\chrome_installer.exe' -ArgumentList '/silent /install /log C:\chrome_install_log.txt' -Wait
    Remove-Item 'C:\chrome_installer.exe'

    # Chrome既定ブラウザに
    $chromePath = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
    if (Test-Path $chromePath) {
        Start-Process $chromePath -ArgumentList '--make-default-browser' -Wait
    }

    # ブックマークの作成
    $bookmarkPath = "$env:PUBLIC\Bookmarks"
    New-Item -ItemType Directory -Force -Path $bookmarkPath | Out-Null
    Set-Content -Path "$bookmarkPath\bookmarks.txt" -Value "https://gmail.com`r`nhttps://dp-handson-jp4.cybereason.net"

    # 成功ログ
    Add-Content -Path 'C:\win_config_log.txt' -Value 'Script executed successfully'
}
catch {
    Add-Content -Path 'C:\win_config_log.txt' -Value ('Error: ' + $_.Exception.Message)
}

# 日本語IMEと言語パックのインストール
Add-WindowsCapability -Online -Name Language.Basic~~~ja-JP~0.0.1.0
Add-WindowsCapability -Online -Name Language.Handwriting~~~ja-JP~0.0.1.0
Add-WindowsCapability -Online -Name Language.Speech~~~ja-JP~0.0.1.0
Add-WindowsCapability -Online -Name Language.TextToSpeech~~~ja-JP~0.0.1.0

# 言語設定を日本語に
Set-WinUILanguageOverride -Language ja-JP
Set-WinUserLanguageList ja-JP -Force
Set-WinSystemLocale ja-JP
Set-Culture ja-JP
Set-WinHomeLocation -GeoId 122
