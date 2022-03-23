package main

import (
	"fmt"
	"net/http"
	"os"

	"github.com/pschlump/godebug"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

// LogInit initializs zap loging to send data to a file and to the console.
func LogInit(d bool, f *os.File) *zap.SugaredLogger {

	pe := zap.NewProductionEncoderConfig()

	fileEncoder := zapcore.NewJSONEncoder(pe)

	pe.EncodeTime = zapcore.ISO8601TimeEncoder // The encoder can be customized for each output
	consoleEncoder := zapcore.NewConsoleEncoder(pe)

	level := zap.InfoLevel
	if d {
		level = zap.DebugLevel
	}

	core := zapcore.NewTee(
		zapcore.NewCore(fileEncoder, zapcore.AddSync(f), level),
		zapcore.NewCore(consoleEncoder, zapcore.AddSync(os.Stdout), level),
	)

	l := zap.New(core) // Creating the logger

	return l.Sugar()
}

// Log in apache format (inside a string for zap)
func LogApacheReq(data string) {
	sugar.Infow("ApacheLog",
		"apache", data,
	)
}

// Log a SQL error.
func LogSQLError(www http.ResponseWriter, req *http.Request, stmt string, err error, data ...interface{}) {
	sugar.Infow("SQLError",
		"url", req.RequestURI,
		"method", req.Method,
		"stmt", stmt,
		"error", fmt.Sprintf("%s", err),
		"data", SVar(data),
		"AT", godebug.LF(2),
	)
	SetJsonHdr(www, req)
	www.WriteHeader(http.StatusBadRequest) // 400
	fmt.Fprintf(www, `{"status":"error","msg":%q}`+"\n", "Database Error")
}

// Log an invalid parameter error.
func LogParamError(www http.ResponseWriter, req *http.Request, pn, msg string) {
	sugar.Infow("InvalidParameter",
		"url", req.RequestURI,
		"method", req.Method,
		"param_name", pn,
		"msg", msg,
		"AT", godebug.LF(2),
	)
	SetJsonHdr(www, req)
	www.WriteHeader(http.StatusNotAcceptable) // 406
	fmt.Fprintf(www, `{"status":"error","msg":%q}`+"\n", msg)
}

// Log an invalid method.
func LogInvalidMethodError(www http.ResponseWriter, req *http.Request) {
	sugar.Infow("InvalidMethod",
		"url", req.RequestURI,
		"method", req.Method,
		"msg", "Invalid Method",
		"AT", godebug.LF(2),
	)
	SetJsonHdr(www, req)
	www.WriteHeader(http.StatusMethodNotAllowed) // 405
	fmt.Fprintf(www, `{"status":"error","msg":%q}`+"\n", "Invalid Method")
}
