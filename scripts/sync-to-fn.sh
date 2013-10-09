test -r ~/pm-git/software || exit 1

cd $HOME

for i in ~/projects/devsupport ~/projects/dotvim ~/pm-git/software/devsupport ~/pm-git/config ; do
	cd $i || exit 2
    git pull
done

DRY_MODE="--dry-run"
[ "$1" = "--force" ] && DRY_MODE=""

PAIRS='
projects/dotvim:pm-git/config/puppet/modules/editors/files/dotvim
projects/devsupport/tasks:pm-git/software/devsupport/tasks
projects/devsupport/vim:pm-git/software/devsupport/vim
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


