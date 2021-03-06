# extract a subproject in first level folder from a Git mother repository.
# the complete history will be extracted.
# the target repository is created, so it has to run on the Git server itself.
#
# It even support sub-Subprojects (like: gems/firstgem), given, that the Git-Base-Repositories have
# the leading path.
#
# the use case follows:
# http://gbayer.com/development/moving-files-from-one-git-repository-to-another-preserving-history/

export LANG=C

MODE="$1"
SUB_PROJECT="$2"
MOTHER_PROJECT="$3"

WORKDIR=$PWD

GITBASE=/srv/git/repos/software

if [ ! -r .gitfiddle ]; then
	echo "this is not the work directory"
	exit 1
fi

test -z "$SUB_PROJECT" && SUB_PROJECT=devsupport
test -z "$MOTHER_PROJECT" && MOTHER_PROJECT=root

if [ -z "$MOTHER_PROJECT" -o -z "$SUB_PROJECT" ]; then
  echo "usage: doozamagic [mode] [subdir] [motherproject]"
  exit 1
fi

GITBASE_TO="$GITBASE/projects"
    URL_TO="$GITBASE_TO/$SUB_PROJECT"
  URL_FROM="$GITBASE/$MOTHER_PROJECT"

IMPORTDIR=import_dir

createSubproject()
{
echo ">>> create new repo $SUB_PROJECT in $URL_TO"
cd $GITBASE_TO
test -d $SUB_PROJECT && rm -rf $SUB_PROJECT
mkdir $SUB_PROJECT
cd $SUB_PROJECT
git --bare init
cd $WORKDIR
test -d $SUB_PROJECT && rm -rf $SUB_PROJECT
git clone "$URL_TO" temprepo
mkdir -p $SUB_PROJECT
mv -T temprepo $SUB_PROJECT
cd $SUB_PROJECT || exit 1
touch .gitignore
git add .gitignore
git commit -a -m startup
git push
cd $WORKDIR
}

checkoutImportDir()
{
echo ">>> checking out $MOTHER_PROJECT into $IMPORTDIR"
test -d `basename $MOTHER_PROJECT` && rm -rf `basename $MOTHER_PROJECT`
test -d $IMPORTDIR && rm -rf $IMPORTDIR
git clone $URL_FROM
mv `basename $MOTHER_PROJECT` $IMPORTDIR
}

filterImportDir()
{
echo ">>> filtering out $SUB_PROJECT inside $IMPORTDIR"
cd $IMPORTDIR || exit 1
git remote rm origin # safety measure
if [ ! -d $SUB_PROJECT ]; then
  echo "$SUB_PROJECT is no longer available, ending!"
  exit 0
fi
git filter-branch --subdirectory-filter $SUB_PROJECT -- --all
test -d `basename $SUB_PROJECT` || mkdir `basename $SUB_PROJECT`
mv .gitignore * `basename $SUB_PROJECT`
cd $WORKDIR
}

mergeImportDir()
{
echo ">>> merging import dir into $SUB_PROJECT"
cd $SUB_PROJECT || exit 1
git remote add import-dir "$WORKDIR/$IMPORTDIR"
# git fetch import-dir master
# git merge master -m "forked from $URL_FROM"
git pull --no-edit import-dir master
git remote rm import-dir
git push origin
}

case "$MODE" in

checkout) checkoutImportDir ;;
mkrepo) createSubproject ;;
filter) filterImportDir ;;
merge) mergeImportDir ;;

all) checkoutImportDir ; createSubproject ; filterImportDir ; mergeImportDir ;;

esac
 
