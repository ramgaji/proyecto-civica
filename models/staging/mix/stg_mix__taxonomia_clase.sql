-- ===========================================================================
-- stg_mix__taxonomia_clase.sql
-- ===========================================================================
-- CAPA:   Staging Mix (Silver normalizado)
-- FUENTE: ref('stg_especies__catalogo')
-- SCHEMA: {{ env_var('DBT_ENVIRONMENTS') }}_SILVER_DB.mix
-- MATERIALIZACIÓN: view
--
-- OBJETIVO:
--   Extrae los valores únicos de clase taxonómica del catálogo y genera
--   una surrogate key con dbt_utils. Primera tabla de la jerarquía
--   taxonómica: clase → orden → familia → especie.
--
-- SURROGATE KEY:
--   Se usa dbt_utils.generate_surrogate_key(['clase']) en vez de un entero
--   manual porque es reproducible — el mismo input siempre genera el mismo
--   hash MD5, independientemente del orden de inserción.
-- ===========================================================================

with src as (

    select distinct
        clase
    from {{ ref('stg_especies__catalogo') }}
    where clase is not null

)

select
      {{ dbt_utils.generate_surrogate_key(['clase']) }}  as id_clase
    , clase                                               as nombre_clase

from src