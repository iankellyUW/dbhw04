  1: package main
  2: 
  3: import (
  4:     "fmt"
  5:     "net/http"
  6:     "os"
  7: 
  8:     "github.com/pschlump/godebug"
  9:     "go.uber.org/zap"
 10:     "go.uber.org/zap/zapcore"
 11: )
 12: 
 13: // LogInit initializs zap loging to send data to a file and to the console.
 14: func LogInit(d bool, f *os.File) *zap.SugaredLogger {
 15: 
 16:     pe := zap.NewProductionEncoderConfig()
 17: 
 18:     fileEncoder := zapcore.NewJSONEncoder(pe)
 19: 
 20:     pe.EncodeTime = zapcore.ISO8601TimeEncoder // The encoder can be customized for each output
 21:     consoleEncoder := zapcore.NewConsoleEncoder(pe)
 22: 
 23:     level := zap.InfoLevel
 24:     if d {
 25:         level = zap.DebugLevel
 26:     }
 27: 
 28:     core := zapcore.NewTee(
 29:         zapcore.NewCore(fileEncoder, zapcore.AddSync(f), level),
 30:         zapcore.NewCore(consoleEncoder, zapcore.AddSync(os.Stdout), level),
 31:     )
 32: 
 33:     l := zap.New(core) // Creating the logger
 34: 
 35:     return l.Sugar()
 36: }
 37: 
 38: // Log in apache format (inside a string for zap)
 39: func LogApacheReq(data string) {
 40:     sugar.Infow("ApacheLog",
 41:         "apache", data,
 42:     )
 43: }
 44: 
 45: // Log a SQL error.
 46: func LogSQLError(www http.ResponseWriter, req *http.Request, stmt string, err error, data ...interface{}) {
 47:     sugar.Infow("SQLError",
 48:         "url", req.RequestURI,
 49:         "method", req.Method,
 50:         "stmt", stmt,
 51:         "error", fmt.Sprintf("%s", err),
 52:         "data", SVar(data),
 53:         "AT", godebug.LF(2),
 54:     )
 55:     SetJsonHdr(www, req)
 56:     www.WriteHeader(http.StatusBadRequest) // 400
 57:     fmt.Fprintf(www, `{"status":"error","msg":%q}`+"\n", "Database Error")
 58: }
 59: 
 60: // Log an invalid parameter error.
 61: func LogParamError(www http.ResponseWriter, req *http.Request, pn, msg string) {
 62:     sugar.Infow("InvalidParameter",
 63:         "url", req.RequestURI,
 64:         "method", req.Method,
 65:         "param_name", pn,
 66:         "msg", msg,
 67:         "AT", godebug.LF(2),
 68:     )
 69:     SetJsonHdr(www, req)
 70:     www.WriteHeader(http.StatusNotAcceptable) // 406
 71:     fmt.Fprintf(www, `{"status":"error","msg":%q}`+"\n", msg)
 72: }
 73: 
 74: // Log an invalid method.
 75: func LogInvalidMethodError(www http.ResponseWriter, req *http.Request) {
 76:     sugar.Infow("InvalidMethod",
 77:         "url", req.RequestURI,
 78:         "method", req.Method,
 79:         "msg", "Invalid Method",
 80:         "AT", godebug.LF(2),
 81:     )
 82:     SetJsonHdr(www, req)
 83:     www.WriteHeader(http.StatusMethodNotAllowed) // 405
 84:     fmt.Fprintf(www, `{"status":"error","msg":%q}`+"\n", "Invalid Method")
 85: }
