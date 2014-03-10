
DRY_MODE="--dry-run"
[ "$1" = "--force" ] && DRY_MODE=""

PAIRS='
projects/devsupport/tasks:pm-git/software/devsupport/tasks
projects/devsupport/vim:pm-git/software/devsupport/vim
projects/devsupport/bin:pm-git/software/devsupport/bin
projects/devsupport/yard:pm-git/software/devsupport/yard
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


