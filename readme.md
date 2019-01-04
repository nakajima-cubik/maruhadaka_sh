# maruhadaka.sh
###### 2018/11/22

```
maruhadaka[dir]
  ├ exclusionlist.txt
  ├ inclusionlist.txt
  └ maruhadaka.sh
```

- バイナリファイル以外を.txtへ出力します。  
- .txtファイルはルート直下のディレクトリ単位で出力します。  
- 出力したファイルは.tar.gz形式で圧縮します。  


注意： ”maruhadaka.sh” と ”exclusionlist.txt” および ”inclusionlist.txt” は同一ディレクトリパスへ格納してください。  
注意：実行中は書き出ししているファイルパスを画面上へ出力し続けます。不要の場合は91行目の ”echo "$file"” をコメントアウトしてください。  


1. ”exclusionlist.txt” を編集
1. ”inclusionlist.txt” を編集
1. ”maruhadaka.sh” を実行

```
log_YYYYMMDD_hhmmss[dir]
  └ YYYYMMDD_XXX.txt
```


