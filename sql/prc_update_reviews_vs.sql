CREATE OR REPLACE PROCEDURE PRC_UPDATE_REVIEWS_VS AS
BEGIN
    DECLARE
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
                    ||'* \\n\\n *Category: '
                    ||R.CATEGORY
                    ||'* \\n\\n *Description: '
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
                R.ID IN (
                    SELECT
                        ID
                    FROM
                        REVIEWS                   REV
                    WHERE
                        NOT EXISTS (
                            SELECT
                                1
                            FROM
                                REVIEWS_VS
                            WHERE
                                DOCUMENT_ID = REV.ID
                        )
                );
    EXCEPTION
        WHEN OTHERS THEN
            V_CODE := SQLCODE;
            V_ERRM := SUBSTR(SQLERRM, 1, 64);
            DBMS_OUTPUT.PUT_LINE('Error code '
                                 || V_CODE
                                 || ': '
                                 || V_ERRM);
    END;

    COMMIT;
END;
/