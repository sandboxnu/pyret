#! /usr/bin/env bash

for f in **/.examples-*.arr; do
  if pyret $f 2>&1 | grep -q 'compilation errors'; then
    echo
    echo ---------------
    echo Error in:
    cat $f
    echo
  fi
done
