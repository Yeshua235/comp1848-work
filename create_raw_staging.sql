-- create_raw_staging.sql
CREATE TABLE stage_raw_files (
  file_name    VARCHAR2(200),
  raw_line     CLOB,
  load_time    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE etl_file_loads (
  file_name VARCHAR2(255),
  load_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  row_count NUMBER
);

COMMIT;
