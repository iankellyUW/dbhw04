  1: 
  2: INSERT INTO i_issue (
  3:     id,
  4:     title,    
  5:     body,                
  6:     state_id,         
  7:     severity_id 
  8: ) values 
  9:     ( 'adcc6ae9-a1db-456a-aa49-427a7111c93e', 'Sample Issue 1', 'This is a sample of an issue', 6, 2 ),
 10:     ( '2de76413-d746-4941-886a-a8ef99255956', 'Sample Issue 2', 'This is a 2nd Samle, sample of an issue', 1, 1 )
 11: ;
 12: 
 13: INSERT INTO i_note (
 14:     id,
 15:     issue_id,
 16:     title,
 17:     body 
 18: ) values    
 19:     ( '819c288e-966e-4cfd-a079-c1c10ad23dfa', 'adcc6ae9-a1db-456a-aa49-427a7111c93e', 'Note 1 on Issue 1', 'Body of Note 1' )_,
 20:     ( 'fc9fb22c-d80e-433f-8510-65fb524d02d8', 'adcc6ae9-a1db-456a-aa49-427a7111c93e', 'Note 2 on Issue 1 John Smith is an Englisman', 'John Smith Speeks English' )
 21: ;
 22: 
