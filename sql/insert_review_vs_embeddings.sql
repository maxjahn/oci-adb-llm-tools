DECLARE
    V_INDEX           NUMBER := 0;
    V_STEP            NUMBER := 50;
    V_UPPER_LIMIT     NUMBER := 2500;
    V_CODE            NUMBER;
    V_ERRM            VARCHAR2(64);
    V_EMBEDDING_MODEL VARCHAR2(64);
BEGIN
    SELECT
        VALUE_TEXT INTO V_EMBEDDING_MODEL
    FROM
        CONFIG_EMBEDDINGS
    WHERE
        CONFIG = 'EMBEDDING_MODEL';
    DELETE FROM REVIEWS_VS VS
    WHERE
        VS.DOCUMENT_ID BETWEEN V_INDEX AND V_UPPER_LIMIT;
    COMMIT;
    WHILE V_INDEX < V_UPPER_LIMIT LOOP
        DBMS_OUTPUT.PUT_LINE('creating embeddings for IDs '
                             || V_INDEX
                             || ' to '
                             || (V_INDEX+V_STEP) );
        BEGIN
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
                    '*Whisky Name: '
                    ||R.NAME
                    ||'*\n'
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
                    REVIEWS                   R,
                    DBMS_VECTOR.UTL_TO_CHUNKS(R.DESCRIPTION,
                    JSON('{"by":"words",
                    "max":"200",
                    "overlap":"20",
                    "split":"recursively",
                    "normalize":"all"}') ) C
                WHERE
                    R.ID BETWEEN (V_INDEX + 1 ) AND (V_INDEX + V_STEP);
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                V_CODE := SQLCODE;
                V_ERRM := SUBSTR(SQLERRM, 1, 64);
                DBMS_OUTPUT.PUT_LINE('Error when processing ID '
                                     ||V_INDEX
                                     || ', Error code '
                                     || V_CODE
                                     || ': '
                                     || V_ERRM);
        END;

        V_INDEX := V_INDEX + V_STEP;
    END LOOP;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        V_CODE := SQLCODE;
        V_ERRM := SUBSTR(SQLERRM, 1, 64);
        DBMS_OUTPUT.PUT_LINE('Error code '
                             || V_CODE
                             || ': '
                             || V_ERRM);
END;
/