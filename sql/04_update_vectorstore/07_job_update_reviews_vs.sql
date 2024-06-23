BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
        JOB_NAME => 'job_update_reviews_vs',
        JOB_TYPE => 'PLSQL_BLOCK',
        JOB_ACTION => 'BEGIN prc_update_reviews_vs; END;',
        START_DATE => SYSTIMESTAMP,
        REPEAT_INTERVAL => 'FREQ=DAILY; BYHOUR=0; BYMINUTE=0; BYSECOND=0',
        ENABLED => TRUE
    );
END;
/