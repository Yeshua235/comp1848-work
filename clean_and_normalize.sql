-- This script performs data cleansing and normalization on staging tables:
-- stg_meta, stg_daily, and stg_sales.

-- Remove Byte Order Mark (BOM) if present
UPDATE stg_meta SET station_id = REGEXP_REPLACE(station_id, '^\ufeff', '');
UPDATE stg_daily SET dateid_raw = REGEXP_REPLACE(dateid_raw, '^\ufeff', '');
UPDATE stg_sales SET datestamp_raw = REGEXP_REPLACE(datestamp_raw, '^\ufeff', '');

-- Parse stg_daily date
UPDATE stg_daily
SET reading_dt =
  CASE
    WHEN REGEXP_LIKE(dateid_raw,'^\d{4}/\d{2}/\d{2}$') THEN TO_DATE(dateid_raw,'YYYY/MM/DD')
    WHEN REGEXP_LIKE(dateid_raw,'^\d{4}-\d{2}-\d{2}$') THEN TO_DATE(dateid_raw,'YYYY-MM-DD')
    WHEN REGEXP_LIKE(dateid_raw,'^\d{2}-\d{2}-\d{4}$') THEN TO_DATE(dateid_raw,'DD-MM-YYYY')
    WHEN REGEXP_LIKE(dateid_raw,'^\d{2}/\d{2}/\d{4}$') THEN TO_DATE(dateid_raw,'DD/MM/YYYY')
    ELSE NULL
  END;

-- Parse stg_sales date
UPDATE stg_sales
SET sale_dt =
  CASE
    WHEN REGEXP_LIKE(datestamp_raw,'^\d{4}-\d{2}-\d{2}$') THEN TO_DATE(datestamp_raw,'YYYY-MM-DD')
    WHEN REGEXP_LIKE(datestamp_raw,'^\d{4}/\d{2}/\d{2}$') THEN TO_DATE(datestamp_raw,'YYYY/MM/DD')
    WHEN REGEXP_LIKE(datestamp_raw,'^\d{2}-\d{2}-\d{4}$') THEN TO_DATE(datestamp_raw,'DD-MM-YYYY')
    WHEN REGEXP_LIKE(datestamp_raw,'^\d{2}/\d{2}/\d{4}$') THEN TO_DATE(datestamp_raw,'DD/MM/YYYY')
    ELSE NULL
  END;
COMMIT;

-- transforming misc1 from string to numeric
ALTER TABLE stg_daily ADD misc1_temp NUMBER;
UPDATE stg_daily SET misc1_temp = CASE
                                    WHEN REGEXP_LIKE(misc1, '^-?\d+\.?\d*$') THEN TO_NUMBER(misc1)
                                ELSE NULL
                                END;

ALTER TABLE stg_daily DROP COLUMN misc1;
ALTER TABLE stg_daily RENAME COLUMN misc1_temp TO misc1;
COMMIT;

-- handling unreasonable (negative) values in numeric fields
-- stg_daily
UPDATE stg_daily SET pd = ABS(pd) WHERE pd < 0;
UPDATE stg_daily SET bc = ABS(bc) WHERE bc < 0;
UPDATE stg_daily SET misc1 = ABS(misc1) WHERE misc1 < 0;
UPDATE stg_daily SET hmd =  (SELECT ROUND(AVG(hmd), 2) FROM stg_daily WHERE hmd IS NOT NULL AND hmd >= 0 AND hmd <= 100) WHERE hmd IS NULL OR hmd < 0 OR hmd > 100;

-- stg_sales
UPDATE stg_sales SET pd = ABS(pd) WHERE pd < 0;
UPDATE stg_sales SET bc = ABS(bc) WHERE bc < 0;
UPDATE stg_sales SET tqty = ABS(tqty) WHERE tqty < 0;
UPDATE stg_sales SET uprice = ABS(uprice) WHERE uprice < 0;
UPDATE stg_sales SET dscnt = ABS(dscnt) WHERE dscnt < 0;
UPDATE stg_sales SET dscnt = 0 WHERE dscnt > 1;

-- Trim/type cleanup
UPDATE stg_daily SET typ = NULLIF(TRIM(typ),'');
UPDATE stg_daily SET notes = NULLIF(TRIM(notes),'');
UPDATE stg_sales SET typ = NULLIF(TRIM(typ),'');
UPDATE stg_meta SET station_name = TRIM(station_name);
COMMIT;

-- handling null values
-- stg_daily
UPDATE stg_daily SET dateid_raw = 'unknown' WHERE dateid_raw IS NULL;
UPDATE stg_daily SET reading_dt = TO_DATE('1900-01-01', 'YYYY-MM-DD') WHERE reading_dt IS NULL;
UPDATE stg_daily  SET rv = 0 WHERE rv IS NULL;
UPDATE stg_daily  SET pd = 0 WHERE pd IS NULL;
UPDATE stg_daily  SET bc = 0 WHERE bc IS NULL;
UPDATE stg_daily  SET misc1 = 0 WHERE misc1 IS NULL;
UPDATE stg_daily  SET rev   = 0 WHERE rev IS NULL;
UPDATE stg_daily SET vscr = 0 WHERE vscr IS NULL;
UPDATE stg_daily SET tmp = (SELECT ROUND(AVG(tmp), 2) FROM stg_daily WHERE tmp IS NOT NULL) WHERE tmp IS NULL;
UPDATE stg_daily  SET typ  = 'unknown' WHERE typ IS NULL;
UPDATE stg_daily  SET notes  = 'unknown' WHERE notes IS NULL;
UPDATE stg_daily  SET stncode  = 'unknown' WHERE stncode IS NULL;

-- stg_sales
UPDATE stg_sales SET datestamp_raw = 'unknown' WHERE datestamp_raw IS NULL;
UPDATE stg_sales SET sale_dt = TO_DATE('1900-01-01', 'YYYY-MM-DD') WHERE sale_dt IS NULL;
UPDATE stg_sales  SET pd = 0 WHERE pd IS NULL;
UPDATE stg_sales  SET bc = 0 WHERE bc IS NULL;
UPDATE stg_sales  SET vscr = 0 WHERE vscr IS NULL;
UPDATE stg_sales SET tqty = 0 WHERE tqty IS NULL;
UPDATE stg_sales SET dscnt = 0 WHERE dscnt IS NULL;
UPDATE stg_sales SET uprice = (SELECT ROUND(AVG(uprice), 2) FROM stg_sales WHERE uprice IS NOT NULL)
WHERE uprice IS NULL;
UPDATE stg_sales SET edid  = 'unknown' WHERE edid IS NULL;
UPDATE stg_sales SET typ  = 'unknown' WHERE typ IS NULL;
UPDATE stg_sales SET curr = 'unknown' WHERE curr IS NULL;
UPDATE stg_sales SET chnl = 'unknown' WHERE chnl IS NULL;
UPDATE stg_sales SET sale_num = 'UNKNOWN' WHERE sale_num IS NULL;

-- stg_meta
UPDATE stg_meta SET station_id = 'UNKNOWN' WHERE station_id IS NULL;
UPDATE stg_meta SET station_name = 'UNKNOWN' WHERE station_name IS NULL;

COMMIT;
