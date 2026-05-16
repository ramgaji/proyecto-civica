-- ===========================================================================
-- dim_provincia.sql
-- ===========================================================================
-- CAPA:   Gold — Dimensiones
-- FUENTE: stg_mix__provincia
--         stg_mix__ccaa
-- SCHEMA: GOLD_DB.dimensions
-- MATERIALIZACIÓN: table
--
-- OBJETIVO:
--   Dimensión de provincia con CCAA desnormalizada.
--   Permite filtrar y agrupar por CCAA en los dashboards sin JOIN adicional.
-- ===========================================================================

with provincia as (

    select *
    from {{ ref('stg_mix__provincia') }}

),

ccaa as (

    select id_ccaa, nombre
    from {{ ref('stg_mix__ccaa') }}

)

select
      prov.id_provincia
    , prov.nombre                                         as nombre_provincia
    , ccaa.nombre                                         as ccaa

from provincia prov
left join ccaa
       on prov.id_ccaa = ccaa.id_ccaa