# use this incantation to keep unwanted local projects "mdb for their content and credentials" sort of invisible
# since ony single files can be "assumed-unchanged": Hey, it works...
git ls-files --deleted -z | git update-index --assume-unchanged -z --stdin

