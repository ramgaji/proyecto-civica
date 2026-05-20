-- ===========================================================================
-- stg_mix__provincia.sql
-- ===========================================================================
-- CAPA:        Staging Mix (Silver normalizado)
-- FUENTE:      ref('provincia_ccaa')  ← seed
--              ref('stg_mix__ccaa')
-- SCHEMA:      {{ env_var('DBT_ENVIRONMENTS') }}_SILVER_DB.mix
-- MATERIALIZACIÓN: view
--
-- DIAGRAMA:
--   provincia {
--     id_provincia   PK  natural (INE)
--     nombre
--     id_ccaa        FK  nullable — zonas fronterizas sin CCAA asignada
--   }
-- ===========================================================================


with provincias as (

    select
          id_provincia
        , trim(nombre) as nombre
        , trim(ccaa)   as ccaa
    from {{ ref('provincia_ccaa') }}

),

ccaa as (

    select
          id_ccaa
        , nombre
    from {{ ref('stg_mix__ccaa') }}

)

select
      p.id_provincia
    , p.nombre
    , c.id_ccaa

from provincias p

left join ccaa c
       on trim(lower(p.ccaa)) = trim(lower(c.nombre))