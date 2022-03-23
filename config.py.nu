  1: #!/home/pschlump/anaconda3/bin/python
  2: 
  3: from configparser import ConfigParser
  4: import psycopg2
  5: import os
  6: 
  7: # get env
  8: #  os.getenv('KEY_THAT_MIGHT_EXIST', default_value) 
  9: 
 10: def config(filename='database.ini', section='postgresql'):
 11:     # create a parser
 12:     parser = ConfigParser()
 13:     # read config file
 14:     parser.read(filename)
 15: 
 16:     # get section, default to postgresql
 17:     db = {}
 18:     if parser.has_section(section):
 19:         params = parser.items(section)
 20:         for param in params:
 21:             db[param[0]] = param[1]
 22:             # print ( "::: Config: key={} value={}".format ( param[0], param[1] ) )
 23:             if len( param[1] ) > 4 :
 24:                 # print ( ":::: Config: length engough" )
 25:                 if param[1][0:4] == "ENV$" :
 26:                     # print ( "::::: Config: starts with ENV$" )
 27:                     name = param[1][4:]
 28:                     # print ( "::::: Config: name=->{}<-".format(name) )
 29:                     s = os.getenv( name )
 30:                     # print ( "::::: Config: s=->{}<-".format(s) )
 31:                     db[param[0]] = s
 32:     else:
 33:         raise Exception('Section {0} not found in the {1} file'.format(section, filename))
 34: 
 35:     return db
 36: 
 37: 
 38: 
 39: 
 40: 
 41: db_conn = None
 42: db_connection_info = None
 43: 
 44: def test_connect():
 45:     """ Connect to the PostgreSQL database server """
 46:     global db_conn
 47:     global db_connection_info
 48:     db_conn = None
 49:     param = None
 50:     try:
 51:         db_connection_info = config() # read database connection parameters
 52:         # print ( "db_connetion_info = {}".format(db_connection_info ) )
 53: 
 54:         # connect to the PostgreSQL server
 55:         print('Connecting to the PostgreSQL database...')
 56:         db_conn = psycopg2.connect(**db_connection_info)
 57:         
 58:         cur = db_conn.cursor()              
 59:         cur.execute('SELECT 123 as "x"')
 60:         t = cur.fetchone()
 61:         # print ( "t={}".format(t) )
 62:         cur.close()
 63:        
 64:     except (Exception, psycopg2.DatabaseError) as error:
 65:         print(error)
 66: 
 67: if __name__ == '__main__':
 68:     test_connect()
