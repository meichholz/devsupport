test -r ~/pm-git/software || exit 1
for i in ~/projects/dotvim ~/pm-git/software/dotvim ~/pm-git/config ; do
	cd $i || exit 2
    git pull
done

DRY_MODE="--dry-run"
[ "$1" = "--force" ] && DRY_MODE=""

PAIRS='
projects/dotvim:pm-git/config/puppet/modules/editors/files/dotvim
projects/lib:pm-git/software/lib
'
cd $HOME || exit 3
for pair in $PAIRS ; do
	my_dir=`echo $pair | cut -d: -f1`
	their_dir=`echo $pair | cut -d: -f2`
	echo "comparing <$my_dir> to <$their_dir>"
	modes="-rtu --verbose --cvs-exclude"
	modes="$modes $DRY_MODE"
	rsync $modes "$my_dir"/ "$their_dir" # slash on source is important
done


