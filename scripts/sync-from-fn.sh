
DRY_MODE="--dry-run"
[ "$1" = "--force" ] && DRY_MODE=""

PAIRS='
projects/devsupport:pm-git/software/devsupport
'
cd $HOME || exit 3
for pair in $PAIRS ; do
	my_dir=`echo $pair | cut -d: -f2`
	their_dir=`echo $pair | cut -d: -f1`
	echo "comparing <$my_dir> to <$their_dir>"
	modes="-rtu --verbose --cvs-exclude"
	modes="$modes $DRY_MODE"
	rsync $modes "$my_dir"/ "$their_dir" # slash on source is important
done


