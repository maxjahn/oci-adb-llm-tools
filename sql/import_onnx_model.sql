DECLARE
    model_source BLOB := NULL;
    model_name varchar2(32) := 'xxx';
    model_object_url varchar2(256) := 'xxx.onnx';

BEGIN
    model_source := DBMS_CLOUD.GET_OBJECT(
        credential_name => null,
        object_uri => model_object_url); 
    
    DBMS_VECTOR.DROP_ONNX_MODEL(model_name => model_name, force => true);

    DBMS_DATA_MINING.IMPORT_ONNX_MODEL(
        model_name,
        model_source,
        JSON('{"function" : "embedding", "embeddingOutput" : "embedding", "input": {"input": ["DATA"]}}')
        );



END;
/