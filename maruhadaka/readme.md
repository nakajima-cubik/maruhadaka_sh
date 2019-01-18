# maruhadaka.sh

## 概要

- バイナリファイル以外を.txtへ出力します。  
- .txtファイルはルート直下のディレクトリ単位で出力します。  
- 出力したファイルは.tar.gz形式で圧縮します。  

## 構成

```bash
maruhadaka[dir]
  ├ exclusionlist.txt
  ├ inclusionlist.txt
  └ maruhadaka.sh
```

  注意： ”maruhadaka.sh” と ”exclusionlist.txt” および ”inclusionlist.txt” は同一ディレクトリパスへ格納してください。  
  注意：実行中は書き出ししているファイルパスを画面上へ出力し続けます。不要の場合は91行目の ”echo "$file"” をコメントアウトしてください。  

## 手順

1. ”exclusionlist.txt” を編集
1. ”inclusionlist.txt” を編集
1. root へスイッチ
1. ”maruhadaka.sh” を実行

```bash
`hostname`_log_YYYYMMDD_hhmmss.tar
```
