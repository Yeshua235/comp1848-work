-- load_star_from_staging.sql

SET SERVEROUTPUT ON

DECLARE
  v_time_id    NUMBER;
  v_dc_id      NUMBER;
  v_product_id NUMBER;
  v_channel_id NUMBER;
  v_vendor_id  NUMBER;
  v_title      VARCHAR2(200);
  v_category   VARCHAR2(200);
  v_language   VARCHAR2(100);
  v_author_id  VARCHAR2(50);
BEGIN


  FOR d IN (SELECT DISTINCT reading_dt dt FROM stg_daily WHERE reading_dt IS NOT NULL
  UNION
  SELECT DISTINCT sale_dt dt FROM stg_sales WHERE sale_dt IS NOT NULL
  ) LOOP
    BEGIN
      SELECT time_id INTO v_time_id FROM dim_time WHERE dt = d.dt;
    EXCEPTION WHEN NO_DATA_FOUND THEN
      INSERT INTO dim_time(dt, day_no, month_no, year_no, quarter_no, is_weekend)
      VALUES (d.dt, TO_NUMBER(TO_CHAR(d.dt,'DD')), TO_NUMBER(TO_CHAR(d.dt,'MM')), TO_NUMBER(TO_CHAR(d.dt,'YYYY')),
              TO_NUMBER(TO_CHAR(d.dt,'Q')), CASE WHEN TO_CHAR(d.dt,'DY','NLS_DATE_LANGUAGE=ENGLISH') IN ('SAT','SUN') THEN 'Y' ELSE 'N' END)
      RETURNING time_id INTO v_time_id;
    END;
  END LOOP;


  FOR r IN (SELECT DISTINCT station_id, station_name, station_region, station_mgr FROM stg_meta WHERE station_id IS NOT NULL) LOOP
    BEGIN
      SELECT dc_id INTO v_dc_id FROM dim_dc WHERE dc_id = r.station_id;
    EXCEPTION WHEN NO_DATA_FOUND THEN
      INSERT INTO dim_dc(dc_id, name, region, mgr) VALUES (r.station_id, r.station_name, r.station_region, r.station_mgr);
    END;
  END LOOP;


  FOR a IN (SELECT DISTINCT author_id, author_first_name, author_last_name, author_country, author_primary_genre FROM stg_meta WHERE author_id IS NOT NULL) LOOP
    BEGIN
        SELECT author_id INTO v_author_id FROM dim_author WHERE author_id = a.author_id;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        INSERT INTO dim_author(author_id, first_name, last_name, country, primary_genre) VALUES (a.author_id, a.author_first_name, a.author_last_name, a.author_country, a.author_primary_genre);
    END;
  END LOOP;


  FOR c IN (SELECT DISTINCT chnl FROM stg_sales WHERE chnl IS NOT NULL) LOOP
    BEGIN
      SELECT channel_id INTO v_channel_id FROM dim_channel WHERE channel_code = c.chnl;
    EXCEPTION WHEN NO_DATA_FOUND THEN
      INSERT INTO dim_channel(channel_code, channel_name) VALUES (c.chnl, c.chnl) RETURNING channel_id INTO v_channel_id;
    END;
  END LOOP;

  FOR p IN (
    SELECT DISTINCT edid, NULL typ FROM stg_sales WHERE edid IS NOT NULL
    UNION
    SELECT NULL edid, typ FROM stg_daily WHERE typ IS NOT NULL
    ) LOOP
    BEGIN
        SELECT product_id INTO v_product_id FROM dim_product WHERE (edid = p.edid OR typ = p.typ) AND ROWNUM = 1;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        IF p.edid IS NOT NULL THEN
         BEGIN
          SELECT NVL(publication_title, NULL), NVL(publication_cat, NULL), NVL(publication_lang, NULL), NVL(author_id, NULL)
          INTO v_title, v_category, v_language, v_author_id
          FROM stg_meta WHERE publication_ed = p.edid;
        EXCEPTION WHEN NO_DATA_FOUND THEN
          v_title := NULL;
          v_category := NULL;
          v_language := NULL;
          v_author_id := NULL;
        END;
      ELSE
        v_title := NULL;
        v_category := NULL;
        v_language := NULL;
        v_author_id := NULL;
      END IF;
      INSERT INTO dim_product(edid, typ, title, category, language, author_id)
      VALUES (p.edid, p.typ, v_title, v_category, v_language, v_author_id) RETURNING product_id INTO v_product_id;
    END;
  END LOOP;

  FOR v IN (SELECT DISTINCT vendor_id, vendor_name, vendor_score FROM stg_meta WHERE vendor_id IS NOT NULL) LOOP
    BEGIN
        SELECT vendor_id INTO v_vendor_id FROM dim_vendor WHERE vendor_id = v.vendor_id;
  EXCEPTION WHEN NO_DATA_FOUND THEN
      INSERT INTO dim_vendor(vendor_id, vendor_name, vendor_score)
      VALUES (v.vendor_id, v.vendor_name, 5)
      RETURNING vendor_id INTO v_vendor_id;
    END;
  END LOOP;



BEGIN
  SELECT channel_id INTO v_channel_id FROM dim_channel WHERE channel_code = 'unknown';
EXCEPTION WHEN NO_DATA_FOUND THEN
  INSERT INTO dim_channel(channel_code, channel_name) VALUES ('unknown', 'Unknown') RETURNING channel_id INTO v_channel_id;
END;


BEGIN
  SELECT vendor_id INTO v_vendor_id FROM dim_vendor WHERE vendor_id = 'unknown';
EXCEPTION WHEN NO_DATA_FOUND THEN
  INSERT INTO dim_vendor(vendor_id, vendor_name, vendor_score) VALUES ('unknown', 'Unknown Vendor', 5) RETURNING vendor_id INTO v_vendor_id;
END;


MERGE INTO fact_production_sales f
USING (
  SELECT time_id, dc_id, product_id, channel_id, vendor_id,
    SUM(printrun) printrun, SUM(binding_cost) binding_cost, SUM(units_sold) units_sold, AVG(unit_price) unit_price,
    SUM(revenue) revenue, AVG(temperature) temperature, AVG(humidity) humidity,
    AVG(vendor_score) vendor_score, AVG(discount) discount, SUM(returns_count) returns_count,
    AVG(gross_margin_pct) gross_margin_pct, CURRENT_TIMESTAMP load_ts
  FROM (

    SELECT t.time_id, r.stncode dc_id, pr.product_id, ch.channel_id, ve.vendor_id,
      r.pd printrun, r.bc binding_cost, r.rv units_sold, NULL unit_price, r.rev revenue, r.tmp temperature, r.hmd humidity,
      r.vscr vendor_score, NULL discount, r.rv returns_count, NULL gross_margin_pct
    FROM stg_daily r
    JOIN dim_time t ON t.dt = r.reading_dt
    LEFT JOIN dim_product pr ON pr.typ = r.typ
    LEFT JOIN dim_channel ch ON ch.channel_code = 'unknown'
    LEFT JOIN (SELECT DISTINCT vendor_score, vendor_id FROM stg_meta
               UNION ALL
               SELECT DISTINCT TO_CHAR(vscr), 'unknown' FROM stg_sales WHERE vscr NOT IN (SELECT vendor_score FROM stg_meta)
               UNION ALL
               SELECT DISTINCT TO_CHAR(vscr), 'unknown' FROM stg_daily WHERE vscr NOT IN (SELECT vendor_score FROM stg_meta)) ve_meta
    ON ve_meta.vendor_score = TO_CHAR(r.vscr)
    LEFT JOIN dim_vendor ve ON ve.vendor_id = ve_meta.vendor_id
    WHERE r.reading_dt IS NOT NULL
    UNION ALL

    SELECT t.time_id, NULL dc_id, pr.product_id, ch.channel_id, ve.vendor_id,
      s.pd printrun, s.bc binding_cost, s.tqty units_sold, s.uprice unit_price, (s.tqty * s.uprice) revenue, NULL temperature, NULL humidity,
      s.vscr vendor_score, s.dscnt discount, NULL returns_count, ((s.tqty * s.uprice - NVL(s.bc,0)) / NULLIF(s.tqty * s.uprice,0) * 100) gross_margin_pct
    FROM stg_sales s
    JOIN dim_time t ON t.dt = s.sale_dt
    LEFT JOIN dim_product pr ON pr.edid = s.edid
    LEFT JOIN dim_channel ch ON ch.channel_code = s.chnl
    LEFT JOIN (SELECT DISTINCT vendor_score, vendor_id FROM stg_meta
               UNION ALL
               SELECT DISTINCT TO_CHAR(vscr), 'unknown' FROM stg_sales WHERE vscr NOT IN (SELECT vendor_score FROM stg_meta)
               UNION ALL
               SELECT DISTINCT TO_CHAR(vscr), 'unknown' FROM stg_daily WHERE vscr NOT IN (SELECT vendor_score FROM stg_meta)) ve_meta
    ON ve_meta.vendor_score = TO_CHAR(s.vscr)
    LEFT JOIN dim_vendor ve ON ve.vendor_id = ve_meta.vendor_id
    WHERE s.sale_dt IS NOT NULL )
  GROUP BY time_id, dc_id, product_id, channel_id, vendor_id
  WHERE product_id IS NOT NULL AND channel_id IS NOT NULL
) s ON (f.time_id = s.time_id AND f.dc_id = s.dc_id AND f.product_id = s.product_id AND f.channel_id = s.channel_id AND f.vendor_id = s.vendor_id)
WHEN MATCHED THEN UPDATE SET
  f.printrun = s.printrun, f.binding_cost = s.binding_cost, f.units_sold = s.units_sold,  f.unit_price = s.unit_price, f.revenue = s.revenue, f.temperature = s.temperature, f.humidity = s.humidity, f.vendor_score = s.vendor_score, f.discount = s.discount, f.returns_count = s.returns_count, f.gross_margin_pct = s.gross_margin_pct, f.load_ts = s.load_ts
WHEN NOT MATCHED THEN INSERT (time_id, dc_id, product_id, channel_id, vendor_id,
  printrun, binding_cost, units_sold, unit_price, revenue, temperature, humidity, vendor_score, discount, returns_count, gross_margin_pct, load_ts)
VALUES (s.time_id, s.dc_id, s.product_id, s.channel_id, s.vendor_id,
  s.printrun, s.binding_cost, s.units_sold, s.unit_price, s.revenue, s.temperature, s.humidity, s.vendor_score, s.discount, s.returns_count, s.gross_margin_pct, s.load_ts);

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Star load complete.');
END;
/
-- End of load_star_from_staging.sql
