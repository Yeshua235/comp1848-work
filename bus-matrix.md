# InkWave DW Bus Matrix

Conformed dimensions
- Time (dim_time): dt, day_no, month_no, year_no, quarter_no, is_weekend
- DC (dim_dc): dc_id, name, region, mgr
- Product (dim_product): product_id, edid, typ, title, category, author_id
- Channel (dim_channel): channel_code, channel_name
- Vendor (dim_vendor): vendor_id, vendor_name, vendor_score
- Author (dim_author): first_name, last_name, country, primary_genre

Fact table and grain
- fact_production_sales
- Grain: one row per day × DC × product × channel

| Business Process / Use Case                 | Fact Table              | Grain                                 | Time | DC | Product | Channel | Vendor | Author | Core Measures                                                | Derived Measures (ETL/SQL)                                             |
|--------------------------------------------|-------------------------|---------------------------------------|------|----|---------|---------|--------|--------|--------------------------------------------------------------|-------------------------------------------------------------------------|
| Sales Analysis (Channel Mix by Edition)     | fact_production_sales   | Day × DC × Product × Channel         |  Y   | Y  |   Y     |   Y     |   -    |   -    | units_sold, unit_price, discount, revenue                   | pct_channel = units_sold / SUM(units_sold) over (edition)              |
| Production / Print Operations               | fact_production_sales   | Day × DC × Product × Channel         |  Y   | Y  |   Y     |   -     |   -    |   -    | printrun, binding_cost, temperature, humidity               | -                                                                       |
| Returns & Quality                           | fact_production_sales   | Day × DC × Product × Channel         |  Y   | Y  |   Y     |   -     |   -    |   -    | returns_count, units_sold                                   | return_rate = returns_count / NULLIF(units_sold,0)                     |
| Margin & Profitability (Top 5 by Region)    | fact_production_sales   | Day × DC × Product × Channel         |  Y   | Y  |   Y     |   -     |   -    |   -    | revenue, binding_cost, gross_margin_pct                     | margin_amt = revenue - binding_cost; wm_margin = margin weighted by rev |
| Vendor Cost Trend (12-mo rolling)           | fact_production_sales   | Day × DC × Product × Channel         |  Y   | Y  |   Y     |   -     |   Y    |   -    | binding_cost, vendor_score                                   | rolling_avg_cost = AVG(binding_cost) over 12 months                     |
| Author Performance (Revenue vs Discount)    | fact_production_sales   | Day × DC × Product × Channel         |  Y   | Y  |   Y     |   Y     |   -    |   Y    | revenue, discount                                           | avg_discount = weighted by revenue                                      |

Notes
- All rows use the same conformed dimensions; Author is joined via dim_product.author_id.
- “Top 5 Editions by Margin per Region” uses Time(quarter/year) + DC(region) + Product(edid) + gross_margin_pct.
- “Hot DCs” uses DC + return_rate + gross_margin_pct.
- “Channel Mix” uses Channel + units_sold percentage within edition.

ETL key mapping (staging → DW)
- Time: stg_daily.reading_dt / stg_sales.sale_dt → dim_time.dt (derive day_no, month_no, year_no, quarter_no, is_weekend)
- DC: stg_daily.stncode → dim_dc.dc_id (name/region/mgr from stg_meta if available)
- Product: stg_sales.edid → dim_product.edid; typ from stg_sales.typ or stg_daily.typ; title/category/author_id from stg_meta
- Channel: stg_sales.chnl → dim_channel.channel_code (map to human name)
- Vendor: vendor fields from stg_meta → dim_vendor; optional vendor_id on fact if known at grain
- Fact measures:
  - printrun ← stg_daily.pd
  - binding_cost ← stg_daily.bc
  - units_sold ← stg_sales.tqty
  - unit_price ← stg_sales.uprice
  - discount ← stg_sales.dscnt (0..1)
  - revenue ← stg_daily.rev OR SUM(tqty*uprice*(1-NVL(dscnt,0)))
  - returns_count ← stg_daily.rv
  - temperature ← stg_daily.tmp
  - humidity ← stg_daily.hmd
  - vendor_score ← stg_sales.vscr or stg_meta
  - gross_margin_pct ← (revenue - binding_cost) / NULLIF(revenue,0) * 100

Constraints to enforce conformance
- Fact grain uniqueness: (time_id, dc_id, product_id, channel_id) unique
- CHECKs: discount ∈ [0,1], humidity ∈ [0,100], gross_margin_pct ∈ [-100,100]
- NOT NULL: dt (dim_time), dc_id (dim_dc), edid (dim_product), channel_code (dim_channel)