#!/bin/bash

mkdir -p x
cd x

# http.Handle("/api/v1/search-keyword", http.HandlerFunc(ResponceHandlerApiV1SearchKeyword))
wget -o search-keyword.err -O search-keyword.out 'http://127.0.0.1:12138/api/v1/search-keyword?kw=body'

if grep success search-keyword.out >/dev/null ; then
	echo PASS
	exit 0
fi

echo FAILED
exit 1

