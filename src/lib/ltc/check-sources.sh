#! /bin/sh
#
# $Id$
#

# Location of libtomcrypt as pulled from GitHub
source=../libtomcrypt

# ----------------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------------

echo "*** Cmd:    /bin/sh `basename $0`"
echo "*** Date:   `date`"
echo "*** Source: http://github.com/tomstdenis/libtomcrypt/tree/develop"
echo "            http://www.libtom.net/LibTomCrypt"
echo

echo "*** Libtomcrypt repo:" \
     `(cd "$source" && git describe --all)` \
     `(cd "$source" && git describe --tags)`
echo


find . -name \*.[ch] -print |
while
    read path
do
    case "$path" in
    ./nimcache/*|\
    */tomcrypt_nim.h|\
    */ltc_*specs.c|\
    */ltc_crypt-const.c) continue
    esac
    
    file=`echo "$path"|sed -e 's/.*\///' -e 's/^ltc_crypt-//' -e 's/^ltc_//'`
    orig=`find $source -name "*$file" -print`

    test -f "$orig" || {
	echo "*** missing $path:"
	continue
    }
    
    diff=`diff -u "$orig" "$path"`
    test -z "$diff" && continue

    echo "*** diff $file:"
    echo "$diff"
    echo
done

echo "*** End"

# ----------------------------------------------------------------------------
# End
# ----------------------------------------------------------------------------
