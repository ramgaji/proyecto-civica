-- ===========================================================================
-- stg_especies__censos.sql
-- ===========================================================================
-- CAPA:   Staging (Silver)
-- FUENTE: source('especies', 'censos')
-- MATERIALIZACIÓN: view
--
-- OBJETIVO:
--   Limpieza mínima de censos para construir:
--   - censo_poblacion
--   - entidad_gestora
--   - provincia / ccaa
-- ===========================================================================

with src as (

    select *
    from {{ source('especies', 'censos') }}

),

cleaned as (

    select

        -- ── ESPECIE ─────────────────────────────────────────────────────────
          trim(especie_nombre_cientifico)                      as nombre_cientifico

        -- ── GEOGRAFÍA ──────────────────────────────────────────────────────
        , trim(provincia)                                      as provincia

        , trim(
            replace(replace(replace(replace(
                ccaa,
            'Andalucia',        'Andalucía'),
            'Castilla y Leon',  'Castilla y León'),
            'Cataluna',         'Cataluña'),
            'Aragon',           'Aragón')
          )                                                    as ccaa

        -- ── ENTIDAD ────────────────────────────────────────────────────────
        , case
            when upper(trim(entidad_responsable))
                 in ('SEO/BIRDLIFE', 'SEO / BIRDLIFE')
                then 'SEO/BirdLife'

            when upper(trim(entidad_responsable)) = 'MITECO'
                then 'MITECO'

            when upper(trim(entidad_responsable)) = 'FEDENCA'
                then 'FEDENCA'

            else trim(entidad_responsable)

          end                                                  as entidad_responsable

        -- ── TIEMPO ─────────────────────────────────────────────────────────
        , anio_censo::integer                                  as anio

        -- ── MÉTRICAS ───────────────────────────────────────────────────────
        , case
            when n_individuos_estimados <= 0 then null
            else n_individuos_estimados
          end                                                  as n_individuos_estimados

        , n_parejas_reproductoras                              as n_parejas_reproductoras


    from src

    -- El límite inferior se controla con la variable min_anio_censo.
    -- El límite superior usa year(current_date()) para no descartar datos
    -- silenciosamente cuando el proyecto supere el año hardcodeado anterior.
    where anio_censo is not null
      and anio_censo::integer between {{ var('min_anio_censo') }} and year(current_date())

)

select *
from cleaned