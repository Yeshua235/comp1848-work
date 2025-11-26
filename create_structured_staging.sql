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
  row_num                NUMBER,
  station_id             VARCHAR2(50),
  station_name           VARCHAR2(400),
  station_region         VARCHAR2(200),
  station_mgr            VARCHAR2(100),
  address_raw            VARCHAR2(1000),
  vendor_id              VARCHAR2(50),
  vendor_name            VARCHAR2(200),
  vendor_score           VARCHAR2(50),
  vendor_services_0_type VARCHAR2(100),
  vendor_services_0_qual NUMBER,
  vendor_services_1_type VARCHAR2(100),
  vendor_services_1_qual VARCHAR2(100),
  publication_ed         VARCHAR2(100),
  publication_title      VARCHAR2(200),
  publication_cat        VARCHAR2(200),
  publication_lang       VARCHAR2(100),
  publication_author     VARCHAR2(200),
  author_id              VARCHAR2(50),
  author_first_name      VARCHAR2(100),
  author_last_name       VARCHAR2(100),
  author_country         VARCHAR2(100),
  author_primary_genre   VARCHAR2(250),
  field23                VARCHAR2(200),
  field24                VARCHAR2(200),
  load_ts                TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMIT;
