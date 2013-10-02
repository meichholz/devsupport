PAIRS='
projects/lib:pm-git/software/lib
'
cd $HOME || exit 3
for pair in $PAIRS ; do
	my_dir=`echo $pair | cut -d: -f2`
	their_dir=`echo $pair | cut -d: -f1`
	echo "comparing <$my_dir> to <$their_dir>"
	modes="-rtu --verbose"
	# modes="$modes --dry-run"
	rsync $modes "$my_dir"/ "$their_dir" # slash on source is important
done


