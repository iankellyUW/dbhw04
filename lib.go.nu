  1: package main
  2: 
  3: import (
  4:     "context"
  5:     "fmt"
  6:     "io/ioutil"
  7:     "net/http"
  8:     "os"
  9: 
 10:     "github.com/jackc/pgx/v4/pgxpool"
 11:     "github.com/pschlump/godebug"
 12:     "github.com/pschlump/json"
 13:     "github.com/pschlump/uuid"
 14: )
 15: 
 16: // SetJsonHdr will set a content-type header to "application/json; charset=utf-8"
 17: func SetJsonHdr(www http.ResponseWriter, req *http.Request) {
 18:     www.Header().Set("Content-Type", "application/json; charset=utf-8")
 19: 
 20: }
 21: 
 22: // EmptyDflt if s is empty, then return d.  Creates a default value for parametrs
 23: func EmptyDflt(s, d string) string {
 24:     if s == "" {
 25:         return d
 26:     }
 27:     return s
 28: }
 29: 
 30: // ReadJson read in a JSON file into a go data structure.
 31: func ReadJson(fn string, x interface{}) (err error) {
 32:     var buf []byte
 33:     buf, err = ioutil.ReadFile(fn)
 34:     if err != nil {
 35:         return
 36:     }
 37:     err = json.Unmarshal(buf, x)
 38:     return
 39: }
 40: 
 41: // ConnectToDb creates a global that is used to connect to the PG database.
 42: // You have to have XXX setup as an environment variable first. (See setup.sh)
 43: 
 44: func ConnectToDb() {
 45:     ctx = context.Background()
 46:     constr := os.Getenv("DATABASE_URL")
 47:     var err error
 48:     // func Connect(ctx context.Context, connString string) (*Pool, error)
 49:     conn, err = pgxpool.Connect(ctx, constr)
 50:     if err != nil {
 51:         fmt.Fprintf(os.Stderr, "Unable to connect to database: %v connetion string [%s]\n", err, constr)
 52:         os.Exit(1)
 53:     }
 54: }
 55: 
 56: // DisConnectToDb() closes connection to databse.
 57: func DisConnectToDb() {
 58:     conn.Close()
 59: }
 60: 
 61: // GenUUID generates a UUID and returns it.
 62: func GenUUID() string {
 63:     newUUID, _ := uuid.NewV4() // Intentionally ignore errors - function will never return any.
 64:     return newUUID.String()
 65: }
 66: 
 67: // SVar return the JSON encoded version of the data.
 68: func SVar(v interface{}) string {
 69:     s, err := json.Marshal(v)
 70:     // s, err := json.MarshalIndent ( v, "", "\t" )
 71:     if err != nil {
 72:         return fmt.Sprintf("Error:%s", err)
 73:     } else {
 74:         return string(s)
 75:     }
 76: }
 77: 
 78: // StatusSuccess prepends to a JSON return value with a status:success.
 79: // This will also set the "Content-Type" to "application/json; charset=utf-8".
 80: func StatusSuccess(s string, www http.ResponseWriter, req *http.Request) string {
 81:     SetJsonHdr(www, req)
 82:     return `{"status":"success","data":` + s + "}\n"
 83: }
 84: 
 85: // SVarI return the JSON encoded version of the data with tab indentation.
 86: func SVarI(v interface{}) string {
 87:     // s, err := json.Marshal ( v )
 88:     s, err := json.MarshalIndent(v, "", "\t")
 89:     if err != nil {
 90:         return fmt.Sprintf("Error:%s", err)
 91:     } else {
 92:         return string(s)
 93:     }
 94: }
 95: 
 96: // RequiredParam will generate an error and a log entry for a missing value parameter.
 97: // It is assuemd that missing values are empty strings.  The parameters are specifed
 98: // as paris of name, then value.
 99: func RequiredParam(www http.ResponseWriter, req *http.Request, pp ...string) error {
100:     for i := 0; i < len(pp); i += 2 {
101:         name := pp[i]
102:         val := ""
103:         if i+1 < len(pp) {
104:             val = pp[i+1]
105:         } else {
106:             fmt.Fprintf(os.Stderr, "Invali call to RequiredParam - params should be pairs, missing one - odd number. [%s], at:%s\n", pp, godebug.LF(2))
107:             os.Exit(1)
108:         }
109:         if val == "" {
110:             LogParamError(www, req, name, "Missing Required Parameter")
111:             return fmt.Errorf("Missing Required Parameter")
112:         }
113:     }
114:     return nil
115: }
116: 
117: // GetParam will return the value for a named parameter from either a GET or a POST
118: // request.  It is not a GET or POST then an empty string is returned.
119: func GetParam(name string, www http.ResponseWriter, req *http.Request) (val string) {
120:     if req.Method == "GET" {
121:         val = req.URL.Query().Get(name)
122:     } else if req.Method == "POST" {
123:         req.ParseForm()
124:         val = req.Form.Get(name)
125:     }
126:     return
127: }
