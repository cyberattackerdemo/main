
import os
import ctypes
from pathlib import Path

# デスクトップパス
desktop = Path(os.path.join(os.environ["USERPROFILE"], "Desktop"))

# .txt ファイルを .locked に変更（模擬）
for file in desktop.glob("*.txt"):
    new_name = file.with_name(file.name + ".locked")
    file.rename(new_name)

# 復号メッセージファイル作成（日本語）
message = """!!! ファイルは暗号化されました !!!

これはハンズオン演習の模擬ランサムウェアです。
実際にはファイルは暗号化されていません。

速やかにインシデント対応チームに報告してください。

--- 教育用デモ ---
"""
(readme := desktop / "README_復号方法について.txt").write_text(message, encoding="utf-8")

# 警告メッセージ（ポップアップ）
ctypes.windll.user32.MessageBoxW(0,
    "ファイルは暗号化されました。\nデスクトップ上の案内ファイルを確認してください。",
    "ランサムウェア警告", 0x30)
