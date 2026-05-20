-- ===========================================================================
-- stg_mix__amenaza.sql
-- ===========================================================================
-- CAPA:   Staging Mix (Silver normalizado)
-- FUENTE: ref('stg_mix__especie')
--         ref('stg_mix__tipo_amenaza')
-- MATERIALIZACIÓN: view

--
-- DIAGRAMA:
--   amenaza {
--     id_especie
--     id_tipo_amenaza
--   }
-- ===========================================================================

with especie as (

    select
          id_especie
        , amenaza_raw
    from {{ ref('stg_mix__especie') }}
    where amenaza_raw is not null

),

amenazas_split as (

    select
          esp.id_especie
        , trim(s.value) as tipo_amenaza_raw
    from especie esp,
         lateral split_to_table(esp.amenaza_raw, '|') s
    where trim(s.value) != ''

),

tipo_amenaza as (

    select
          id_tipo_amenaza
        , nombre
    from {{ ref('stg_mix__tipo_amenaza') }}

)

select distinct
      a.id_especie
    , ta.id_tipo_amenaza

from amenazas_split a
inner join tipo_amenaza ta
        on trim(lower(a.tipo_amenaza_raw)) = trim(lower(ta.nombre))