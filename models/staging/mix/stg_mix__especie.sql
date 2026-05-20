-- ===========================================================================
-- stg_mix__especie.sql
-- ===========================================================================
-- CAPA:   Staging Mix (Silver normalizado)
-- FUENTE: ref('stg_especies__catalogo')
--         ref('stg_mix__taxonomia_familia')
--         ref('stg_mix__estado_conservacion')
--         ref('stg_mix__tipo_migracion')
--         ref('stg_mix__cites_apendice')
-- MATERIALIZACIÓN: view
--
-- DIAGRAMA:
--   especie {
--     id_especie
--     nombre_cientifico
--     nombre_comun_es
--     nombre_comun_en
--     id_familia
--     id_estado_iucn
--     id_estado_espana
--     endemismo
--     id_tipo_migracion
--     id_cites
--   }
-- ===========================================================================

with catalogo as (

    select *
    from {{ ref('stg_especies__catalogo') }}

),

familia as (

    select
          id_familia
        , nombre_familia
    from {{ ref('stg_mix__taxonomia_familia') }}

),

estado as (

    select
          id_estado
        , codigo
    from {{ ref('stg_mix__estado_conservacion') }}

),

tipo_migracion as (

    select
          id_tipo_migracion
        , nombre
    from {{ ref('stg_mix__tipo_migracion') }}

),

cites as (

    select
          id_cites
        , apendice
    from {{ ref('stg_mix__cites_apendice') }}

)

select
      {{ dbt_utils.generate_surrogate_key(['cat.nombre_cientifico']) }}
                                                        as id_especie

    , cat.nombre_cientifico
    , cat.nombre_comun_es
    , cat.nombre_comun_en

    , fam.id_familia

    , est_iucn.id_estado                                as id_estado_iucn
    , est_esp.id_estado                                 as id_estado_espana

    , cat.endemismo
    , tm.id_tipo_migracion

    , cit.id_cites

    , cat.amenaza_raw

from catalogo cat

left join familia fam
       on trim(lower(cat.nombre_familia)) = trim(lower(fam.nombre_familia))

left join estado est_iucn
       on cat.estado_iucn = est_iucn.codigo

left join estado est_esp
       on cat.estado_espana = est_esp.codigo

left join tipo_migracion tm
       on trim(lower(cat.tipo_migracion)) = trim(lower(tm.nombre))

left join cites cit
       on cat.cites_apendice = cit.apendice