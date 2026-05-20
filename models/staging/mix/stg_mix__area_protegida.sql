-- ===========================================================================
-- stg_mix__area_protegida.sql
-- ===========================================================================
-- CAPA:   Staging Mix (Silver normalizado)
-- FUENTE: ref('stg_avistamientos__areas')
--         ref('stg_mix__provincia')
--         ref('stg_mix__entidad_gestora')
-- MATERIALIZACIÓN: view
--
-- DIAGRAMA:
--   area_protegida {
--     id_area_protegida
--     nombre
--     es_lic
--     es_zepa
--     es_parque_nacional
--     id_provincia
--     id_entidad
--     lat_min
--     lat_max
--     lon_min
--     lon_max
--     superficie_ha
--     anio_declaracion
--     codigo_red_natura
--   }
-- ===========================================================================

with areas as (

    select *
    from {{ ref('stg_avistamientos__areas') }}

),

provincia as (

    select
          id_provincia
        , nombre
    from {{ ref('stg_mix__provincia') }}

),

entidad_gestora as (

    select
          id_entidad
        , nombre
    from {{ ref('stg_mix__entidad_gestora') }}

),

areas_normalizadas as (

    select
          {{ dbt_utils.generate_surrogate_key(['areas.id_area_protegida']) }}
                                                                as id_area_protegida
        , areas.nombre
        , areas.es_lic
        , areas.es_zepa
        , areas.es_parque_nacional
        , prov.id_provincia
        , ent.id_entidad
        , areas.lat_min
        , areas.lat_max
        , areas.lon_min
        , areas.lon_max
        , areas.superficie_ha
        , areas.anio_declaracion
        , areas.codigo_red_natura

    from areas

    left join provincia prov
           on trim(lower(areas.provincia)) = trim(lower(prov.nombre))

    left join entidad_gestora ent
           on trim(lower(areas.entidad_gestora)) = trim(lower(ent.nombre))

)

select * from areas_normalizadas

union all

-- Fila ficticia para avistamientos fuera de área protegida.
-- lat/lon son NULL para que no participe en el join espacial de fct_avistamiento.
-- Se excluye del join con: where id_area_protegida != 'NO_AREA'
select
      'NO_AREA'            as id_area_protegida
    , 'Sin área protegida' as nombre
    , false                as es_lic
    , false                as es_zepa
    , false                as es_parque_nacional
    , null                 as id_provincia
    , null                 as id_entidad
    , null                 as lat_min
    , null                 as lat_max
    , null                 as lon_min
    , null                 as lon_max
    , null                 as superficie_ha
    , null                 as anio_declaracion
    , null                 as codigo_red_natura