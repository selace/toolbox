-- Base specific query, to report on the used space by the backup pieces, split per ZFS pool
-- order by db name, db unique name, dbid and pool
-- the reported sizes are the sizes seen by rman, thus before any filesystem compression or deduplication

-- this query must be run against the rman catalog repository

set linesize 150
set pages 50000

column name format a10
column db_unique_name format a30
column pool format a5
column GB format 9G999G999D99

compute sum of GB on db_unique_name
compute sum of GB on report

break on dbid on name on db_unique_name skip 1 on pool on report

with backup_files
as
( select
    db_key,
    site_key,
    bytes,
    replace(regexp_substr(regexp_substr(bpd.handle,'/[^/]+/',2),'_[^_]+',1,2),'_') pool
  from
    rc_backup_piece_details   bpd
  where
    device_type = 'DISK'
)
select
  db.dbid,
  db.name,
  st.db_unique_name,
  bf.pool,
  sum(bf.bytes)/1024/1024/1024 GB
from
  backup_files   bf,
  rc_site        st,
  rc_database    db
where
  bf.site_key = st.site_key
  and db.db_key = bf.db_key
group by
  db.dbid,
  db.name,
  st.db_unique_name,
  bf.pool
order by
  db.name,
  st.db_unique_name,
  db.dbid,
  bf.pool
;

clear breaks
clear computes
