# RestoreRansomEffects.ps1 改善版

# エラー発生時に表示させる
$ErrorActionPreference = "Continue"

# ======== 🔄 拡張子を元に戻す処理（改良版） ========
param(
  [switch]$Recurse,          # -Recurse を付けるとサブフォルダも対象に
  [switch]$WhatIfMode        # -WhatIfMode でドライラン
)

$targetFolder      = Join-Path $env:USERPROFILE 'Desktop'
$extensionToRemove = '.locked'

Write-Host "対象フォルダ: $targetFolder"
Write-Host "拡張子 $extensionToRemove を復旧（推定で .docx / .txt を付与）"
if ($Recurse) { Write-Host "サブフォルダも再帰的に処理します" }

# ファイル内容から拡張子推定
function Get-OriginalExtension {
  param([string]$Path)
  try {
    $fs = [System.IO.File]::Open($Path, 'Open', 'Read', 'ReadWrite')
    try {
      $buf = New-Object byte[] 4
      $null = $fs.Read($buf, 0, 4)
    } finally { $fs.Dispose() }
    # DOCX は ZIP: 先頭 50 4B (= 'PK')
    if ($buf[0] -eq 0x50 -and $buf[1] -eq 0x4B) { return '.docx' }
    return '.txt'
  } catch {
    # 読めない場合は安全側で .txt
    return '.txt'
  }
}

# 既存衝突を避けるため連番を付与
function Get-NonCollidingPath {
  param([string]$Dir, [string]$Base, [string]$Ext)
  $candidate = Join-Path $Dir ($Base + $Ext)
  if (-not (Test-Path -LiteralPath $candidate)) { return $candidate }
  $i = 1
  while ($true) {
    $candidate = Join-Path $Dir ("{0} ({1}){2}" -f $Base, $i, $Ext)
    if (-not (Test-Path -LiteralPath $candidate)) { return $candidate }
    $i++
  }
}

$gciArgs = @{
  Path        = $targetFolder
  Filter      = "*$extensionToRemove"
  File        = $true
  ErrorAction = 'SilentlyContinue'
}
if ($Recurse) { $gciArgs.Recurse = $true }

$lockedFiles = @(Get-ChildItem @gciArgs)

if ($lockedFiles.Count -eq 0) {
  Write-Host "対象ファイルが見つかりませんでした。"
} else {
  foreach ($f in $lockedFiles) {
    try {
      $origExt   = Get-OriginalExtension -Path $f.FullName
      $baseName  = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)  # .locked を外す
      $target    = Get-NonCollidingPath -Dir $f.DirectoryName -Base $baseName -Ext $origExt

      Write-Host ("復元候補: {0} -> {1}" -f $f.Name, (Split-Path $target -Leaf))

      if ($WhatIfMode) {
        Rename-Item -LiteralPath $f.FullName -NewName (Split-Path $target -Leaf) -WhatIf
      } else {
        Rename-Item -LiteralPath $f.FullName -NewName (Split-Path $target -Leaf) -Force -Verbose
        Write-Host "✅ 復元成功: $($f.Name) -> $(Split-Path $target -Leaf)"
      }
    } catch {
      Write-Host "❌ 復元失敗: $($f.FullName) - $($_.Exception.Message)"
    }
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

