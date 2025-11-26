-- create_structured_staging.sql
CREATE TABLE stg_daily (
  row_num     NUMBER,
  dateid_raw  VARCHAR2(100),
  stncode     VARCHAR2(50),
  pd          NUMBER,
  bc          NUMBER,
  misc1       VARCHAR2(200),
  rv          NUMBER,
  rev         NUMBER,
  tmp         NUMBER,
  hmd         NUMBER,
  vscr        NUMBER,
  typ         VARCHAR2(200),
  notes       VARCHAR2(4000),
  reading_dt  DATE,
  load_ts     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE stg_sales (
  row_num       NUMBER,
  sale_num      VARCHAR2(50),
  datestamp_raw VARCHAR2(100),
  edid          VARCHAR2(50),
  chnl          VARCHAR2(50),
  tqty          NUMBER,
  uprice        NUMBER,
  curr          VARCHAR2(10),
  dscnt         NUMBER,
  pd            NUMBER,
  bc            NUMBER,
  vscr          NUMBER,
  typ           VARCHAR2(200),
  sale_dt       DATE,
  load_ts       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE stg_meta (
  row_num         NUMBER,
  station_id      VARCHAR2(50),
  station_name    VARCHAR2(400),
  station_region  VARCHAR2(200),
  station_mgr     VARCHAR2(100),
  address_raw     VARCHAR2(2000),
  description_raw CLOB,
  author_country  VARCHAR2(50),
  author_genre    VARCHAR2(100),
  extra1          VARCHAR2(200),
  extra2          VARCHAR2(200),
  author_first    VARCHAR2(100),
  author_last     VARCHAR2(100),
  load_ts         TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMIT;
