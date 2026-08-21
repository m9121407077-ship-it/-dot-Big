#!/usr/bin/env python3
import hashlib, json, os, time
from pathlib import Path
from datetime import datetime, timezone
import requests, duckdb

ROOT=Path(os.environ.get('DIVAR_WORKDIR','divar_work')); RAW=ROOT/'raw'; OUT=ROOT/'out'; REP=OUT/'reports'; CLEAN=OUT/'clean_full'
for p in (RAW,OUT,REP,CLEAN): p.mkdir(parents=True,exist_ok=True)
BASE='https://huggingface.co/datasets/divarofficial/real_estate_ads/resolve/refs%2Fconvert%2Fparquet/default/train'
FILES=[
 {'name':'0000.parquet','url':BASE+'/0000.parquet?download=true','sha256':'b335a736b9a6e8acf73f21b6a634e16671194f21f79aceea842736aa7a3274c1','size':187384098},
 {'name':'0001.parquet','url':BASE+'/0001.parquet?download=true','sha256':'0019bfa2627a6832f163e39c8a4389f11edd1ee80391b1f7f08e1b21775db8f5','size':153245851},
]

def sh(path):
 h=hashlib.sha256()
 with open(path,'rb') as f:
  for b in iter(lambda:f.read(8*1024*1024),b''): h.update(b)
 return h.hexdigest()

def dl(s):
 d=RAW/s['name']
 for a in range(1,5):
  try:
   print('DOWNLOAD',s['name'],'attempt',a,flush=True)
   with requests.get(s['url'],stream=True,timeout=(30,240),allow_redirects=True,headers={'User-Agent':'Qarain-Atlas-Divar/2.0'}) as r:
    r.raise_for_status(); tmp=d.with_suffix('.part'); total=0; last=time.time()
    with open(tmp,'wb') as f:
     for c in r.iter_content(8*1024*1024):
      if not c: continue
      f.write(c); total+=len(c)
      if time.time()-last>20: print('PROGRESS',s['name'],total,flush=True); last=time.time()
    tmp.replace(d)
   assert d.stat().st_size==s['size'],(d.stat().st_size,s['size'])
   got=sh(d); assert got==s['sha256'],(got,s['sha256'])
   print('VERIFIED',s['name'],got,flush=True); return d
  except Exception as e:
   print('ERROR',repr(e),flush=True)
   if a==4: raise
   time.sleep(5*a)

paths=[dl(s) for s in FILES]
con=duckdb.connect(str(ROOT/'divar.duckdb')); con.execute('PRAGMA threads=4'); con.execute("PRAGMA memory_limit='6GB'")
plist=','.join("'"+str(p).replace("'","''")+"'" for p in paths)
con.execute(f"CREATE VIEW raw AS SELECT * FROM read_parquet([{plist}],union_by_name=true)")
row_count=con.execute('SELECT COUNT(*) FROM raw').fetchone()[0]; desc=con.execute('DESCRIBE raw').fetchall(); cols=[r[0] for r in desc]; types={r[0]:r[1] for r in desc}
print('ROWS',row_count,'COLS',len(cols),flush=True)

def q(s): return con.execute(s).fetchone()[0]
def escpath(p): return str(p).replace("'","''")
def norm(c): return f"trim(regexp_replace(replace(replace(coalesce({c},''),'ي','ی'),'ك','ک'),'\\s+',' ','g'))"

con.execute('CREATE VIEW clean AS SELECT *, '+norm('title')+' title_norm, '+norm('description')+''' description_norm,
 CASE WHEN price_value>0 AND building_size>0 THEN price_value/building_size END asking_price_per_sqm_raw_unit,
 try_cast(created_at_month AS DATE) created_month_date,
 CASE WHEN price_value IS NULL THEN 'PRICE_MISSING' WHEN price_value=0 THEN 'PRICE_ZERO' WHEN price_value<0 THEN 'PRICE_NEGATIVE' ELSE 'PRICE_PRESENT' END price_presence_flag,
 CASE WHEN building_size IS NULL THEN 'SIZE_MISSING' WHEN building_size<=0 THEN 'SIZE_NONPOSITIVE' ELSE 'SIZE_PRESENT' END building_size_flag
 FROM raw''')
# Non-destructive clean: preserve all 1M source rows and all source columns; add helper columns only.
con.execute(f"COPY (SELECT * FROM clean) TO '{escpath(CLEAN)}' (FORMAT PARQUET,COMPRESSION ZSTD,PARTITION_BY(cat2_slug),OVERWRITE_OR_IGNORE TRUE)")

null_expr=[f'SUM(CASE WHEN "{c}" IS NULL THEN 1 ELSE 0 END)' for c in cols]; nr=con.execute('SELECT '+','.join(null_expr)+' FROM raw').fetchone(); nulls={c:{'null_count':int(nr[i]),'null_pct':round(100*nr[i]/row_count,4)} for i,c in enumerate(cols)}
coverage={
 'row_count':row_count,'source_column_count':len(cols),'columns':cols,'types':types,
 'date_min':str(q('SELECT MIN(try_cast(created_at_month AS DATE)) FROM raw')),
 'date_max':str(q('SELECT MAX(try_cast(created_at_month AS DATE)) FROM raw')),
 'cities':int(q('SELECT COUNT(DISTINCT city_slug) FROM raw')),'neighborhoods':int(q('SELECT COUNT(DISTINCT neighborhood_slug) FROM raw')),
 'cat2':int(q('SELECT COUNT(DISTINCT cat2_slug) FROM raw')),'cat3':int(q('SELECT COUNT(DISTINCT cat3_slug) FROM raw')),
 'rows_price_present':int(q('SELECT COUNT(*) FROM raw WHERE price_value IS NOT NULL')),'rows_price_positive':int(q('SELECT COUNT(*) FROM raw WHERE price_value>0')),
 'rows_building_size':int(q('SELECT COUNT(*) FROM raw WHERE building_size IS NOT NULL')),'rows_latlon':int(q('SELECT COUNT(*) FROM raw WHERE location_latitude IS NOT NULL AND location_longitude IS NOT NULL'))
}
queries={
 'cat2_counts':'SELECT cat2_slug,COUNT(*) n FROM raw GROUP BY 1 ORDER BY n DESC',
 'cat3_counts':'SELECT cat3_slug,COUNT(*) n FROM raw GROUP BY 1 ORDER BY n DESC',
 'city_counts':'SELECT city_slug,COUNT(*) n FROM raw GROUP BY 1 ORDER BY n DESC',
 'deed_type_counts':'SELECT deed_type,COUNT(*) n FROM raw GROUP BY 1 ORDER BY n DESC',
 'user_type_counts':'SELECT user_type,COUNT(*) n FROM raw GROUP BY 1 ORDER BY n DESC'}
for n,sql in queries.items(): con.execute(f"COPY ({sql}) TO '{escpath(REP/(n+'.parquet'))}' (FORMAT PARQUET,COMPRESSION ZSTD)")

# Missingness by category for every source column. row_count alias avoids DuckDB ROWS keyword conflict.
parts=[]
for c in cols:
 cc=c.replace("'","''"); parts.append(f'''SELECT cat2_slug,'{cc}' column_name,COUNT(*) row_count,SUM(CASE WHEN "{c}" IS NULL THEN 1 ELSE 0 END) null_count,ROUND(100.0*SUM(CASE WHEN "{c}" IS NULL THEN 1 ELSE 0 END)/COUNT(*),4) null_pct FROM raw GROUP BY cat2_slug''')
con.execute(f"COPY ({' UNION ALL '.join(parts)}) TO '{escpath(REP/'missingness_by_cat2.parquet')}' (FORMAT PARQUET,COMPRESSION ZSTD)")

# Discover real residential-sale category instead of assuming one slug spelling.
cat2_values=[r[0] for r in con.execute("SELECT DISTINCT cat2_slug FROM raw WHERE cat2_slug IS NOT NULL ORDER BY 1").fetchall()]
res_candidates=[x for x in cat2_values if ('residential' in x.lower() and ('sell' in x.lower() or 'sale' in x.lower()))]
if not res_candidates:
 res_candidates=[x for x in cat2_values if ('sell' in x.lower() or 'sale' in x.lower())]
if not res_candidates:
 raise RuntimeError('No residential/sale cat2 slug found; inspect cat2_counts')
res_cat=res_candidates[0]
print('RESIDENTIAL_SALE_CAT2',res_cat,flush=True)
valid=f"cat2_slug='{res_cat.replace(chr(39),chr(39)*2)}' AND price_value>0 AND building_size BETWEEN 10 AND 1000"
lo,hi=con.execute(f'SELECT quantile_cont(price_value/building_size,0.001),quantile_cont(price_value/building_size,0.999) FROM raw WHERE {valid}').fetchone()
if lo is None or hi is None: raise RuntimeError('No usable residential-sale price/size observations')
base_summary=f'''SELECT city_slug,neighborhood_slug,try_cast(created_at_month AS DATE) month,COUNT(*) n,median(price_value/building_size) median_asking_ppsqm_raw_unit,quantile_cont(price_value/building_size,.25) p25_asking_ppsqm_raw_unit,quantile_cont(price_value/building_size,.75) p75_asking_ppsqm_raw_unit,AVG(price_value/building_size) mean_asking_ppsqm_raw_unit FROM raw WHERE {valid} GROUP BY 1,2,3 HAVING COUNT(*)>=5'''
robust=f'''SELECT city_slug,neighborhood_slug,try_cast(created_at_month AS DATE) month,COUNT(*) n,median(price_value/building_size) median_asking_ppsqm_raw_unit,quantile_cont(price_value/building_size,.25) p25_asking_ppsqm_raw_unit,quantile_cont(price_value/building_size,.75) p75_asking_ppsqm_raw_unit,AVG(price_value/building_size) mean_asking_ppsqm_raw_unit FROM raw WHERE {valid} AND price_value/building_size BETWEEN {float(lo)} AND {float(hi)} GROUP BY 1,2,3 HAVING COUNT(*)>=5'''
con.execute(f"COPY ({base_summary}) TO '{escpath(REP/'residential_sell_price_context_raw.parquet')}' (FORMAT PARQUET,COMPRESSION ZSTD)")
con.execute(f"COPY ({robust}) TO '{escpath(REP/'residential_sell_price_context_robust.parquet')}' (FORMAT PARQUET,COMPRESSION ZSTD)")

patterns={'deed':'سند','single_page_deed':'سند.{0,5}تک.?برگ','six_dang':'شش.?دانگ','power_of_attorney':'وکالت|وکالتی','contractual_deed':'قولنامه|قولنامه.?ای','endowment':'اوقاف|اوقافی','parking':'پارکینگ','warehouse':'انباری','elevator':'آسانسور','no_violation':'بدون.?خلاف|فاقد.?خلاف','completion':'پایان.?کار','urgent':'فوری','below_price':'زیر.?قیمت|زیر.?فی','discount':'تخفیف','presale':'پیش.?فروش','mortgage':'وام','exchange':'معاوضه','vacant':'تخلیه|تخلیه.?شده','owner_direct':'مالک|شخصی','share_land':'قدرالسهم','common_area':'مشاعات','rebuilt':'بازسازی','usage':'کاربری','frontage':'بر.?خیابان|بر.?کوچه|گذر'}
text="lower(coalesce(title_norm,'')||' '||coalesce(description_norm,''))"; u=[]
for k,p in patterns.items():
 ep=p.replace("'","''"); u.append(f"SELECT '{k}' pattern_key,'{ep}' regex_pattern,COUNT(*) FILTER(WHERE regexp_matches({text},'{ep}')) matched_rows,COUNT(*) total_rows FROM clean")
con.execute(f"COPY ({' UNION ALL '.join(u)}) TO '{escpath(REP/'claim_patterns.parquet')}' (FORMAT PARQUET,COMPRESSION ZSTD)")

dups=int(q('''SELECT COALESCE(SUM(n-1),0) FROM (SELECT COUNT(*) n FROM raw GROUP BY cat2_slug,cat3_slug,city_slug,neighborhood_slug,created_at_month,title,description,price_value,credit_value,rent_value,building_size HAVING COUNT(*)>1)'''))
checks={'readme_expected_rows':1000000,'actual_rows':row_count,'row_count_matches_readme':row_count==1000000,'readme_claimed_columns':57,'actual_source_columns':len(cols),'column_count_matches_readme':len(cols)==57,'parquet_hashes_verified':True,'no_rows_dropped_clean_full':True,'currency_unit_assumed':False,'listing_price_treated_as_transaction_truth':False,'candidate_duplicate_excess_rows_key_fields':dups}
manifest={'run_at_utc':datetime.now(timezone.utc).isoformat(),'source':{'dataset':'divarofficial/real_estate_ads','license':'ODbL','csv_sha256':'e5760fe1325a195e6682c371457bfecd51d255c518756e3cbea234b8163a801f','csv_size_bytes':780721338,'parquet_conversion_commit':'e6e201dd5e4ea21cbd615746748c155f4628ed7b','files':[{**s,'verified_sha256':sh(RAW/s['name'])} for s in FILES],'semantic_locks':['listing/asking data, not transaction truth','currency unit not explicit in README: keep raw_unit','README says randomized sample, not complete Divar census']},'coverage':coverage,'price_context':{'residential_sale_cat2':res_cat,'global_ppsqm_p001':lo,'global_ppsqm_p999':hi,'unit':'RAW_DATASET_CURRENCY_UNIT_UNKNOWN'},'checks':checks,'cleaning':{'rows_removed':0,'all_source_columns_preserved':True,'helpers':['title_norm','description_norm','asking_price_per_sqm_raw_unit','created_month_date','price_presence_flag','building_size_flag'],'text':'Arabic ya/kaf normalized; whitespace collapsed; originals retained','robust_price':'0.1%-99.9% global pp-sqm only for robust aggregate; no deletion from clean_full'}}
(REP/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2,default=str),encoding='utf-8'); (REP/'null_profile.json').write_text(json.dumps(nulls,ensure_ascii=False,indent=2),encoding='utf-8'); (REP/'quality_report.json').write_text(json.dumps({'coverage':coverage,'checks':checks,'price_context':manifest['price_context']},ensure_ascii=False,indent=2,default=str),encoding='utf-8')
for name,sql in {'cat2_counts.csv':queries['cat2_counts'],'top_cities.csv':'SELECT city_slug,COUNT(*) n FROM raw GROUP BY 1 ORDER BY n DESC LIMIT 100','deed_type_counts.csv':queries['deed_type_counts'], 'claim_patterns.csv':f"SELECT * FROM read_parquet('{escpath(REP/'claim_patterns.parquet')}') ORDER BY matched_rows DESC"}.items(): con.execute(f"COPY ({sql}) TO '{escpath(REP/name)}' (HEADER,DELIMITER ',')")
(REP/'README_FA.md').write_text(f'''# استخراج رسمی املاک دیوار برای اطلس قرائن\n\nمنبع `divarofficial/real_estate_ads`، مجوز ODbL. تمام **{row_count:,}** ردیف خوانده شد. ستون‌های منبع: **{len(cols)}**. شهرها: **{coverage['cities']}**. بازه واقعی created_at_month: **{coverage['date_min']} تا {coverage['date_max']}**.\n\nقفل: `price_value` قیمت آگهی است نه معامله؛ واحد پول در README صریح نیست و در خروجی `raw_unit` مانده است. در clean_full هیچ ردیفی حذف نشده و همه ستون‌های منبع حفظ شده‌اند.\n''',encoding='utf-8')
print('FINAL',json.dumps({'rows':row_count,'cols':len(cols),'cities':coverage['cities'],'date_min':coverage['date_min'],'date_max':coverage['date_max'],'residential_sale_cat2':res_cat,'checks':checks},ensure_ascii=False,default=str),flush=True)
