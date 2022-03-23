#!/bin/bash

mkdir -p x
cd x

# http.Handle("/api/v1/global-data.js", http.HandlerFunc(ResponceHandlerApiV1GlobalData))
wget -o db-global_data.err -O db-global_data.out 'http://127.0.0.1:12138/api/v1/global-data.js'

if diff db-global_data.out ../ref ; then
	echo PASS
	exit 0
else
	echo FAILED - output dit not match
	exit 1
fi
