-- ===========================================================================
-- dim_fecha.sql
-- ===========================================================================
-- CAPA:        Gold — dimensión temporal
-- FUENTE:      ref('stg_mix__avistamiento')
-- MATERIALIZACIÓN: table
--
-- DIAGRAMA:
--   dim_fecha {
--     fecha         PK
--     anio
--     mes
--     estacion
--     dia_semana
--     nombre_mes
--   }

with fechas as (

    select distinct
          fecha
    from {{ ref('stg_mix__avistamiento') }}
    where fecha is not null

)

select
      fecha

    , extract(year from fecha)  as anio
    , extract(month from fecha) as mes

    , case
        when extract(month from fecha) in (12, 1, 2)  then 'Invierno'
        when extract(month from fecha) in (3, 4, 5)   then 'Primavera'
        when extract(month from fecha) in (6, 7, 8)   then 'Verano'
        when extract(month from fecha) in (9, 10, 11) then 'Otoño'
      end as estacion

    , dayofweek(fecha) as dia_semana

    , case extract(month from fecha)
        when 1  then 'Enero'
        when 2  then 'Febrero'
        when 3  then 'Marzo'
        when 4  then 'Abril'
        when 5  then 'Mayo'
        when 6  then 'Junio'
        when 7  then 'Julio'
        when 8  then 'Agosto'
        when 9  then 'Septiembre'
        when 10 then 'Octubre'
        when 11 then 'Noviembre'
        when 12 then 'Diciembre'
      end as nombre_mes

from fechas