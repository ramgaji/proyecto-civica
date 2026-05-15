-- ===========================================================================
-- stg_mix__taxonomia_familia.sql
-- ===========================================================================
-- CAPA:   Staging Mix (Silver normalizado)
-- FUENTE: ref('stg_especies__catalogo')
--         ref('stg_mix__taxonomia_clase')
-- MATERIALIZACIÓN: view
--
-- DIAGRAMA:
--   taxonomia_familia {
--     id_familia
--     nombre_familia
--     id_clase
--   }
-- ===========================================================================

with src as (

    select distinct
          nombre_familia
        , nombre_clase
    from {{ ref('stg_especies__catalogo') }}
    where nombre_familia is not null

),

clase as (

    select
          id_clase
        , nombre_clase
    from {{ ref('stg_mix__taxonomia_clase') }}

)

select
      {{ dbt_utils.generate_surrogate_key(['src.nombre_familia', 'src.nombre_clase']) }}
                                                        as id_familia

    , src.nombre_familia
    , clase.id_clase

from src

left join clase
       on trim(lower(src.nombre_clase)) = trim(lower(clase.nombre_clase))