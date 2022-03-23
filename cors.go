package main

// Copyright (c) Philip Schlump, 2015.
// MIT Licensed.

import (
	"fmt"
	"net/http"
	"os"
)

type CORSResponceWriter struct {
	http.ResponseWriter
	HTTPStatus int
}

func (www *CORSResponceWriter) WriteHeader(status int) {
	www.ResponseWriter.WriteHeader(status)
	www.HTTPStatus = status
}

func (www *CORSResponceWriter) Flush() {
	z := www.ResponseWriter
	if f, ok := z.(http.Flusher); ok {
		f.Flush()
	}
}

func (www *CORSResponceWriter) CloseNotify() <-chan bool {
	z := www.ResponseWriter
	return z.(http.CloseNotifier).CloseNotify()
}

func (www *CORSResponceWriter) Write(b []byte) (int, error) {
	if www.HTTPStatus == 0 {
		www.HTTPStatus = 200
	}
	return www.ResponseWriter.Write(b)
}

func CORSMiddleware(handler http.Handler) http.Handler {
	return http.HandlerFunc(func(www http.ResponseWriter, req *http.Request) {
		middleware := CORSResponceWriter{www, 0}
		if req.Method == "OPTIONS" {
			www.Header().Set("Access-Control-Allow-Origin", "*")
			www.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
			www.Header().Set("Access-Control-Allow-Headers", "Origin, Accept, Content-Type, X-Requested-With, X-CSRF-Token")
			fmt.Fprintf(os.Stderr, "Caught OPTIONS in middleware\n")
		} else {
			www.Header().Set("Access-Control-Allow-Origin", "*")
			www.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
			www.Header().Set("Access-Control-Allow-Headers", "Origin, Accept, Content-Type, X-Requested-With, X-CSRF-Token")
			handler.ServeHTTP(&middleware, req)
		}
	})
}
