#!/bin/bash

case $1 in
	to)
		src=0 #local
		dest=1 # remote	
		;;
	from)
		src=1 # remote
		dest=0 # remote
		;;
	*)
		echo "Please specify 'to' or 'from'"
		exit 1
		;;
esac

remote=${2?remote was not specified}
ssync_config=~/.config/lstuff/ssync.conf
tmpfile=/tmp/ssync-"$USER"
check='s/^\*deleting /Delete/p'
[ "$3" == v ] && check+=';s/^\(<\|>\)[^ ]*/Update/p'
[ "$3" == vv ] && check='s/\.\/$//;p'

echo 'The following will occur (see verbosity settings)'
(umask 077; rm -f $tmpfile; touch $tmpfile;)
while read -r line
do
	eval "paths=($line)"
	paths[0]=$(ls -pd "${paths[0]}") # local
	paths[1]=$remote:${paths[1]:-${paths[0]}} # remote
	outputpath=${paths[$dest]}
	[ -d ${paths[0]} ] || outputpath=${paths[$dest]%/*}/
	rsync -uain --del "${paths[$src]}" "${paths[$dest]}" \
		--out-format="%i $outputpath%n" || exit 1
	echo "'${paths[$src]}' '${paths[$dest]}'" >> $tmpfile
done < $ssync_config | sed -ne "$check"

read -p 'Continue?[y/N]' continue
echo $continue | grep -qi '^y[e]*[s]*$' || exit 1

while read -r line
do
	eval "args=($line)"
	echo working in directory/on file ${args[1]}
	eval "rsync -Pua --del  $line" # | sed "/\.\//c ${args[1]}"
	[ ${PIPESTATUS[0]} == 1 ] && exit 1
done < $tmpfile
