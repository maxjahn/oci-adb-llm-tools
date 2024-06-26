-- USER SQL
CREATE USER VECTOR IDENTIFIED BY #Password#;

-- ADD ROLES
GRANT CONNECT TO VECTOR;

GRANT CONSOLE_DEVELOPER TO VECTOR;

GRANT DB_DEVELOPER_ROLE TO VECTOR;

GRANT DWROLE TO VECTOR;

GRANT OML_DEVELOPER TO VECTOR;

GRANT RESOURCE TO VECTOR;

ALTER USER VECTOR DEFAULT ROLE CONSOLE_DEVELOPER, DB_DEVELOPER_ROLE, DWROLE, OML_DEVELOPER;

-- REST ENABLE
BEGIN
    ORDS_ADMIN.ENABLE_SCHEMA(
        P_ENABLED => TRUE,
        P_SCHEMA => 'VECTOR',
        P_URL_MAPPING_TYPE => 'BASE_PATH',
        P_URL_MAPPING_PATTERN => 'vector',
        P_AUTO_REST_AUTH=> TRUE
    );
 -- ENABLE DATA SHARING
    C##ADP$SERVICE.DBMS_SHARE.ENABLE_SCHEMA(
        SCHEMA_NAME => 'VECTOR',
        ENABLED => TRUE
    );
    COMMIT;
END;
/

-- ENABLE OML
ALTER USER VECTOR GRANT CONNECT THROUGH OML$PROXY;

-- QUOTA
ALTER USER VECTOR QUOTA UNLIMITED ON DATA;