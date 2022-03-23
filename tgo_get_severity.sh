#!/bin/bash

mkdir -p x
cd x

wget -o get-severity.err -O get-severity.out 'http://127.0.0.1:12138/api/v1/get-severity'

if grep success get-severity.out >/dev/null ; then
	if diff get-severity.out ../ref ; then
		:
	else
		echo FAILED - output dit not match
		exit 1
	fi
	echo PASS
	exit 0
fi

echo FAILED
exit 1

