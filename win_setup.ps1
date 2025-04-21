$logFile = "C:\win_config_log.txt"

function Log($message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestamp [INFO] $message"
}

function LogError($message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestamp [ERROR] $message"
}

Start-Transcript -Path "C:\win_setup_transcript.txt" -Append

try {
    Log "スクリプト実行開始"

    # Defenderのリアルタイム保護を無効化
    Log "Defenderのリアルタイム保護を無効化"
    Set-MpPreference -DisableRealtimeMonitoring $true

    # ファイアウォール無効化
    Log "ファイアウォールを無効化"
    netsh advfirewall set allprofiles state off

    # UAC無効化
    Log "UACを無効化"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0

    # Office Deployment Tool ダウンロードと展開
    $odtPath = "C:\ODT"
    $odtExe = "C:\ODTSetup.exe"
    Log "Office Deployment Toolをダウンロード"
    Invoke-WebRequest -Uri "https://download.microsoft.com/download/0/1/B/01BE1D1F-AB7B-4A02-A4B8-3A64E4F64F8C/Officedeploymenttool.exe" -OutFile $odtExe
    Log "ODTSetup.exeを展開"
    Start-Process -FilePath $odtExe -ArgumentList "/quiet /extract:$odtPath" -Wait

    # Word用構成ファイル作成
    Log "Office構成ファイル作成"
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

    # Wordをデスクトップに追加
    $wordPath = "C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE"
    if (Test-Path $wordPath) {
        Log "デスクトップにWordショートカット作成"
        $desktop = [Environment]::GetFolderPath("Desktop")
        $shortcutPath = Join-Path $desktop "Word.lnk"
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $wordPath
        $shortcut.IconLocation = $wordPath
        $shortcut.Save()
    }

    # タイムゾーンを日本時間に設定
    Log "タイムゾーンをTokyoに設定"
    Set-TimeZone -Id "Tokyo Standard Time"

    # NTP設定
    Log "NTP設定（ntp.nict.jp）"
    w32tm /config /manualpeerlist:"ntp.nict.jp" /syncfromflags:manual /update | Out-Null
    w32tm /resync | Out-Null

    # Wordインストール
    Log "Wordインストール開始"
    Start-Process -FilePath "$odtPath\setup.exe" -ArgumentList "/configure $odtPath\config.xml" -Wait

    # マクロ警告設定
    Log "Wordマクロ警告レジストリ設定"
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\Word' -Force | Out-Null
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\Word\Security' -Force | Out-Null
    New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\Word\Security' -Name 'VBAWarnings' -PropertyType DWord -Value 1 -Force

    # Chromeインストール
    Log "Chromeをダウンロード＆インストール"
    Invoke-WebRequest -Uri 'https://dl.google.com/chrome/install/latest/chrome_installer.exe' -OutFile 'C:\chrome_installer.exe'
    Start-Process -FilePath 'C:\chrome_installer.exe' -ArgumentList '/silent /install /log C:\chrome_install_log.txt' -Wait
    Remove-Item 'C:\chrome_installer.exe'

    # 既定ブラウザに設定
    $chromePath = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
    if (Test-Path $chromePath) {
        Log "Chromeを既定ブラウザに設定"
        Start-Process $chromePath -ArgumentList '--make-default-browser' -Wait
    }

    # Chromeショートカット作成（デスクトップとタスクバー）
    $chromeExePath = $chromePath
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = Join-Path $desktopPath "Google Chrome.lnk"

    if (Test-Path $chromeExePath) {
        Log "Chromeショートカット作成"
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $chromeExePath
        $shortcut.IconLocation = $chromeExePath
        $shortcut.Save()

        # タスクバーにピン留め（非公式APIの代替）
        Log "Chromeをタスクバーにピン留め"
        $taskbarShortcutPath = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Google Chrome.lnk"
        Copy-Item -Path $shortcutPath -Destination $taskbarShortcutPath -Force
    }

    # ブックマーク作成
    Log "ブックマークファイル作成"
    $bookmarkPath = "$env:PUBLIC\Bookmarks"
    New-Item -ItemType Directory -Force -Path $bookmarkPath | Out-Null
    Set-Content -Path "$bookmarkPath\bookmarks.txt" -Value "https://gmail.com`r`nhttps://dp-handson-jp4.cybereason.net"

    # 日本語の言語パックとIMEをインストール
    Log "日本語言語パックとIMEをインストール"
    Add-WindowsCapability -Online -Name Language.Basic~~~ja-JP~0.0.1.0
    Add-WindowsCapability -Online -Name Language.Handwriting~~~ja-JP~0.0.1.0
    Add-WindowsCapability -Online -Name Language.Speech~~~ja-JP~0.0.1.0
    Add-WindowsCapability -Online -Name Language.TextToSpeech~~~ja-JP~0.0.1.0

    # 言語設定
    Log "言語設定を日本語に変更"
    Set-WinUILanguageOverride -Language ja-JP
    Set-WinUserLanguageList ja-JP -Force
    Set-WinSystemLocale ja-JP
    Set-Culture ja-JP
    Set-WinHomeLocation -GeoId 122

    # プロキシ設定（ユーザー＋WinHTTP）
    Log "プロキシ設定"
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    Set-ItemProperty -Path $regPath -Name ProxyEnable -Value 1
    Set-ItemProperty -Path $regPath -Name ProxyServer -Value "10.0.1.254:3128"
    netsh winhttp set proxy 10.0.1.254:3128

    Log "スクリプト実行完了"

} catch {
    LogError "エラー発生: $($_.Exception.Message)"
} finally {
    Stop-Transcript
}
