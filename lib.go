package main

import (
	"context"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"

	"github.com/jackc/pgx/v4/pgxpool"
	"github.com/pschlump/godebug"
	"github.com/pschlump/json"
	"github.com/pschlump/uuid"
)

// SetJsonHdr will set a content-type header to "application/json; charset=utf-8"
func SetJsonHdr(www http.ResponseWriter, req *http.Request) {
	www.Header().Set("Content-Type", "application/json; charset=utf-8")

}

// EmptyDflt if s is empty, then return d.  Creates a default value for parametrs
func EmptyDflt(s, d string) string {
	if s == "" {
		return d
	}
	return s
}

// ReadJson read in a JSON file into a go data structure.
func ReadJson(fn string, x interface{}) (err error) {
	var buf []byte
	buf, err = ioutil.ReadFile(fn)
	if err != nil {
		return
	}
	err = json.Unmarshal(buf, x)
	return
}

// ConnectToDb creates a global that is used to connect to the PG database.
// You have to have XXX setup as an environment variable first. (See setup.sh)

func ConnectToDb() {
	ctx = context.Background()
	constr := os.Getenv("DATABASE_URL")
	var err error
	// func Connect(ctx context.Context, connString string) (*Pool, error)
	conn, err = pgxpool.Connect(ctx, constr)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Unable to connect to database: %v connetion string [%s]\n", err, constr)
		os.Exit(1)
	}
}

// DisConnectToDb() closes connection to databse.
func DisConnectToDb() {
	conn.Close()
}

// GenUUID generates a UUID and returns it.
func GenUUID() string {
	newUUID, _ := uuid.NewV4() // Intentionally ignore errors - function will never return any.
	return newUUID.String()
}

// SVar return the JSON encoded version of the data.
func SVar(v interface{}) string {
	s, err := json.Marshal(v)
	// s, err := json.MarshalIndent ( v, "", "\t" )
	if err != nil {
		return fmt.Sprintf("Error:%s", err)
	} else {
		return string(s)
	}
}

// StatusSuccess prepends to a JSON return value with a status:success.
// This will also set the "Content-Type" to "application/json; charset=utf-8".
func StatusSuccess(s string, www http.ResponseWriter, req *http.Request) string {
	SetJsonHdr(www, req)
	return `{"status":"success","data":` + s + "}\n"
}

// SVarI return the JSON encoded version of the data with tab indentation.
func SVarI(v interface{}) string {
	// s, err := json.Marshal ( v )
	s, err := json.MarshalIndent(v, "", "\t")
	if err != nil {
		return fmt.Sprintf("Error:%s", err)
	} else {
		return string(s)
	}
}

// RequiredParam will generate an error and a log entry for a missing value parameter.
// It is assuemd that missing values are empty strings.  The parameters are specifed
// as paris of name, then value.
func RequiredParam(www http.ResponseWriter, req *http.Request, pp ...string) error {
	for i := 0; i < len(pp); i += 2 {
		name := pp[i]
		val := ""
		if i+1 < len(pp) {
			val = pp[i+1]
		} else {
			fmt.Fprintf(os.Stderr, "Invali call to RequiredParam - params should be pairs, missing one - odd number. [%s], at:%s\n", pp, godebug.LF(2))
			os.Exit(1)
		}
		if val == "" {
			LogParamError(www, req, name, "Missing Required Parameter")
			return fmt.Errorf("Missing Required Parameter")
		}
	}
	return nil
}

// GetParam will return the value for a named parameter from either a GET or a POST
// request.  It is not a GET or POST then an empty string is returned.
func GetParam(name string, www http.ResponseWriter, req *http.Request) (val string) {
	if req.Method == "GET" {
		val = req.URL.Query().Get(name)
	} else if req.Method == "POST" {
		req.ParseForm()
		val = req.Form.Get(name)
	}
	return
}
