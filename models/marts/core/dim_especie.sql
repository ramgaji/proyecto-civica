-- ===========================================================================
-- dim_especie.sql
-- ===========================================================================

with snapshot as (

    select *
    from {{ ref('especie_snapshot') }}
    where dbt_current_flag = 'Y'

),

familia as (

    select *
    from {{ ref('stg_mix__taxonomia_familia') }}

),

clase as (

    select *
    from {{ ref('stg_mix__taxonomia_clase') }}

),

estado as (

    select *
    from {{ ref('stg_mix__estado_conservacion') }}

),

migracion as (

    select *
    from {{ ref('stg_mix__tipo_migracion') }}

),

cites as (

    select *
    from {{ ref('stg_mix__cites_apendice') }}

)

select
      snap.id_especie
    , snap.nombre_cientifico
    , snap.nombre_comun_es
    , snap.nombre_comun_en
    , fam.nombre_familia
    , cla.nombre_clase
    , est_iucn.codigo as estado_iucn
    , est_esp.codigo  as estado_espana
    , snap.endemismo

    , case
        when mig.nombre is null then false
        else true
      end as es_migratoria

    , mig.nombre   as tipo_migracion
    , cit.apendice as cites_apendice

from snapshot snap

left join familia fam
       on snap.id_familia = fam.id_familia

left join clase cla
       on fam.id_clase = cla.id_clase

left join estado est_iucn
       on snap.id_estado_iucn = est_iucn.id_estado

left join estado est_esp
       on snap.id_estado_espana = est_esp.id_estado

left join migracion mig
       on snap.id_tipo_migracion = mig.id_tipo_migracion

left join cites cit
       on snap.id_cites = cit.id_cites