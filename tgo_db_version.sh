#!/bin/bash

mkdir -p x
cd x

wget -o db-version.err -O db-version.out 'http://127.0.0.1:12138/api/v1/db-version'
if grep PostgreSQL db-version.out >/dev/null ; then
	echo PASS
	exit 0
fi

echo FAILED
exit 0
