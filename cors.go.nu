  1: package main
  2: 
  3: // Copyright (c) Philip Schlump, 2015.
  4: // MIT Licensed.
  5: 
  6: import (
  7:     "fmt"
  8:     "net/http"
  9:     "os"
 10: )
 11: 
 12: type CORSResponceWriter struct {
 13:     http.ResponseWriter
 14:     HTTPStatus int
 15: }
 16: 
 17: func (www *CORSResponceWriter) WriteHeader(status int) {
 18:     www.ResponseWriter.WriteHeader(status)
 19:     www.HTTPStatus = status
 20: }
 21: 
 22: func (www *CORSResponceWriter) Flush() {
 23:     z := www.ResponseWriter
 24:     if f, ok := z.(http.Flusher); ok {
 25:         f.Flush()
 26:     }
 27: }
 28: 
 29: func (www *CORSResponceWriter) CloseNotify() <-chan bool {
 30:     z := www.ResponseWriter
 31:     return z.(http.CloseNotifier).CloseNotify()
 32: }
 33: 
 34: func (www *CORSResponceWriter) Write(b []byte) (int, error) {
 35:     if www.HTTPStatus == 0 {
 36:         www.HTTPStatus = 200
 37:     }
 38:     return www.ResponseWriter.Write(b)
 39: }
 40: 
 41: func CORSMiddleware(handler http.Handler) http.Handler {
 42:     return http.HandlerFunc(func(www http.ResponseWriter, req *http.Request) {
 43:         middleware := CORSResponceWriter{www, 0}
 44:         if req.Method == "OPTIONS" {
 45:             www.Header().Set("Access-Control-Allow-Origin", "*")
 46:             www.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
 47:             www.Header().Set("Access-Control-Allow-Headers", "Origin, Accept, Content-Type, X-Requested-With, X-CSRF-Token")
 48:             fmt.Fprintf(os.Stderr, "Caught OPTIONS in middleware\n")
 49:         } else {
 50:             www.Header().Set("Access-Control-Allow-Origin", "*")
 51:             www.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
 52:             www.Header().Set("Access-Control-Allow-Headers", "Origin, Accept, Content-Type, X-Requested-With, X-CSRF-Token")
 53:             handler.ServeHTTP(&middleware, req)
 54:         }
 55:     })
 56: }
