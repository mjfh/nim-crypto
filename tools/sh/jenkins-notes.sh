#! /bin/sh
#
# helper
#

# Update local repo
git fetch -f origin refs/notes/*:refs/notes/*

# Log ...
git log -p notes/jenkins

