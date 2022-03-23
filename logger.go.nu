  1: package main
  2: 
  3: // Copyright (c) Philip Schlump, 2014.
  4: // MIT Licensed.
  5: 
  6: import (
  7:     "fmt"
  8:     "net/http"
  9:     "time"
 10: )
 11: 
 12: type LoggingResponceWriter struct {
 13:     http.ResponseWriter
 14:     HTTPStatus   int
 15:     ResponseSize int
 16: }
 17: 
 18: func (w *LoggingResponceWriter) WriteHeader(status int) {
 19:     w.ResponseWriter.WriteHeader(status)
 20:     w.HTTPStatus = status
 21: }
 22: 
 23: func (w *LoggingResponceWriter) Flush() {
 24:     z := w.ResponseWriter
 25:     if f, ok := z.(http.Flusher); ok {
 26:         f.Flush()
 27:     }
 28: }
 29: 
 30: func (w *LoggingResponceWriter) CloseNotify() <-chan bool {
 31:     z := w.ResponseWriter
 32:     return z.(http.CloseNotifier).CloseNotify()
 33: }
 34: 
 35: func (w *LoggingResponceWriter) Write(b []byte) (int, error) {
 36:     w.ResponseSize = len(b)
 37:     if w.HTTPStatus == 0 {
 38:         w.HTTPStatus = 200
 39:     }
 40:     return w.ResponseWriter.Write(b)
 41: }
 42: 
 43: func ApacheLogger(handler http.Handler) http.Handler {
 44:     return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
 45:         middleware := LoggingResponceWriter{w, 0, 0}
 46:         t := time.Now()
 47: 
 48:         handler.ServeHTTP(&middleware, r)
 49:         LogApacheReq(
 50:             fmt.Sprintf("HTTP - %s - - %s \"%s %s %s\" %d %d %s %dus\n",
 51:                 r.RemoteAddr,
 52:                 t.Format("02/Jan/2006:15:04:05 -0700"),
 53:                 r.Method,
 54:                 r.URL.Path,
 55:                 r.Proto,
 56:                 middleware.HTTPStatus,
 57:                 middleware.ResponseSize,
 58:                 r.UserAgent(),
 59:                 time.Since(t),
 60:             ),
 61:         )
 62:     })
 63: }
