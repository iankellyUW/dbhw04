package main

// Copyright (c) Philip Schlump, 2014.
// MIT Licensed.

import (
	"fmt"
	"net/http"
	"time"
)

type LoggingResponceWriter struct {
	http.ResponseWriter
	HTTPStatus   int
	ResponseSize int
}

func (w *LoggingResponceWriter) WriteHeader(status int) {
	w.ResponseWriter.WriteHeader(status)
	w.HTTPStatus = status
}

func (w *LoggingResponceWriter) Flush() {
	z := w.ResponseWriter
	if f, ok := z.(http.Flusher); ok {
		f.Flush()
	}
}

func (w *LoggingResponceWriter) CloseNotify() <-chan bool {
	z := w.ResponseWriter
	return z.(http.CloseNotifier).CloseNotify()
}

func (w *LoggingResponceWriter) Write(b []byte) (int, error) {
	w.ResponseSize = len(b)
	if w.HTTPStatus == 0 {
		w.HTTPStatus = 200
	}
	return w.ResponseWriter.Write(b)
}

func ApacheLogger(handler http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		middleware := LoggingResponceWriter{w, 0, 0}
		t := time.Now()

		handler.ServeHTTP(&middleware, r)
		LogApacheReq(
			fmt.Sprintf("HTTP - %s - - %s \"%s %s %s\" %d %d %s %dus\n",
				r.RemoteAddr,
				t.Format("02/Jan/2006:15:04:05 -0700"),
				r.Method,
				r.URL.Path,
				r.Proto,
				middleware.HTTPStatus,
				middleware.ResponseSize,
				r.UserAgent(),
				time.Since(t),
			),
		)
	})
}
