#!/bin/bash

mkdir -p x
cd x

wget -o db-status.err -O db-status.out 'http://127.0.0.1:12138/api/v1/status'

if grep success db-status.out >/dev/null ; then
	echo PASS
	exit 0
fi

echo FAILED
exit 1

