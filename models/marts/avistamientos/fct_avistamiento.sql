-- ===========================================================================
-- fct_avistamiento.sql
-- ===========================================================================
-- CAPA:   Gold — tabla de hechos principal
-- FUENTE: ref('stg_mix__avistamiento')
--         ref('stg_mix__localizacion')
--         ref('stg_mix__area_protegida')
-- MATERIALIZACIÓN: table
--
-- GRANULARIDAD: una fila por avistamiento.
--
-- NOTA — hora_local y franja horaria:
--   Tras corregir dim_fecha (granularidad estricta por fecha), la hora
--   y la franja dia/tarde/noche se calculan aquí directamente desde
--   hora_utc aplicando el offset horario de España.
--   Esto mantiene el dato disponible para análisis sin romper la dim.
--
-- NOTA — join espacial bounding box:
--   El join loc × area es no-equi (BETWEEN), por lo que Snowflake aplica
--   nested-loop. QUALIFY resuelve solapamientos de áreas priorizando
--   la figura de mayor protección: parque > zepa > lic.
--   La fila ficticia NO_AREA se excluye del join para no añadir
--   comparaciones innecesarias al nested-loop.
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
    from {{ ref('stg_mix__area_protegida') }}
    -- Excluir fila ficticia del join espacial: lat/lon son NULL
    -- y añadiría N comparaciones inútiles al nested-loop O(N×M)
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
    -- COALESCE: avistamientos fuera de área protegida reciben NO_AREA
    -- en lugar de NULL para mantener la relación en Power BI
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