#!/bin/bash

mkdir -p x
cd x

wget -o x404.err -O x404.out 'http://127.0.0.1:12138/api/v1/xyzzy'
if grep 404 x404.err >/dev/null 2>&1 ; then
	echo "PASS"
	exit 0
fi

echo "FAILED"
exit 1
