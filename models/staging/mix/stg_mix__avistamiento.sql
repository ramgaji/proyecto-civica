-- stg_mix__avistamiento.sql
-- ===========================================================================
-- CAPA:        Staging Mix (Silver normalizado)
-- FUENTE:      ref('stg_avistamientos__observaciones')
--              ref('stg_mix__especie')
--              ref('stg_mix__localizacion')
-- MATERIALIZACIÓN: incremental (merge)
--
-- DIAGRAMA:
--   avistamiento {
--     id_avistamiento   PK
--     fecha
--     hora_utc
--     id_especie        FK nullable
--     id_localizacion   FK
--     verificado
--     precision_gps_m
--     es_catalogada
--   }
--
-- DECISIÓN — incremental merge:
--   unique_key=id_avistamiento porque iNaturalist puede actualizar
--   observaciones existentes (verificación, corrección de especie).
--   Watermark sobre fecha con overlap de -1h para cubrir registros
--   con lag de sincronización. on_schema_change=fail para detectar
--   cambios de esquema de forma ruidosa, no silenciosa.

{{ config(
    materialized='incremental',
    unique_key='id_avistamiento',
    incremental_strategy='merge',
    on_schema_change='fail'
) }}

with obs as (

    select *
    from {{ ref('stg_avistamientos__observaciones') }}

    {% if is_incremental() %}
        where fecha > (
            select dateadd('hour', -1, coalesce(max(fecha), '2020-01-01'::date))
            from {{ this }}
        )
    {% endif %}

),

especie as (

    select
          id_especie
        , nombre_cientifico
    from {{ ref('stg_mix__especie') }}

),

localizacion as (

    select
          id_localizacion
        , id_avistamiento
    from {{ ref('stg_mix__localizacion') }}

)

select
      obs.id_avistamiento
    , obs.fecha
    , obs.hora_utc
    , esp.id_especie
    , loc.id_localizacion
    , obs.verificado
    , obs.precision_gps_m
    , case
        when esp.id_especie is null then false
        else true
      end as es_catalogada

from obs

left join especie esp
       on trim(lower(obs.nombre_cientifico)) = trim(lower(esp.nombre_cientifico))

left join localizacion loc
       on obs.id_avistamiento = loc.id_avistamiento