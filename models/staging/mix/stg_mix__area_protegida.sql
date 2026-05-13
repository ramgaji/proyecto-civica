-- ===========================================================================
-- stg_mix__area_protegida.sql
-- ===========================================================================
-- CAPA:   Staging Mix (Silver normalizado)
-- FUENTE: ref('stg_avistamientos__areas')
--         ref('stg_mix__provincia')
-- SCHEMA: {{ env_var('DBT_ENVIRONMENTS') }}_SILVER_DB.mix
-- MATERIALIZACIÓN: view
--
-- OBJETIVO:
--   Tabla normalizada de áreas protegidas con FK a provincia.
--   Mantiene el bounding box (lat/lon min/max) para el join espacial
--   con avistamientos en stg_mix__localizacion.
--
-- SURROGATE KEY:
--   Se genera sobre id_area del staging (que viene del CSV original).
--   Se mantiene el id original como natural key para trazabilidad.
-- ===========================================================================

with areas as (

    select *
    from {{ ref('stg_avistamientos__areas') }}

),

provincia as (

    select id_provincia, nombre, pais
    from {{ ref('stg_mix__provincia') }}

)

select
      {{ dbt_utils.generate_surrogate_key(['areas.id_area']) }}
                                                          as id_area_protegida
    , areas.id_area                                       as id_area_natural
    , areas.nombre
    , areas.tipo_area
    , areas.es_lic
    , areas.es_zepa
    , areas.es_parque_nacional
    , areas.pais
    , prov.id_provincia
    , areas.lat_min
    , areas.lat_max
    , areas.lon_min
    , areas.lon_max
    , areas.superficie_ha
    , areas.anio_declaracion
    , areas.entidad_gestora
    , areas.codigo_red_natura

from areas
left join provincia prov
       on trim(lower(areas.provincia)) = trim(lower(prov.nombre))
      and trim(lower(areas.pais))      = trim(lower(prov.pais))