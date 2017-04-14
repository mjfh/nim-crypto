#! /bin/sh


opts=-p:..

set -e
for f in *.nim
do
  (set -x; nim cc -r $opts $f)
done

# End
