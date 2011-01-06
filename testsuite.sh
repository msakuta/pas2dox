#!/bin/bash
#
# Compiletime testing script for pas2dox
#   This script will test every *.pas file in the $TESTDIR directory
#   against corresponding *.cpp. If all tests pass the return value is 0.
# Invocation:
#   test.sh <pas2dox_executable>
#
# For every *.pas file if first line has the form of '{pas2dox <options> }'
#   - no spaces are allowed before or after curly braces - #  pas2dox will be
#   executed with <options> for that file.
# WARNING! Do not use {pas2dox -o} of the above comment, as it will
#   destroy current *.cpp files
#

TESTSDIR=TESTS

#------------------------------------------------------------------------------
if test "$1" == ""; then
  echo No executable given
  exit 1
fi

# get all *.pas files from test directory
files=$(ls $TESTSDIR/*.pas)
level=0;

for name1 in $files
do

# get options for current file
  opt=$(awk 'NR == 1 && /^{pas2dox .+}$/ {print substr($0, 10, length($0)-10)}' $name1)

# test the file
  if ! ($1 $opt $name1 | diff -b -c - $name1".cpp"); then
    level=1;
  fi
done

if test $level == 0; then
  echo All tests OK
else
  echo ---
  echo Some tests failed
fi

exit $level
