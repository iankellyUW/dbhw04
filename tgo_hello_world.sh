#!/bin/bash

mkdir -p x
cd x

wget -o hello.err -O hello.out 'http://127.0.0.1:12138/api/v1/hello'
if grep Hello hello.out >/dev/null ; then
	echo PASS
	exit 0
fi

echo FAILED
exit 0
