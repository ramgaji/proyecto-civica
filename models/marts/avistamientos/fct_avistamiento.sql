-- ===========================================================================
-- fct_avistamiento.sql
-- ===========================================================================
-- CAPA:        Gold — tabla de hechos principal
-- FUENTE:      ref('stg_mix__avistamiento')
--              ref('stg_mix__localizacion')
--              ref('stg_mix__area_protegida')
-- MATERIALIZACIÓN: table
--
-- DIAGRAMA:
--   fct_avistamiento {
--     id_avistamiento     PK
--     id_especie          FK
--     id_provincia        FK
--     id_area_protegida   FK  'NO_AREA' si fuera de zona
--     fecha
--     hora_utc
--     hora_local
--     franja_horaria
--     latitud
--     longitud
--     verificado
--     precision_gps_m
--     es_lic
--     es_zepa
--     es_parque_nacional
--     dentro_area_protegida
--   }

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
    from {{ ref('stg_mix__area_protegida') }}

    where id_area_protegida != 'NO_AREA'

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
           on loc.latitud  between area.lat_min and area.lat_max
          and loc.longitud between area.lon_min and area.lon_max

    qualify row_number() over (
        partition by loc.id_avistamiento
        order by
            area.es_parque_nacional desc nulls last,
            area.es_zepa            desc nulls last,
            area.es_lic             desc nulls last
    ) = 1

)

select
      avi.id_avistamiento
    , avi.id_especie
    , aca.id_provincia

    , coalesce(aca.id_area_protegida, 'NO_AREA')  as id_area_protegida
    , avi.fecha
    , avi.hora_utc

    , case
        when extract(month from avi.fecha) between 4 and 10
            then mod(date_part('hour', avi.hora_utc) + 2, 24)
        else
            mod(date_part('hour', avi.hora_utc) + 1, 24)
      end                                                  as hora_local

    , case
        when case
               when extract(month from avi.fecha) between 4 and 10
                   then mod(date_part('hour', avi.hora_utc) + 2, 24)
               else mod(date_part('hour', avi.hora_utc) + 1, 24)
             end between 7  and 14 then 'Dia'
        when case
               when extract(month from avi.fecha) between 4 and 10
                   then mod(date_part('hour', avi.hora_utc) + 2, 24)
               else mod(date_part('hour', avi.hora_utc) + 1, 24)
             end between 15 and 20 then 'Tarde'
        else 'Noche'
      end                                                  as franja_horaria

    , aca.latitud
    , aca.longitud
    , avi.verificado
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

where avi.es_catalogada = true