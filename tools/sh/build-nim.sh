#! /bin/sh

dir=${1:-tools/sub}

mkdir -p $dir

(
	set -e
	cd $dir

	# See also http://nim-lang.org/download.html
	test -d nim || git clone https://github.com/nim-lang/nim nim
	cd nim
	git pull

	# Update or new installation
	test \! -d csources || mv csources csources~

	set -x
	git clone --depth 1 https://github.com/nim-lang/csources
	(cd csources && sh build.sh)
	./bin/nim c koch
	./koch boot -d:release
	./koch nimble
	./bin/nim c -d:release -o:bin/nimgrep tools/nimgrep.nim || :
	find . -type d -name nimcache -print | xargs rm -rf
	rm -rf csources~
	chmod +x ./bin/nim*
)

# End
