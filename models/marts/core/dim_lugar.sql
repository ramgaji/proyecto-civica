-- ===========================================================================
-- dim_lugar.sql
-- ===========================================================================

with provincia as (

    select *
    from {{ ref('stg_mix__provincia') }}

),

ccaa as (

    select *
    from {{ ref('stg_mix__ccaa') }}

)

select
      prov.id_provincia
    , prov.nombre as provincia
    , prov.id_ccaa
    , ccaa.nombre as ccaa

from provincia prov

left join ccaa
       on prov.id_ccaa = ccaa.id_ccaa