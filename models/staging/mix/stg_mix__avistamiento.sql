-- ===========================================================================
-- stg_mix__avistamiento.sql
-- ===========================================================================
-- CAPA:   Staging Mix (Silver normalizado)
-- FUENTE: ref('stg_avistamientos__observaciones')
--         ref('stg_mix__especie')
--         ref('stg_mix__localizacion')
-- MATERIALIZACIÓN: incremental (merge)
--
-- DIAGRAMA:
--   avistamiento {
--     id_avistamiento
--     id_avistamiento_natural
--     fecha
--     hora_utc
--     id_especie
--     id_localizacion
--     verificado
--     fuente
--     precision_gps_m
--     es_catalogada
--   }
-- ===========================================================================

{{ config(
    materialized='incremental',
    unique_key='id_avistamiento_natural',
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
        , id_avistamiento_natural
    from {{ ref('stg_mix__localizacion') }}

)

select
      {{ dbt_utils.generate_surrogate_key(['obs.id_avistamiento_natural', 'obs.fuente']) }}
                                                        as id_avistamiento

    , obs.id_avistamiento_natural
    , obs.fecha
    , obs.hora_utc
    , esp.id_especie
    , loc.id_localizacion
    , obs.verificado
    , obs.fuente
    , obs.precision_gps_m

    , case
        when esp.id_especie is null then false
        else true
      end                                               as es_catalogada

from obs

left join especie esp
       on trim(lower(obs.nombre_cientifico)) = trim(lower(esp.nombre_cientifico))

left join localizacion loc
       on obs.id_avistamiento_natural = loc.id_avistamiento_natural