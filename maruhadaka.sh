#!/bin/bash
# maruhadaka.sh  written by Yoshiki Nakajima
# 2019/01/04

# 実行スクリプトのファイル位置を取得
script_dir=$(cd "$(dirname $0)"||exit; pwd)

# ログディレクトリ名を定義
log_name=`hostname`_log_$(date +%Y%m%d_%H%M%S)

# 実行スクリプトのディレクトリ配下に年月日時分秒のディレクトリを定義
log_dir=${script_dir}/${log_name}

# ディレクトリが無ければ作成する
echo "directory creation..."
if [ ! -d "${log_dir}" ]; then
  mkdir "${log_dir}" ||exit
fi
echo "done"

# tmpリスト作成
echo "list creation..."
tmplist=$(mktemp "${script_dir}/maruhadaka.tmp.XXXXX" ||exit)

# 除外リスト定義
. "${script_dir}"/exclusionlist.txt

# 含めるリストを定義
. "${script_dir}"/inclusionlist.txt

echo "done"

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

echo "start acquiring..."

# CentOSのMajor Versionを判定する
major_version=$(cat /etc/redhat-release | sed -e 's/.*\s\([0-9]\)\..*/\1/')

# メモリ、CPU、DiskI/O の事前取得
echo "vmstat -t > CMDvmstat.txt"
(echo -e \\n"==================== BEFORE ===================="\\n ;vmstat -t ) |gzip > "$log_dir"/"$(date +%Y%m%d)"_CMDvmstat.txt.gz

# ルート直下ディレクトリを検索
echo "cat /* > *.txt"
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
echo "rpm -qa --last > CMDrpm.txt"
rpm -qa --last |gzip > "$log_dir"/"$file_name"CMDrpm.txt.gz
echo "rpm -qa --qf > CMDrpmname.txt"
rpm -qa --qf '%{name}\n' |gzip > "$log_dir"/"$file_name"CMDrpmname.txt.gz

# カーネル内部のパラメータを確認する
echo "sysctl -a > CMDrpmname.txt"
sysctl -a |gzip > "$log_dir"/"$file_name"CMDsysctl.txt.gz

# インストール済gemの一覧を確認する
echo "gem list > CMDrpmname.txt"
gem list |gzip > "$log_dir"/"$file_name"CMDgem.txt.gz

# インストール済pipの一覧を確認する
echo "pip list > CMDpip.txt"
pip list |gzip > "$log_dir"/"$file_name"CMDpip.txt.gz
echo "pip3 list > CMDpip3.txt"
pip3 list --format=legacy |gzip > "$log_dir"/"$file_name"CMDpip3.txt.gz

# 設定されているcronを確認する
echo "crontab -l > CMDcron.txt"
for user in $(cut -f1 -d: /etc/passwd); 
do 
  echo $user; crontab -u $user -l; 
done |gzip > "$log_dir"/"$file_name"CMDcron.txt.gz

# ポートおよびルーティング情報を確認する
#6系の場合
if [ "$major_version" -eq 6 ] ; then
  echo "netstat -anp > CMDnetstatanp.txt"
  netstat -anp |gzip > "$log_dir"/"$file_name"CMDnetstatanp.txt.gz
  echo "netstat -nr > CMDnetstatnr.txt"
  netstat -nr |gzip > "$log_dir"/"$file_name"CMDnetstatnr.txt.gz
#7系の場合
else
  if [ "$major_version" -eq 7 ] ; then
    echo "ss -anp > CMDssanp.txt"
    ss -anp |gzip > "$log_dir"/"$file_name"CMDssanp.txt.gz
    echo "routel > CMDroutel.txt"
    routel |gzip > "$log_dir"/"$file_name"CMDroutel.txt.gz
  fi
fi

# ファイアウォール関連の確認をする stubl7にてiptableのインストールを確認 (2018/11/29)
##6系の場合
#if [ "$major_version" -eq 6 ] ; then
  echo "iptables --list > CMDiptables.txt"
  iptables --list |gzip > "$log_dir"/"$file_name"CMDiptables.txt.gz
##7系の場合
#else
#  if [ "$major_version" -eq 7 ] ; then
#    echo "firewall-cmd --get-active-zones > CMDfirewallac.txt"
#    firewall-cmd --get-active-zones |gzip > "$log_dir"/"$file_name"CMDfirewallac.txt.gz
#    echo "firewall-cmd --list-all > CMDfirewalldf.txt"
#    firewall-cmd --list-all |gzip > "$log_dir"/"$file_name"CMDfirewalldf.txt.gz
#  fi
#fi

# パーミッション等の情報取得
echo "ls -lRa > CMDlslRa.txt"
ls -lRa / |gzip > "$log_dir"/"$file_name"CMDlslRa.txt.gz

# プロセス情報取得
echo "ps -A > CMDps.txt"
ps -A o user,command --no-header --sort command | grep -v -e '\s\['|gzip > "$log_dir"/"$file_name"CMDps.txt.gz

# 高頻度で使用されるディレクトリの情報取得
echo "du -m > CMDdusize.txt"
du -m / --max-depth=3 --exclude="/proc*" | sort -k1 -n -r |gzip > "$log_dir"/"$file_name"CMDdusize.txt.gz

# メモリ、CPU、DiskI/O の事後取得
(echo -e \\n"==================== AFTER  ===================="\\n ;vmstat -t ) |gzip >> "$log_dir"/"$file_name"CMDvmstat.txt.gz

# 結果ファイルを圧縮
echo -e \\n\\n"Archiving files..."\\n\\n
tar cvf "$log_name".tar -C "$(pwd)" "$log_name"

if [ -d "$log_name" ]; then
    rm -rf "$log_name"
fi

# 最後にファイルを消す
trap 'test -f "$tmplist" && rm -f "$tmplist"' 0

