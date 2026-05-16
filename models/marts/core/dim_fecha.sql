-- ===========================================================================
-- dim_fecha.sql
-- ===========================================================================

with fechas as (

    select distinct
          fecha

        , case
            when extract(month from fecha) between 4 and 10
                then mod(date_part('hour', hora_utc) + 2, 24)

            else
                mod(date_part('hour', hora_utc) + 1, 24)

          end as hora

    from {{ ref('stg_mix__avistamiento') }}

)

select
      fecha

    , extract(year from fecha)  as anio
    , extract(month from fecha) as mes

    , case
        when extract(month from fecha) in (12, 1, 2) then 'Invierno'
        when extract(month from fecha) in (3, 4, 5) then 'Primavera'
        when extract(month from fecha) in (6, 7, 8) then 'Verano'
        when extract(month from fecha) in (9, 10, 11) then 'Otoño'
      end as estacion

    , dayofweek(fecha) as dia_semana

    , case extract(month from fecha)
        when 1 then 'Enero'
        when 2 then 'Febrero'
        when 3 then 'Marzo'
        when 4 then 'Abril'
        when 5 then 'Mayo'
        when 6 then 'Junio'
        when 7 then 'Julio'
        when 8 then 'Agosto'
        when 9 then 'Septiembre'
        when 10 then 'Octubre'
        when 11 then 'Noviembre'
        when 12 then 'Diciembre'
      end as nombre_mes

    , hora

    , case
        when hora between 7 and 14 then 'Dia'
        when hora between 15 and 20 then 'Tarde'
        else 'Noche'
      end as dia_tarde_noche

from fechas