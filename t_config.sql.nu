  1: 
  2: --        cur.execute('SELECT value FROM i_config where name = \'language\'')
  3: --    return run_select ( "SELECT * FROM i_issue_st_sv where words @@ to_tsquery('{}'::regconfig,%(kw)s)".format(lang), { "kw":kw[0] } )
  4: 
  5: SELECT value FROM i_config where name = 'language';
  6: SELECT * FROM i_issue_st_sv where words @@ to_tsquery('English'::regconfig,'body');
