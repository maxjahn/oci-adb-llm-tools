CREATE OR REPLACE TRIGGER TRG_REVIEWS_VS_UPD_INS AFTER
    INSERT OR UPDATE ON REVIEWS FOR EACH ROW
DECLARE
    V_CODE            NUMBER;
    V_ERRM            VARCHAR2(64);
    V_EMBEDDING_MODEL VARCHAR2(64);
BEGIN
    BEGIN
        SELECT
            VALUE_TEXT INTO V_EMBEDDING_MODEL
        FROM
            CONFIG_EMBEDDINGS
        WHERE
            CONFIG = 'EMBEDDING_MODEL';
        DELETE FROM REVIEWS_VS
        WHERE
            DOCUMENT_ID = :NEW.ID;
        INSERT INTO REVIEWS_VS (
            DOCUMENT_ID,
            DOCUMENT_NAME,
            TEXT,
            METADATA,
            EMBEDDING,
            EMBEDDING_MODEL
        )
            SELECT
                R.ID                                                                                    AS DOCUMENT_ID,
                R.NAME                                                                                  AS DOCUMENT_NAME,
                '**Whisky Name:** '
                ||R.NAME
                || CHR(13)
                || CHR(10)
                ||'**Category:** '
                ||R.CATEGORY
                || CHR(13)
                || CHR(10)
                ||'**Description:** '
                || JSON_VALUE(C.COLUMN_VALUE, '$.chunk_data')                                           AS TEXT,
                JSON('{"document_id" : "'
                     || R.ID
                     || '", "_rowid" : "'
                     || R.ROWID
                     || '"}')                                                                           AS METADATA,
                DBMS_VECTOR.UTL_TO_EMBEDDING(JSON_VALUE(C.COLUMN_VALUE, '$.chunk_data'), JSON('{"provider":"database", "model":"'
                                                                                              || V_EMBEDDING_MODEL
                                                                                              || '"}')) AS EMBEDDING,
                V_EMBEDDING_MODEL                                                                       AS EMBEDDING_MODEL
            FROM
                DBMS_VECTOR.UTL_TO_CHUNKS( :NEW.DESCRIPTION,
                JSON('{"by":"words",
                            "max":"200",
                            "overlap":"20",
                            "split":"recursively",
                            "normalize":"all"}') ) C;
    EXCEPTION
        WHEN OTHERS THEN
            V_CODE := SQLCODE;
            V_ERRM := SUBSTR(SQLERRM, 1, 64);
            DBMS_OUTPUT.PUT_LINE('Error Code '
                                 || V_CODE
                                 || ': '
                                 || V_ERRM);
    END;
END;
/