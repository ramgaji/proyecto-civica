-- ===========================================================================
-- stg_mix__taxonomia_familia.sql
-- ===========================================================================
-- CAPA:   Staging Mix (Silver normalizado)
-- FUENTE: ref('stg_especies__catalogo') + ref('stg_mix__taxonomia_orden')
-- SCHEMA: {{ env_var('DBT_ENVIRONMENTS') }}_SILVER_DB.mix
-- MATERIALIZACIÓN: view
--
-- OBJETIVO:
--   Extrae los valores únicos de familia taxonómica y los enlaza con su orden
--   padre mediante FK. Tercera tabla de la jerarquía taxonómica.
-- ===========================================================================

with src as (

    select distinct
          orden
        , familia
    from {{ ref('stg_especies__catalogo') }}
    where familia is not null

),

orden as (

    select id_orden, nombre_orden
    from {{ ref('stg_mix__taxonomia_orden') }}

)

select
      {{ dbt_utils.generate_surrogate_key(['src.familia']) }}  as id_familia
    , src.familia                                               as nombre_familia
    , orden.id_orden

from src
left join orden
       on src.orden = orden.nombre_orden