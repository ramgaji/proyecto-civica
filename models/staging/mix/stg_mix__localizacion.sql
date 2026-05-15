-- ===========================================================================
-- stg_mix__localizacion.sql
-- ===========================================================================

with obs as (

    select
          id_avistamiento
        , latitud
        , longitud
        , provincia_raw
    from {{ ref('stg_avistamientos__observaciones') }}
    where latitud is not null
      and longitud is not null

),

areas as (

    select
          id_area_protegida
        , es_lic
        , es_zepa
        , es_parque_nacional
        , lat_min
        , lat_max
        , lon_min
        , lon_max
    from {{ ref('stg_mix__area_protegida') }}

),

provincia as (

    select
          id_provincia
        , nombre
    from {{ ref('stg_mix__provincia') }}

),

obs_con_area as (

    select
          obs.id_avistamiento
        , obs.latitud
        , obs.longitud
        , obs.provincia_raw
        , areas.id_area_protegida
        , coalesce(areas.es_lic, false)             as es_lic
        , coalesce(areas.es_zepa, false)            as es_zepa
        , coalesce(areas.es_parque_nacional, false) as es_parque_nacional

    from obs

    left join areas
           on obs.latitud between areas.lat_min and areas.lat_max
          and obs.longitud between areas.lon_min and areas.lon_max

    qualify row_number() over (
        partition by obs.id_avistamiento
        order by
            areas.es_parque_nacional desc nulls last,
            areas.es_zepa desc nulls last,
            areas.es_lic desc nulls last
    ) = 1

)

select
      {{ dbt_utils.generate_surrogate_key(['oca.id_avistamiento']) }} as id_localizacion
    , oca.id_avistamiento
    , oca.latitud
    , oca.longitud
    , prov.id_provincia
    , oca.id_area_protegida
    , oca.es_lic
    , oca.es_zepa
    , oca.es_parque_nacional

from obs_con_area oca

left join provincia prov
       on trim(lower(oca.provincia_raw)) = trim(lower(prov.nombre))