# vim: ft=sh
SUBDIRS="tasks vim bin yard"
MEPATH=projects/devsupport
PMPATH=pm-git/software/devsupport

for i in $SUBDIRS ; do
	PAIRS="$PAIRS $MEPATH/$i:$PMPATH/$i"
done
cd $HOME || exit 3

DRY_MODE="--dry-run"
if [ "$1" = "--force" ]; then
	DRY_MODE=""
	shift
fi

MODE="$1"

syncThem()
{
  local their_dir my_dir pair modes
  their_dir=`echo $pair | cut -d: -f$1`
  my_dir=`echo $pair | cut -d: -f$2`

  for pair in $PAIRS ; do
	  my_dir=`echo $pair | cut -d: -f2`
	  echo "comparing <$my_dir> to <$their_dir>"
	  modes="-rtu --verbose --cvs-exclude"
	  modes="$modes $DRY_MODE"
	  rsync $modes "$my_dir"/ "$their_dir" # slash on source is important
  done
}

checkSanity()
{
	test -r $PMPATH || exit 1

	# just for sanity: update it
	for i in ~/projects/devsupport ~/projects/dotvim ~/pm-git/software/devsupport ~/pm-git/config ; do
		cd $i || exit 2
		git pull
	done
}

diffThem()
{
	for pair in $PAIRS ; do
		my_dir=`echo $pair | cut -d: -f2`
		their_dir=`echo $pair | cut -d: -f1`
		diff -r $my_dir $their_dir
	done
}

case "$MODE" in
	diff) diffThem ;;
	to-fn)
		checkSanity
        syncThem 2 1 # to FN
		;;
	from-fn)
		checkSanity
		syncThem 1 2 # from FN
		;;
	*) echo "USAGE: sh sync.sh [--force] diff|to-fn|from-fn"
	   ;;
esac

