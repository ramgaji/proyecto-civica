-- ===========================================================================
-- stg_mix__taxonomia_clase.sql
-- ===========================================================================
-- CAPA:   Staging Mix (Silver normalizado)
-- FUENTE: ref('stg_especies__catalogo')
-- MATERIALIZACIÓN: view
--
-- DIAGRAMA:
--   taxonomia_clase {
--     id_clase
--     nombre_clase
--   }
-- ===========================================================================

with src as (

    select distinct
          nombre_clase
    from {{ ref('stg_especies__catalogo') }}
    where nombre_clase is not null

)

select
      {{ dbt_utils.generate_surrogate_key(['nombre_clase']) }} as id_clase
    , nombre_clase

from src