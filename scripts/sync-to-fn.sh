test -r ~/pm-git/software || exit 1
for i in ~/projects ~/pm-git/software ~/pm-git/config ; do
	cd $i || exit 2
    git pull
done

PAIRS='
projects/dotvim:pm-git/config/puppet/modules/editors/files/dotvim
projects/lib:pm-git/software/lib
'
cd $HOME || exit 3
for pair in $PAIRS ; do
	my_dir=`echo $pair | cut -d: -f1`
	their_dir=`echo $pair | cut -d: -f2`
	echo "comparing <$my_dir> to <$their_dir>"
	modes="-rtu --verbose"
	# modes="$modes --dry-run"
	rsync $modes "$my_dir"/ "$their_dir" # slash on source is important
done

cd ~/pm-git/software
git commit -a
cd ~/pm-git/config
git commit -a

