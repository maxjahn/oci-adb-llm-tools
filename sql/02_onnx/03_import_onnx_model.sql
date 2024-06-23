DECLARE
    V_MODEL_SOURCE     BLOB := NULL;
    V_MODEL_NAME       VARCHAR2(32) := 'xxx';
    V_MODEL_OBJECT_URL VARCHAR2(256) := 'xxx.onnx';
BEGIN V_MODEL_SOURCE := DBMS_CLOUD.GET_OBJECT(
    CREDENTIAL_NAME => NULL,
    OBJECT_URI => V_MODEL_OBJECT_URL
);
BEGIN
    DBMS_VECTOR.DROP_ONNX_MODEL(
        MODEL_NAME => V_MODEL_NAME,
        FORCE => TRUE
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error code '
                             || SQLCODE
                             || ': '
                             || SQLERRM);
        END;
    DBMS_DATA_MINING.IMPORT_ONNX_MODEL( V_MODEL_NAME, V_MODEL_SOURCE, JSON('{"function" : "embedding", "embeddingOutput" : "embedding", "input": {"input": ["DATA"]}}') );
END;
/