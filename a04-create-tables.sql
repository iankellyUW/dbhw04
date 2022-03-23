CREATE TABLE IF NOT EXISTS i_issue(
    id UUID PRIMARY KEY,
    title TEXT,
    body TEXT,
    state_id INT,
    severity_id INT,
    workds TSVECTOR,
    updated TIMESTAMP,
    created TIMESTAMP
);

CREATE TABLE IF NOT EXISTS i_state(
    id SERIAL PRIMARY KEY,
    state TEXT
);

CREATE TABLE IF NOT EXISTS i_severity(
    id SERIAL PRIMARY KEY,
    severity TEXT
);

CREATE TABLE IF NOT EXISTS i_note(
    id UUID PRIMARY KEY,
    title TEXT,
    body TEXT,
    issue_id UUID,
    seq SERIAL,
    words TSVECTOR,
    updated TIMESTAMP,
    created TIMESTAMP
);

CREATE TABLE IF NOT EXISTS i_config(
    id SERIAL PRIMARY KEY,
    name TEXT,
    value TEXT
);
    
ALTER TABLE i_issue
    ADD CONSTRAINT fk_issue_state
        FOREIGN KEY (state_id) REFERENCES i_state(id);
        
ALTER TABLE i_issue
    ADD CONSTRAINT fk_issue_severity
        FOREIGN KEY (severity_id) REFERENCES i_severity(id);
        
ALTER TABLE i_note
    ADD CONSTRAINT fk_note_issue
        FOREIGN KEY (issue_id) REFERENCES i_issue(id);
    
    
    
