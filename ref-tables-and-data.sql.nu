  1: 
  2: drop table if exists i_state cascade;
  3: drop table if exists i_severity cascade;
  4: 
  5: CREATE table if not exists i_state (
  6:     id serial not null primary key,
  7:     state text not null
  8: );
  9: CREATE unique index i_state_u1 on i_state ( state );
 10: 
 11: CREATE table if not exists i_severity (
 12:     id serial not null primary key,
 13:     severity text not null
 14: );
 15: CREATE unique index i_severity_u1 on i_severity ( severity );
 16: 
 17: ALTER TABLE i_issue
 18:     ADD CONSTRAINT i_issue_fk2
 19:     FOREIGN KEY (state_id)
 20:     REFERENCES i_state (id)
 21: ;
 22: ALTER TABLE i_issue
 23:     ADD CONSTRAINT i_issue_fk3
 24:     FOREIGN KEY (severity_id)
 25:     REFERENCES i_severity (id)
 26: ;
 27: 
 28: INSERT INTO i_state ( id, state ) values
 29:     ( 1, 'Created' ),
 30:     ( 2, 'Verified' ),
 31:     ( 3, 'In Progress' ),
 32:     ( 4, 'Development Complete' ),
 33:     ( 5, 'Unit Test' ),
 34:     ( 6, 'Integration Test' ),
 35:     ( 7, 'Tests Passed' ),
 36:     ( 8, 'Documentation' ),
 37:     ( 9, 'Deployed' ),
 38:     ( 10, 'Closed' ),
 39:     ( 11, 'Deleted' )
 40: ;
 41: ALTER SEQUENCE i_state_id_seq RESTART WITH 12;
 42: 
 43: INSERT INTO i_severity ( id, severity ) values
 44:     ( 1, 'Unknown' ),
 45:     ( 2, 'Ignore' ),
 46:     ( 3, 'Minor' ),
 47:     ( 4, 'Documentation Error' ),
 48:     ( 6, 'Code Chagne' ),
 49:     ( 7, 'User Interface Change' ),
 50:     ( 8, 'Severe - System down' ),
 51:     ( 9, 'Critial - System down' )
 52: ;
 53: ALTER SEQUENCE i_severity_id_seq RESTART WITH 10;
 54: 
 55: insert into i_config ( name, value ) values 
 56:     ( 'language', 'english' )
 57: ;
 58: 
 59: 
 60: 
 61: ------------------------------------------------------------------------------------------------------------
 62: -- Configuration Table
 63: ------------------------------------------------------------------------------------------------------------
 64: 
 65: CREATE table if not exists i_config (
 66:     id                     serial not null primary key,
 67:     name                 text not null,
 68:     value                 text not null
 69: );
 70: 
 71: CREATE UNIQUE INDEX i_config_p1 on i_config ( name );
