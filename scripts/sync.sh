# vim: ft=sh
MEPATH=projects/devsupport
PMPATH=pm-git/software/devsupport

PAIRS="projects/dotvim:pm-git/config/puppet/modules/editors/files/dotvim"
for i in tasks vim bin yard ; do
	PAIRS="$PAIRS $MEPATH/$i:$PMPATH/$i"
done

DRY_MODE="--dry-run"
if [ "$1" = "--force" ]; then
	DRY_MODE=""
	shift
fi

MODE="$1"

syncThem()
{
  local their_dir my_dir pair modes

  cd $HOME || exit 3

  for pair in $PAIRS ; do
	  their_dir=`echo $pair | cut -d: -f$1`
	  my_dir=`echo $pair | cut -d: -f$2`
	  echo ">>> rsyncing <$my_dir> to <$their_dir>"
	  modes="-rtuvC --include=tags"
	  modes="$modes $DRY_MODE"
	  rsync $modes "$my_dir"/ "$their_dir" # slash on source is important
  done
}

checkSanity()
{
    cd $HOME || exit 3
	test -r $PMPATH || exit 1

	# just for sanity: update it
	for i in ~/projects/devsupport ~/projects/dotvim ~/pm-git/software/devsupport ~/pm-git/config ; do
		cd $i || exit 2
		git pull
	done
}

diffThem()
{
    cd $HOME || exit 3
	for pair in $PAIRS ; do
		my_dir=`echo $pair | cut -d: -f$2`
		their_dir=`echo $pair | cut -d: -f$1`
		diff -r $my_dir $their_dir
	done
}

case "$MODE" in
	diff) diffThem 1 2 ;;
	to-fn)
		checkSanity
        syncThem 2 1
		;;
	from-fn)
		checkSanity
		syncThem 1 2
		;;
	*) echo "USAGE: sh sync.sh [--force] diff|to-fn|from-fn"
	   ;;
esac

