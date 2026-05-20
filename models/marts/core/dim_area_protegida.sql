-- ===========================================================================
-- dim_area_protegida.sql
-- ===========================================================================
-- CAPA:        Gold — dimensión áreas protegidas
-- FUENTE:      ref('stg_mix__area_protegida')
--              ref('stg_mix__provincia')
--              ref('stg_mix__ccaa')
--              ref('stg_mix__entidad_gestora')
-- MATERIALIZACIÓN: table
--
-- DIAGRAMA:
--   dim_area_protegida {
--     id_area_protegida   PK
--     nombre
--     es_lic
--     es_zepa
--     es_parque_nacional
--     nombre_provincia
--     ccaa
--     entidad_gestora
--     lat_min
--     lat_max
--     lon_min
--     lon_max
--   }
-- ===========================================================================

with area as (

    select *
    from {{ ref('stg_mix__area_protegida') }}

),

provincia as (

    select *
    from {{ ref('stg_mix__provincia') }}

),

ccaa as (

    select *
    from {{ ref('stg_mix__ccaa') }}

),

entidad as (

    select *
    from {{ ref('stg_mix__entidad_gestora') }}

)

select
      area.id_area_protegida
    , area.nombre
    , area.es_lic
    , area.es_zepa
    , area.es_parque_nacional


    , prov.nombre as nombre_provincia
    , ccaa.nombre as ccaa
    , ent.nombre  as entidad_gestora


    , area.lat_min
    , area.lat_max
    , area.lon_min
    , area.lon_max

from area

left join provincia prov
       on area.id_provincia = prov.id_provincia

left join ccaa
       on prov.id_ccaa = ccaa.id_ccaa

left join entidad ent
       on area.id_entidad = ent.id_entidad