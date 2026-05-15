-- ===========================================================================
-- stg_mix__provincia.sql
-- ===========================================================================
-- CAPA:   Staging Mix (Silver normalizado)
-- FUENTE: ref('provincia_ccaa')  ← seed
-- SCHEMA: {{ env_var('DBT_ENVIRONMENTS') }}_SILVER_DB.mix
-- MATERIALIZACIÓN: view
--
-- OBJETIVO:
--   Expone el seed de provincias como modelo Silver. Cubre las 50 provincias
--   españolas más las regiones de Francia, Portugal y Marruecos que aparecen
--   en los datos de avistamientos y censos.
--
--   Usado como lookup por stg_mix__localizacion y stg_mix__censo_poblacion
--   para enriquecer con CCAA y código INE.
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