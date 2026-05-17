-- ===========================================================================
-- stg_especies__catalogo.sql
-- ===========================================================================
-- CAPA:   Staging (Silver)
-- FUENTE: source('especies', 'catalogo')
-- MATERIALIZACIÓN: view
--
-- OBJETIVO:
--   Limpieza mínima del catálogo de especies para construir:
--   - especie
--   - taxonomia_clase
--   - taxonomia_familia
--   - amenaza
-- ===========================================================================

with src as (

    select *
    from {{ source('especies', 'catalogo') }}

),

deduped as (

    select *
    from src
    qualify row_number() over (
        partition by trim(lower(nombre_cientifico))
        order by nombre_cientifico
    ) = 1

),

cleaned as (

    select

        -- ── ESPECIE ─────────────────────────────────────────────────────────
          trim(nombre_cientifico)                              as nombre_cientifico
        , initcap(trim(lower(nombre_comun_es)))                as nombre_comun_es
        , trim(nombre_comun_en)                                as nombre_comun_en

        -- ── TAXONOMÍA ──────────────────────────────────────────────────────
        , trim(clase)                                          as nombre_clase
        , trim(familia)                                        as nombre_familia

        -- ── CONSERVACIÓN ───────────────────────────────────────────────────
        , upper(trim(replace(replace(estado_iucn, '.', ''), ' ', '')))
                                                               as estado_iucn

        , coalesce(
            nullif(trim(upper(estado_espana)), ''),
            'NE'
          )                                                    as estado_espana

        -- ── ENDEMISMO ──────────────────────────────────────────────────────
        , coalesce(endemismo::boolean, false)                  as endemismo

        -- ── MIGRACIÓN ──────────────────────────────────────────────────────
        , nullif(trim(tipo_migracion), '')                     as tipo_migracion

        -- ── CITES ──────────────────────────────────────────────────────────
        , case
            when cites_apendice is null                  then '–'
            when trim(cites_apendice) in ('', '-', '–')  then '–'
            when upper(trim(cites_apendice)) = 'N/A'     then '–'
            else trim(cites_apendice)
          end                                                  as cites_apendice

        -- ── AMENAZAS ───────────────────────────────────────────────────────
        , amenaza                                              as amenaza_raw

    from deduped

)

select *
from cleaned