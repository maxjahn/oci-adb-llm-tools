DECLARE

    v_index number := 0;
    v_step number := 50;
    v_upper_limit number := 2500;
    v_code  NUMBER;
    v_errm  VARCHAR2(64);
    v_embedding_model VARCHAR2(64);

BEGIN

    SELECT value_text INTO v_embedding_model FROM CONFIG_EMBEDDINGS where config = 'EMBEDDING_MODEL';

    delete from reviews_vs vs where vs.document_id between v_index and v_upper_limit;
    commit;
    
    WHILE v_index < v_upper_limit LOOP

        DBMS_OUTPUT.PUT_LINE('creating embeddings for IDs '|| v_index || ' to ' || (v_index+v_step) );

        BEGIN

            insert into reviews_vs (document_id, document_name, text, metadata, embedding, embedding_model)
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
           where r.id between (v_index + 1 ) and (v_index + v_step);

            commit;
        EXCEPTION
            WHEN OTHERS THEN
                v_code := SQLCODE;
                v_errm := SUBSTR(SQLERRM, 1, 64);
                DBMS_OUTPUT.PUT_LINE('Error when processing ID '||v_index || ', Error code ' || v_code || ': ' || v_errm);
        END;

        v_index := v_index + v_step;
    END LOOP;

    commit;

    EXCEPTION
        WHEN OTHERS THEN
            v_code := SQLCODE;
            v_errm := SUBSTR(SQLERRM, 1, 64);
            DBMS_OUTPUT.PUT_LINE('Error code ' || v_code || ': ' || v_errm);

END;
/



