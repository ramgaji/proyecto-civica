-- ===========================================================================
-- dim_lugar.sql
-- ===========================================================================
-- CAPA:        Gold — dimensión geográfica
-- FUENTE:      ref('stg_mix__provincia')
--              ref('stg_mix__ccaa')
-- MATERIALIZACIÓN: table
--
-- DIAGRAMA:
--   dim_lugar {
--     id_provincia   PK
--     provincia
--     ccaa
--   }
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
    , ccaa.nombre as ccaa

from provincia prov

left join ccaa
       on prov.id_ccaa = ccaa.id_ccaa