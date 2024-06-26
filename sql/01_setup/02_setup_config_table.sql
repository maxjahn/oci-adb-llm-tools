CREATE TABLE VECTOR.CONFIG_EMBEDDINGS (
    CONFIG VARCHAR2 (32),
    VALUE_TEXT VARCHAR2 (4000),
    VALUE_NUM NUMBER
) LOGGING;

ALTER TABLE VECTOR.CONFIG_EMBEDDINGS ADD CONSTRAINT CONFIG_EMBEDDINGS_PK PRIMARY KEY ( CONFIG ) USING INDEX LOGGING;

INSERT INTO VECTOR.CONFIG_EMBEDDINGS (
    CONFIG,
    VALUE_TEXT,
    VALUE_NUM
) VALUES (
    'EMBEDDING_MODEL',
    'ALL_MPNET_BASE_V2',
    NULL
);