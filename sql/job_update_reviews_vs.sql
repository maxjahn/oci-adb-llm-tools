BEGIN
    DBMS_SCHEDULER.create_job (
        job_name        => 'job_update_reviews_vs',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'BEGIN prc_update_reviews_vs; END;',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY; BYHOUR=0; BYMINUTE=0; BYSECOND=0',
        enabled         => TRUE
    );
END;
/
