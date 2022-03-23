#!/home/pschlump/anaconda3/bin/python

from configparser import ConfigParser
import psycopg2
import os

# get env
#  os.getenv('KEY_THAT_MIGHT_EXIST', default_value) 

def config(filename='database.ini', section='postgresql'):
    # create a parser
    parser = ConfigParser()
    # read config file
    parser.read(filename)

    # get section, default to postgresql
    db = {}
    if parser.has_section(section):
        params = parser.items(section)
        for param in params:
            db[param[0]] = param[1]
            # print ( "::: Config: key={} value={}".format ( param[0], param[1] ) )
            if len( param[1] ) > 4 :
                # print ( ":::: Config: length engough" )
                if param[1][0:4] == "ENV$" :
                    # print ( "::::: Config: starts with ENV$" )
                    name = param[1][4:]
                    # print ( "::::: Config: name=->{}<-".format(name) )
                    s = os.getenv( name )
                    # print ( "::::: Config: s=->{}<-".format(s) )
                    db[param[0]] = s
    else:
        raise Exception('Section {0} not found in the {1} file'.format(section, filename))

    return db





db_conn = None
db_connection_info = None

def test_connect():
    """ Connect to the PostgreSQL database server """
    global db_conn
    global db_connection_info
    db_conn = None
    param = None
    try:
        db_connection_info = config() # read database connection parameters
        # print ( "db_connetion_info = {}".format(db_connection_info ) )

        # connect to the PostgreSQL server
        print('Connecting to the PostgreSQL database...')
        db_conn = psycopg2.connect(**db_connection_info)
		
        cur = db_conn.cursor()              
        cur.execute('SELECT 123 as "x"')
        t = cur.fetchone()
        # print ( "t={}".format(t) )
        cur.close()
       
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)

if __name__ == '__main__':
    test_connect()
