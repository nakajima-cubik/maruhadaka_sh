#!/bin/bash
# maruhadaka.sh  written by Yoshiki Nakajima

# 実行スクリプトのファイル位置を取得
script_dir=$(cd "$(dirname $0)"||exit; pwd)

# ログディレクトリ名を定義
log_name=log_$(date +%Y%m%d_%H%M%S)

# 実行スクリプトのディレクトリ配下に年月日時分秒のディレクトリを定義
log_dir=${script_dir}/${log_name}

# ディレクトリが無ければ作成する
if [ ! -d "${log_dir}" ]; then
  mkdir "${log_dir}" ||exit
fi

# tmpリスト作成
tmplist=$(mktemp "${script_dir}/maruhadaka.tmp.XXXXX" ||exit)

# 除外リスト定義
. "${script_dir}"/exclusionlist.txt

# 含めるリストを定義
. "${script_dir}"/inclusionlist.txt

# 引数で渡ってきたディレクトリ名が除外リストにあるか判定する
function isNotExistsExclusionDirs() {
    if (echo "${exclusion_dirs[@]}" | grep -q "$1") ; then
        return 1
    else
        return 0
    fi
}

# 引数で渡ってきた名前がディレクトリかどうか判定する
function isDirectory() {
    if [ -d "$1" ]; then
        return 0
    else
        return 1
    fi
}

# 引数で渡ってきたファイルがバイナリかどうか判定する
function isNotBinary() {
    a=$(file --mime "$1" | grep "charset=binary")
    if [ -n "$a" ]; then
        return 1
    else
        return 0
    fi
}

# CentOSのMajor Versionを判定する
major_version=$(cat /etc/redhat-release | sed -e 's/.*\s\([0-9]\)\..*/\1/')

# メモリ、CPU、DiskI/O の事前取得
(echo -e \\n"==================== BEFORE ===================="\\n ;vmstat -t ) |gzip > "$log_dir"/"$(date +%Y%m%d)"_CMDvmstat.txt.gz

# ルート直下ディレクトリを検索
files="/*"
for dir in $files ;
do
    # 取得結果がディレクトリかどうか、除外リストにないか確認する
    # ディレクトリかつ除外リストにない場合、tmpfileに追記する
    if isDirectory "$dir" && isNotExistsExclusionDirs "$dir" ; then
        echo "${dir}" >> "$tmplist"
    fi
done

# 除外リストのうち、特定のディレクトリを取得する場合
for dir in "${inclusion_dirs[@]}" ;
do
    # 含めるリストの名称が存在するディレクトリかどうか確認する
    # ディレクトリの場合、tmplistに追記する
    if isDirectory "$dir" ; then
        echo "${dir}" >> "$tmplist"
    fi
done

# 区切り文字を一時的に改行のみに変更
IFS_OLD=$IFS
IFS='
'

for line in `cat "$tmplist"` ;
do
    # ファイル名の設定
    file_name=$(date +%Y%m%d)${line//"/"/_}
    # ディスクI/O優先度をベストエフォート設定で最低＆コマンド優先度最低に
    # 10MB以下のファイルを検索
    for file in $(ionice -c 2 -n 7 nice -n 19 find "$line" -type f -size -10M);
    do
        echo "$file"
        if isNotBinary "$file" ; then
            echo \'"$file"\' |xargs more |cat |gzip >> "$log_dir"/"$file_name".txt.gz
        else
            echo -e \\n":::::::::::::::"\\n "${file}" \\n":::::::::::::::"\\n |gzip >> "$log_dir"/"$file_name".txt.gz
        fi
    done
done

# 区切り文字を元の値に
IFS=$IFS_OLD

# ファイル名の再設定
file_name=$(date +%Y%m%d)_


# インストール済rpmパッケージを確認する
rpm -qa |gzip > "$log_dir"/"$file_name"CMDrpm.txt.gz
rpm -qa --qf '%{name}\n' |gzip > "$log_dir"/"$file_name"CMDrpmname.txt.gz

# カーネル内部のパラメータを確認する
sysctl -a |gzip > "$log_dir"/"$file_name"CMDsysctl.txt.gz

# インストール済gemの一覧を確認する
gem list |gzip > "$log_dir"/"$file_name"CMDgem.txt.gz

# インストール済pipの一覧を確認する
pip list |gzip > "$log_dir"/"$file_name"CMDpip.txt.gz

# 設定されているcronを確認する
for user in $(cut -f1 -d: /etc/passwd); 
do 
    echo $user; crontab -u $user -l; 
done |gzip > "$log_dir"/"$file_name"CMDcron.txt.gz

# ポートおよびルーティング情報を確認する
#6系の場合
if [ "$major_version" -eq 6 ] ; then
    netstat -anp |gzip > "$log_dir"/"$file_name"CMDnetstatanp.txt.gz
    netstat -nr |gzip > "$log_dir"/"$file_name"CMDnetstatnr.txt.gz
#7系の場合
else
    if [ "$major_version" -eq 7 ] ; then
        ss -anp |gzip > "$log_dir"/"$file_name"CMDssanp.txt.gz
        routel |gzip > "$log_dir"/"$file_name"CMDroutel.txt.gz
    fi
fi

# ファイアウォール関連の確認をする stubl7にてiptableのインストールを確認 (2018/11/29)
##6系の場合
#if [ "$major_version" -eq 6 ] ; then
    iptables --list |gzip > "$log_dir"/"$file_name"CMDiptables.txt.gz
##7系の場合
#else
#    if [ "$major_version" -eq 7 ] ; then
#        firewall-cmd --get-active-zones |gzip > "$log_dir"/"$file_name"CMDfirewallac.txt.gz
#        firewall-cmd --list-all |gzip > "$log_dir"/"$file_name"CMDfirewalldf.txt.gz
#    fi
#fi

# メモリ、CPU、DiskI/O の事後取得
(echo -e \\n"==================== AFTER  ===================="\\n ;vmstat -t ) |gzip >> "$log_dir"/"$file_name"CMDvmstat.txt.gz

## 結果ファイルを圧縮
#echo -e \\n\\n"Archiving files..."\\n\\n
#
#tar zcvf "$log_name".tar.gz -C "$(pwd)" "$log_name"
#
#if [ -d "$log_name" ]; then
#    rm -rf "$log_name"
#fi

# 最後にファイルを消す
trap 'test -f "$tmplist" && rm -f "$tmplist"' 0
