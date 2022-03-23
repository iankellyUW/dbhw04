CREATE unique index i_state_u1 on i_state ( state );
CREATE unique index i_severity_u1 on i_severity ( severity );

INSERT INTO i_state ( id, state ) values
	( 1, 'Created' ),
	( 2, 'Verified' ),
	( 3, 'In Progress' ),
	( 4, 'Development Complete' ),
	( 5, 'Unit Test' ),
	( 6, 'Integration Test' ),
	( 7, 'Tests Passed' ),
	( 8, 'Documentation' ),
	( 9, 'Deployed' ),
	( 10, 'Closed' ),
	( 11, 'Deleted' )
;
ALTER SEQUENCE i_state_id_seq RESTART WITH 12;

INSERT INTO i_severity ( id, severity ) values
	( 1, 'Unknown' ),
	( 2, 'Ignore' ),
	( 3, 'Minor' ),
	( 4, 'Documentation Error' ),
	( 6, 'Code Chagne' ),
	( 7, 'User Interface Change' ),
	( 8, 'Severe - System down' ),
	( 9, 'Critial - System down' )
;
ALTER SEQUENCE i_severity_id_seq RESTART WITH 10;

insert into i_config ( name, value ) values 
	( 'language', 'english' )
;

CREATE UNIQUE INDEX i_config_p1 on i_config ( name );
