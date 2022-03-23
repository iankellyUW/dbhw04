
--        cur.execute('SELECT value FROM i_config where name = \'language\'')
--    return run_select ( "SELECT * FROM i_issue_st_sv where words @@ to_tsquery('{}'::regconfig,%(kw)s)".format(lang), { "kw":kw[0] } )

SELECT value FROM i_config where name = 'language';
SELECT * FROM i_issue_st_sv where words @@ to_tsquery('English'::regconfig,'body');
