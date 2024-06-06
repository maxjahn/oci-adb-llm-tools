CREATE OR REPLACE TRIGGER trg_reviews_vs_upd_ins
AFTER INSERT OR UPDATE ON reviews
FOR EACH ROW
DECLARE
    v_code  NUMBER;
    v_errm  VARCHAR2(64);
    v_embedding_model VARCHAR2(64);

BEGIN

    BEGIN

        SELECT value_text INTO v_embedding_model FROM CONFIG_EMBEDDINGS where config = 'EMBEDDING_MODEL';

        DELETE FROM reviews_vs WHERE document_id = :NEW.id;

        INSERT INTO reviews_vs (document_id, document_name, text, metadata, embedding, embedding_model)
            SELECT 
                :NEW.id as document_id,
                :NEW.name as document_name,
                '*Whisky Name: '||:NEW.name || '*\n' || JSON_VALUE(C.column_value, '$.chunk_data') AS text,
                json('{"document_id" : "' || :NEW.id || '", "_rowid" : "' || :NEW.rowid || '"}') as metadata,
                dbms_vector.utl_to_embedding(JSON_VALUE(C.column_value, '$.chunk_data'), json('{"provider":"database", "model":"' || v_embedding_model || '"}')) as embedding,
                v_embedding_model as embedding_model            
            FROM            
                dbms_vector.utl_to_chunks(
                    :NEW.description,
                    JSON('{"by":"words",
                            "max":"200",
                            "overlap":"20",
                            "split":"recursively",
                            "normalize":"all"}')
                    ) C
             ;
        
    EXCEPTION
        WHEN OTHERS THEN
            v_code := SQLCODE;
            v_errm := SUBSTR(SQLERRM, 1, 64);
            DBMS_OUTPUT.PUT_LINE('Error Code ' || v_code || ': ' || v_errm);
    END;

END;
/
