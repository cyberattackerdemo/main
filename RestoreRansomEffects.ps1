# ======== RestoreRansomEffects.ps1（すべて .docx に復元） ========
[CmdletBinding()]
param(
  [string]$TargetFolder = (Join-Path $env:USERPROFILE 'Desktop'),  # 既定はデスクトップ
  [switch]$Recurse,                                                # サブフォルダも処理： -Recurse
  [switch]$WhatIfMode                                              # ドライラン       ： -WhatIfMode
)

$ErrorActionPreference = 'Continue'

Write-Host "対象フォルダ: $TargetFolder"
Write-Host "復元方針: すべての *.locked を .docx にリネームします"
if ($Recurse) { Write-Host "サブフォルダも再帰的に処理します" }

# ---- 既存名と衝突しないパスを作る ----
function Get-NonCollidingPath {
  param(
    [Parameter(Mandatory)][string]$Dir,
    [Parameter(Mandatory)][string]$Base
  )
  $candidate = Join-Path $Dir ($Base + '.docx')
  if (-not (Test-Path -LiteralPath $candidate)) { return $candidate }
  $i = 1
  while ($true) {
    $candidate = Join-Path $Dir ("{0} ({1}).docx" -f $Base, $i)
    if (-not (Test-Path -LiteralPath $candidate)) { return $candidate }
    $i++
  }
}

# ---- .locked を一括で .docx に復元 ----
$gciArgs = @{
  LiteralPath = $TargetFolder
  Filter      = '*.locked'
  File        = $true
  ErrorAction = 'SilentlyContinue'
}
if ($Recurse) { $gciArgs.Recurse = $true }

$lockedFiles = @(Get-ChildItem @gciArgs)

if ($lockedFiles.Count -eq 0) {
  Write-Host "対象ファイルが見つかりませんでした。"
} else {
  $count = 0
  foreach ($f in $lockedFiles) {
    try {
      $baseName = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)  # .locked を外したベース名
      $target   = Get-NonCollidingPath -Dir $f.DirectoryName -Base $baseName
      $newLeaf  = Split-Path $target -Leaf

      Write-Host ("[DOCX固定] {0} -> {1}" -f $f.Name, $newLeaf)

      if ($WhatIfMode) {
        Rename-Item -LiteralPath $f.FullName -NewName $newLeaf -WhatIf
      } else {
        Rename-Item -LiteralPath $f.FullName -NewName $newLeaf -Force -Verbose
        $count++
      }
    } catch {
      Write-Host "❌ 復元失敗: $($f.FullName) - $($_.Exception.Message)"
    }
  }
  Write-Host ("処理件数: {0}" -f $count)
}

# ---- 壁紙をデフォルトに戻す ----
$defaultWallpaperPath = "$env:windir\Web\Wallpaper\Windows\img0.jpg"
try {
  Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name Wallpaper -Value $defaultWallpaperPath

  Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class NativeMethods {
  [DllImport("user32.dll", SetLastError = true)]
  public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@

  [void][NativeMethods]::SystemParametersInfo(20, 0, $defaultWallpaperPath, 3)
  Write-Host "壁紙をデフォルトに戻しました"
} catch {
  Write-Host "❌ 壁紙復元でエラー: $($_.Exception.Message)"
}

# ---- 完了メッセージ ----
try {
  Add-Type -AssemblyName System.Windows.Forms
  [void][System.Windows.Forms.MessageBox]::Show(
    "ファイル（*.locked）は .docx に復元され、壁紙も初期化されました。",
    "復元完了",
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information
  )
} catch {
  Write-Host "メッセージボックス表示でエラー: $($_.Exception.Message)"
}

Write-Host "RestoreRansomEffects.ps1 完了"
