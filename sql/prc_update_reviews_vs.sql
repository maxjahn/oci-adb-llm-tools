CREATE OR REPLACE PROCEDURE prc_update_reviews_vs AS
BEGIN
    DECLARE
        v_code  NUMBER;
        v_errm  VARCHAR2(64);
        v_embedding_model VARCHAR2(64);
  
  BEGIN

    SELECT value_text INTO v_embedding_model FROM CONFIG_EMBEDDINGS where config = 'EMBEDDING_MODEL';


    INSERT INTO  reviews_vs (document_id, document_name, text, metadata, embedding, embedding_model)
    SELECT r.id as document_id,
    r.name as document_name,
    '*Whisky Name: '||r.name ||'*\n' || JSON_VALUE(C.column_value, '$.chunk_data') AS text,
    json('{"document_id" : "' || r.id || '", "_rowid" : "' || r.rowid || '"}') as metadata,
    dbms_vector.utl_to_embedding(JSON_VALUE(C.column_value, '$.chunk_data'), json('{"provider":"database", "model":"' || v_embedding_model || '"}')) as embedding,
    v_embedding_model as embedding_model            
    FROM reviews r,
    dbms_vector.utl_to_chunks(r.description,
    JSON('{"by":"words",
            "max":"200",
            "overlap":"20",
            "split":"recursively",
            "normalize":"all"}')
        ) C
    where r.id in (select id from reviews rev where not exists (select 1 from reviews_vs where document_id = rev.id));

    EXCEPTION
        WHEN OTHERS THEN
            v_code := SQLCODE;
            v_errm := SUBSTR(SQLERRM, 1, 64);
            DBMS_OUTPUT.PUT_LINE('Error code ' || v_code || ': ' || v_errm);
    END;
    
    COMMIT;
END;
/




