if [ ! -r .gitmodules ]; then
	echo "PANIC: must be called in sandbox parent directory"
	exit 1
fi
if [ -d trunk ]; then
	TRUNK='trunk/'
else
    TRUNK=""
fi
SBOX=${TRUNK}devsupport
if [ ! -d $BOX ]; then
	echo "PANIC: $TRUNK not found. Please investigate!"
    exit 1
fi
URL='ssh://git@git.freenet.de/srv/git/repos/software/devsupport'
git rm -rf $SBOX
git submodule deinit $SBOX
rm -rf .git/modules/$SBOX
git submodule add "$URL" $SBOX

