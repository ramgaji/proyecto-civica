-- ===========================================================================
-- dim_area_protegida.sql
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

    -- Desnormalizado
    , prov.nombre as nombre_provincia
    , ccaa.nombre as ccaa
    , ent.nombre  as entidad_gestora

    -- Bounding box para join espacial en fct_avistamiento
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