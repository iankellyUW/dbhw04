#!/bin/bash

mkdir -p x
cd x

wget -o get-state.err -O get-state.out 'http://127.0.0.1:12138/api/v1/get-state'

if grep success get-state.out >/dev/null ; then
	if diff get-state.out ../ref ; then
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

