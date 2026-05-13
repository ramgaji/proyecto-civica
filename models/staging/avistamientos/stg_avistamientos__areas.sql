-- ===========================================================================
-- stg_avistamientos__areas.sql
-- ===========================================================================
-- CAPA:   Staging (Silver)
-- FUENTE: source('avistamientos', 'areas')
-- SCHEMA: {{ env_var('DBT_ENVIRONMENTS') }}_SILVER_DB.avistamientos
-- MATERIALIZACIÓN: view
--
-- LIMPIEZA APLICADA:
--   1. nombre         → TRIM() para eliminar espacios extra
--   2. tipo_area      → INITCAP(TRIM()) para normalizar mayúsculas
--   3. entidad_gestora→ normalizar variantes (MITECO/Miteco/miteco)
--   4. superficie_ha  → ROUND() para eliminar decimales de export Excel
--   5. anio_declaracion → CAST a int (puede venir como float)
--   6. ccaa / pais    → TRIM()
-- ===========================================================================

with src as (

    select *
    from {{ source('avistamientos', 'areas') }}

),

cleaned as (

    select
        -- ── PK ───────────────────────────────────────────────────────────────
          id_area

        -- ── NOMBRE Y TIPO ────────────────────────────────────────────────────
        , trim(nombre)                                           as nombre
        -- Normalizar mayúsculas: 'parque nacional' → 'Parque Nacional'
        , initcap(trim(tipo_area))                              as tipo_area

        -- ── CATEGORÍAS DE PROTECCIÓN ─────────────────────────────────────────
        , es_lic
        , es_zepa
        , es_parque_nacional

        -- ── GEOGRAFÍA ────────────────────────────────────────────────────────
        , trim(pais)                                            as pais
        , trim(provincia)                                       as provincia
        , trim(ccaa)                                            as ccaa

        -- Bounding box para el join espacial con observaciones
        , lat_min
        , lat_max
        , lon_min
        , lon_max

        -- ── MÉTRICAS ─────────────────────────────────────────────────────────
        -- Eliminar decimales de export Excel (ej: 54252.3 → 54252)
        , round(superficie_ha)::integer                         as superficie_ha

        -- Año como int (puede venir como float por Excel)
        , try_to_number(anio_declaracion::varchar)::integer              as anio_declaracion

        -- ── ENTIDAD GESTORA ───────────────────────────────────────────────────
        -- Normalizar variantes: MITECO/Miteco/miteco → 'MITECO'
        , case
            when upper(trim(entidad_gestora)) = 'MITECO'       then 'MITECO'
            when upper(trim(entidad_gestora)) = 'ICNF'         then 'ICNF'
            when upper(trim(entidad_gestora)) = 'SEO/BIRDLIFE' then 'SEO/BirdLife'
            else trim(entidad_gestora)
          end                                                   as entidad_gestora

        , trim(codigo_red_natura)                               as codigo_red_natura

    from src

)

select * from cleaned
