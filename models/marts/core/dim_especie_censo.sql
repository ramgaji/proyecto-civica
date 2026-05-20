-- ===========================================================================
-- dim_especie_censo.sql
-- ===========================================================================
-- CAPA:        Gold — dimensión especies con censo
-- FUENTE:      ref('especie_snapshot')
--              ref('stg_mix__censo_poblacion')
--              ref('stg_mix__taxonomia_familia')
--              ref('stg_mix__taxonomia_clase')
--              ref('stg_mix__estado_conservacion')
--              ref('stg_mix__cites_apendice')
--              ref('stg_mix__tipo_migracion')
-- MATERIALIZACIÓN: table
--
-- DIAGRAMA:
--   dim_especie_censo {
--     id_especie          PK
--     nombre_cientifico
--     nombre_comun_es
--     nombre_clase
--     nombre_familia
--     estado_iucn
--     estado_espana
--     endemismo
--     es_migratoria
--     cites_apendice
--   }
--
-- DECISIÓN — INNER JOIN censo_poblacion:
--   Subconjunto de dim_especie restringido a especies con al menos
--   un censo. Evita exponer el catálogo completo en el contexto
--   de análisis de poblaciones.
-- ===========================================================================
with especie as (

    select *
    from {{ ref('especie_snapshot') }}
    where dbt_valid_to is null

),

familia as (

    select
          id_familia
        , nombre_familia
        , id_clase
    from {{ ref('stg_mix__taxonomia_familia') }}

),

clase as (

    select
          id_clase
        , nombre_clase
    from {{ ref('stg_mix__taxonomia_clase') }}

),

estado as (

    select
          id_estado
        , codigo
    from {{ ref('stg_mix__estado_conservacion') }}

),

cites as (

    select
          id_cites
        , apendice
    from {{ ref('stg_mix__cites_apendice') }}

),

migracion as (

    select
          id_tipo_migracion
        , nombre
    from {{ ref('stg_mix__tipo_migracion') }}

)

select distinct
      esp.id_especie
    , esp.nombre_cientifico
    , esp.nombre_comun_es
    , cla.nombre_clase
    , fam.nombre_familia
    , est_iucn.codigo  as estado_iucn
    , est_esp.codigo   as estado_espana
    , esp.endemismo
    , case
        when mig.nombre is null then false
        else true
      end              as es_migratoria
    , cit.apendice     as cites_apendice

from especie esp

inner join {{ ref('stg_mix__censo_poblacion') }} cen
        on esp.id_especie = cen.id_especie

left join familia fam
       on esp.id_familia = fam.id_familia

left join clase cla
       on fam.id_clase = cla.id_clase

left join estado est_iucn
       on esp.id_estado_iucn = est_iucn.id_estado

left join estado est_esp
       on esp.id_estado_espana = est_esp.id_estado

left join cites cit
       on esp.id_cites = cit.id_cites

left join migracion mig
       on esp.id_tipo_migracion = mig.id_tipo_migracion