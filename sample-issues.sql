


insert into "i_issue" ( "body", "created", "id", "severity_id", "state_id", "title" ) values ( 'Missing states. 
Missing Severity.
', '2021-01-03T14:34:18.84727+0000', 'b2a06795-ee6a-4a0d-ee74-bf96c5ca81ab', '1', '1', 'issue tracking is lacking a state of "ignore" in severity.' );
insert into "i_issue" ( "body", "created", "id", "severity_id", "state_id", "title" ) values ( 'When a student logs in the tool must connect to the correct postgresql database for that strudent.
Currently it is only connected to the "learndb" database.

Database connections must be cached.   
Sufficient number of connections must be provided for in the database configuration for 100 students.
Connections per-strudent should have a "time-out" where they are closed after 2 hours of idle time.
This means that every use on a connection has to traced for time.
', '2021-01-03T12:17:40.6874+0000', 'df4c0f1a-8606-42b2-8999-c4977a8d1daf', '4', '2', 'learn-db: connection to correct PosgreSQL database.' );
insert into "i_issue" ( "body", "created", "id", "severity_id", "state_id", "title" ) values ( 'pass', '2021-02-21T22:31:08.90619+0000', '2c4043f4-65cf-4f64-89f0-aa3e186c4a92', '1', '1', 'bob' );
insert into "i_issue" ( "body", "created", "id", "severity_id", "state_id", "title" ) values ( 'My Body', '2021-03-18T10:29:36.93826+0000', '55cb20b9-0ead-45fd-85ca-23dc3c7d331c', '3', '1', 'ATitle' );
insert into "i_issue" ( "body", "created", "id", "severity_id", "state_id", "title" ) values ( 'My Body', '2021-03-18T10:33:26.62774+0000', 'a270851a-de6c-4a4f-b533-9146f8186d0e', '3', '1', 'ATitle' );
insert into "i_issue" ( "body", "created", "id", "severity_id", "state_id", "title" ) values ( 'My Body', '2021-03-18T10:34:07.4062+0000', '9271fe73-afb8-4690-a3c5-30318879a4f5', '3', '1', 'ATitle' );
insert into "i_issue" ( "body", "created", "id", "severity_id", "state_id", "title" ) values ( 'Bod', '2021-03-18T11:30:37.74793+0000', '40e03b7b-258e-40d1-833b-cbcb34570447', '1', '1', 'AAA' );
insert into "i_issue" ( "body", "created", "id", "severity_id", "state_id", "title" ) values ( 'My Body', '2021-03-18T11:34:15.77678+0000', '9d6d795c-278d-4ff7-9f83-306c580d5948', '3', '1', 'AibTitle' );
insert into "i_issue" ( "body", "created", "id", "severity_id", "state_id", "title" ) values ( 'My Body', '2021-03-18T11:43:57.38853+0000', '76941ec5-7566-4299-ab18-f5a0f1bd9544', '3', '1', 'AibTitle' );



insert into "i_note" ( "body", "created", "id", "issue_id", "seq", "title", "updated" ) values ( '8888', '2021-01-02T16:05:40.72861+0000', '6ba7bfe9-3575-4fad-a998-0aa1044fcb26', '2de76413-d746-4941-886a-a8ef99255956', '3', '888', '2021-01-02T16:06:03.3957+0000' );
insert into "i_note" ( "body", "created", "id", "issue_id", "seq", "title" ) values ( 'iiii', '2021-01-02T16:06:03.4+0000', '727c7d7a-9548-4b3b-988f-1fe91e262b0e', '2de76413-d746-4941-886a-a8ef99255956', '4', 'iii' );


