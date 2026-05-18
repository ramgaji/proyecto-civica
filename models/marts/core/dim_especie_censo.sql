-- dim_especie_censo.sql
with especie as (

    select *
    from {{ ref('stg_mix__especie') }}

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