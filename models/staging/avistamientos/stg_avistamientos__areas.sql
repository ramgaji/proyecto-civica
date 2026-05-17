-- ===========================================================================
-- stg_avistamientos__areas.sql
-- ===========================================================================
-- CAPA:   Staging (Silver)
-- FUENTE: source('avistamientos', 'areas')
-- MATERIALIZACIÓN: view
--
-- OBJETIVO:
--   Limpieza mínima de áreas protegidas para construir:
--   - area_protegida
--   - entidad_gestora
--
-- COLUMNAS FINALES:
--   - id_area_natural
--   - nombre
--   - es_lic
--   - es_zepa
--   - es_parque_nacional
--   - provincia
--   - ccaa
--   - lat_min / lat_max
--   - lon_min / lon_max
--   - superficie_ha
--   - anio_declaracion
--   - entidad_gestora
--   - codigo_red_natura
-- ===========================================================================

with src as (

    select *
    from {{ source('avistamientos', 'areas') }}

),

cleaned as (

    select

        -- ── PK NATURAL ──────────────────────────────────────────────────────
          id_area                                              as id_area_protegida

        -- ── IDENTIFICACIÓN ──────────────────────────────────────────────────
        , trim(nombre)                                         as nombre

        -- ── PROTECCIONES ────────────────────────────────────────────────────
        , es_lic::boolean                                      as es_lic
        , es_zepa::boolean                                     as es_zepa
        , es_parque_nacional::boolean                          as es_parque_nacional

        -- ── GEOGRAFÍA ───────────────────────────────────────────────────────
        , trim(provincia)                                      as provincia
        , trim(ccaa)                                           as ccaa

        -- Bounding box para joins espaciales
        , try_to_double(replace(lat_min, ',', '.'))            as lat_min
        , try_to_double(replace(lat_max, ',', '.'))            as lat_max
        , try_to_double(replace(lon_min, ',', '.'))            as lon_min
        , try_to_double(replace(lon_max, ',', '.'))            as lon_max

        -- ── MÉTRICAS ────────────────────────────────────────────────────────
        , round(
            try_to_double(replace(superficie_ha, ',', '.'))
          )::integer                                           as superficie_ha

        , try_to_number(anio_declaracion::varchar)::integer
                                                                as anio_declaracion

        -- ── ENTIDAD GESTORA ─────────────────────────────────────────────────
        , case
            when upper(trim(entidad_gestora)) = 'MITECO'
                then 'MITECO'

            when upper(trim(entidad_gestora)) = 'SEO/BIRDLIFE'
                then 'SEO/BirdLife'

            else trim(entidad_gestora)

          end                                                  as entidad_gestora

        , trim(codigo_red_natura)                              as codigo_red_natura

    from src

)

select *
from cleaned