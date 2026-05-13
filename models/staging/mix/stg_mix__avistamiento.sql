-- ===========================================================================
-- stg_mix__avistamiento.sql
-- ===========================================================================
-- CAPA:   Staging Mix (Silver normalizado)
-- FUENTE: ref('stg_avistamientos__observaciones')
--         ref('stg_mix__especie')
--         ref('stg_mix__localizacion')
--         ref('stg_mix__observador')
-- SCHEMA: {{ env_var('DBT_ENVIRONMENTS') }}_SILVER_DB.mix
-- MATERIALIZACIÓN: incremental (merge)
--
-- OBJETIVO:
--   Tabla de hechos Silver de avistamientos. Integra observaciones con
--   especie, localización y observador mediante FKs normalizadas.
--   Es el modelo que alimenta directamente fct_avistamiento en Gold.
--
-- POR QUÉ INCREMENTAL AQUÍ Y NO EN GOLD:
--   iNaturalist permite que expertos corrijan identificaciones después de
--   publicar. Con merge, si un avistamiento ya existe se actualiza
--   (ej: especie corregida), si no existe se inserta. Materializar el
--   incremental en Silver evita recalcular dos veces el mismo dato.
--
-- ESTRATEGIA MERGE:
--   unique_key = id_avistamiento_natural (ID original de iNaturalist)
--   Watermark  = fecha (solo procesa registros nuevos o modificados)
--   on_schema_change = 'fail' — si cambia el schema avisa explícitamente
--
-- COMANDOS:
--   dbt run --select stg_mix__avistamiento                    <- incremental
--   dbt run --select stg_mix__avistamiento --full-refresh     <- reconstruir
--
-- GRANULARIDAD: una fila por avistamiento.
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
        -- Solo registros más nuevos que el máximo ya cargado.
        -- Margen de 1 hora para capturar late-arriving data —
        -- registros que llegaron con retraso al sistema fuente.
        where fecha > (
            select dateadd('hour', -1, coalesce(max(fecha), '2020-01-01'::date))
            from {{ this }}
        )
    {% endif %}

),

especie as (

    select id_especie, nombre_cientifico
    from {{ ref('stg_mix__especie') }}

),

localizacion as (

    select id_localizacion, id_avistamiento
    from {{ ref('stg_mix__localizacion') }}

),

observador as (

    select id_observador, nombre
    from {{ ref('stg_mix__observador') }}

)

select
      {{ dbt_utils.generate_surrogate_key(['obs.id_avistamiento']) }}
                                                          as id_avistamiento
    -- Natural key: ID original de iNaturalist
    -- unique_key del merge — garantiza idempotencia
    , obs.id_avistamiento                                 as id_avistamiento_natural
    , obs.fecha
    , obs.hora_utc
    , esp.id_especie
    , loc.id_localizacion
    , obsr.id_observador
    , obs.verificado
    , obs.fuente
    , obs.precision_gps_m

    -- Campo de clasificación para Gold
    -- Permite filtrar por categoría sin JOIN adicional
    , case
        when esp.id_especie is null then 'Sin catalogar'
        else 'Catalogada'
      end                                                 as estado_catalogo

from obs
left join especie esp
       on trim(lower(obs.nombre_cientifico)) = trim(lower(esp.nombre_cientifico))
left join localizacion loc
       on obs.id_avistamiento = loc.id_avistamiento
left join observador obsr
       on trim(lower(obs.observador_raw)) = trim(lower(obsr.nombre))