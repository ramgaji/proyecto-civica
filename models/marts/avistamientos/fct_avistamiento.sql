-- ===========================================================================
-- fct_avistamiento.sql
-- ===========================================================================

with avi as (

    select *
    from {{ ref('stg_mix__avistamiento') }}

),

loc as (

    select *
    from {{ ref('stg_mix__localizacion') }}

),

area as (

    select *
    from {{ ref('dim_area_protegida') }}

),

avistamiento_con_area as (

    select
          loc.id_avistamiento
        , loc.latitud
        , loc.longitud
        , loc.id_provincia
        , area.id_area_protegida
        , coalesce(area.es_lic, false)             as es_lic
        , coalesce(area.es_zepa, false)            as es_zepa
        , coalesce(area.es_parque_nacional, false) as es_parque_nacional

    from loc

    left join area
           on loc.latitud between area.lat_min and area.lat_max
          and loc.longitud between area.lon_min and area.lon_max

    qualify row_number() over (
        partition by loc.id_avistamiento
        order by
            area.es_parque_nacional desc nulls last,
            area.es_zepa desc nulls last,
            area.es_lic desc nulls last
    ) = 1

)

select
      avi.id_avistamiento
    , avi.id_especie
    , aca.id_provincia
    , aca.id_area_protegida
    , avi.fecha
    , avi.hora_utc
    , aca.latitud
    , aca.longitud
    , avi.verificado
    , avi.es_catalogada
    , avi.precision_gps_m
    , aca.es_lic
    , aca.es_zepa
    , aca.es_parque_nacional

    , case
        when aca.id_area_protegida is not null then true
        else false
      end as dentro_area_protegida

from avi

left join avistamiento_con_area aca
       on avi.id_avistamiento = aca.id_avistamiento