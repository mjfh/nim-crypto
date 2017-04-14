#! /bin/sh

dir=${1:-tools/sub}

mkdir -p $dir

(
	set -x
	cd $dir

	# See also http://nim-lang.org/download.html
	git clone https://github.com/nim-lang/nim
	cd nim
	git clone --depth 1 https://github.com/nim-lang/csources
	(cd csources && sh build.sh)
	./bin/nim c koch
	./koch boot -d:release
	./koch nimble
	./bin/nim c -d:release -o:bin/nimgrep tools/nimgrep.nim
	chmod +x ./bin/nim*
)

# End
