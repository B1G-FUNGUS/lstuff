#!/bin/bash

ssync_cfg_root=~/.config/lstuff/ssync
check='s/^\*deleting /Delete/p'
tmpfile=/tmp/ssync-"$USER"
while getopts 't:f:uvCT' option
do
	case $option in
		t)
			src=0 # local
			dest=1 #remote
			remote=$OPTARG
			;;
		f)
			src=1 # local
			dest=0 #remote
			remote=$OPTARG
			;;
		u)
			check+=';s/^\(<\|>\)[^ ]*/Update/p'
			;;
		v)
			check='s/\.\/$//;p'
			;;
		C)
			ssync_cfg_root=$OPTARG
			;;
		T)
			tmpfile=$OPTARG
			;;
	esac
done

ssync_config=$ssync_cfg_root-${remote?:No remote found}.conf
[ -v $remote ] && exit 1

echo 'The following will occur (see verbosity settings)'
(umask 077; rm -f "$tmpfile"; touch "$tmpfile";)
while read -r line
do
	dirsig=''
	change=''
	eval "paths=($line)"
	ls -pd "${paths[0]}"  | grep -q '/$' && dirsig='/'
	paths[1]=$remote:${paths[1]:-${paths[0]}}$dirsig
	paths[0]=${paths[0]}$dirsig # local
	outputpath=${paths[$dest]}
	[ -d ${paths[0]} ] || outputpath=${paths[$dest]%/*}/
	info=$(rsync -uain --del "${paths[$src]}" "${paths[$dest]}" \
		--out-format="%i $outputpath%n") || exit 1
	printf '%s\n' "$info"
	printf '%s\n' "$info" | grep -q '^\(<\|>\|\*deleting\)' &&
		echo "'${paths[$src]}' '${paths[$dest]}'" >> "$tmpfile"
done < "$ssync_config" | sed -ne "$check"

read -p 'Continue?[y/N]' continue
echo $continue | grep -qi '^y[e]*[s]*$' || exit 1

while read -r line
do
	eval "args=($line)"
	echo working in directory/on file ${args[1]}
	eval "rsync -Puaz --del  $line" # | sed "/\.\//c ${args[1]}"
	[ ${PIPESTATUS[0]} == 1 ] && exit 1
done < "$tmpfile"

trap "exit 130" SIGINT
