-- dim_ccaa.sql
select
      id_ccaa
    , nombre as ccaa
from {{ ref('stg_mix__ccaa') }}