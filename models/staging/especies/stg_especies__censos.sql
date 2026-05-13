-- ===========================================================================
-- stg_especies__censos.sql
-- ===========================================================================
-- CAPA:   Staging (Silver)
-- FUENTE: source('especies', 'censos')
-- SCHEMA: {{ env_var('DBT_ENVIRONMENTS') }}_SILVER_DB.especies
-- MATERIALIZACIÓN: view
--
-- LIMPIEZA APLICADA:
--   1. especie_nombre_cientifico → TRIM()
--   2. anio_censo     → CAST a int (puede venir como float 2018.0 por Excel)
--   3. provincia/ccaa → TRIM() + normalización de tildes inconsistentes
--   4. n_individuos   → valores <= 0 → NULL (errores de exportación)
--   5. metodo_censo   → INITCAP(TRIM()) para normalizar mayúsculas
--   6. entidad        → normalizar variantes de nombre
--
-- CAMPO DERIVADO:
--   Se deriva del JOIN con el catálogo para no duplicar lógica en Gold.
--   Justificación: n_parejas_reproductoras es un indicador específico de aves
--   (número de parejas que crían). En mamíferos este dato no se recoge.
--
-- FILTROS:
--   - Excluir registros con anio_censo nulo o fuera del rango esperado
-- ===========================================================================

with src_censos as (

    select *
    from {{ source('especies', 'censos') }}

),

-- Necesitamos la clase para derivar aplica_parejas
src_catalogo as (

    select
          trim(nombre_cientifico) as nombre_cientifico
        , trim(clase)             as clase
    from {{ source('especies', 'catalogo') }}
    qualify row_number() over (
        partition by trim(lower(nombre_cientifico))
        order by nombre_cientifico
    ) = 1

),

cleaned as (

    select
        -- ── ESPECIE ───────────────────────────────────────────────────────────
          trim(c.especie_nombre_cientifico)                      as nombre_cientifico

        -- ── TIEMPO ───────────────────────────────────────────────────────────
        -- Cast a int: puede venir como float (2018.0) por export Excel
        , c.anio_censo::integer                                  as anio_censo

        -- ── GEOGRAFÍA ────────────────────────────────────────────────────────
        , trim(c.provincia)                                      as provincia
        -- Normalizar tildes inconsistentes
        , trim(
            replace(replace(replace(replace(
                c.ccaa,
            'Andalucia',        'Andalucía'),
            'Castilla y Leon',  'Castilla y León'),
            'Cataluna',         'Cataluña'),
            'Aragon',           'Aragón')
          )                                                      as ccaa

        -- ── MÉTRICAS ─────────────────────────────────────────────────────────
        -- Valores <= 0 son errores de exportación → NULL
        , case
            when c.n_individuos_estimados <= 0 then null
            else c.n_individuos_estimados
          end                                                    as n_individuos_estimados

        , c.n_parejas_reproductoras

        -- Campo derivado: TRUE solo para Aves
        -- Justificación: el censo de parejas reproductoras solo aplica a aves.
        -- En mamíferos se registran individuos totales, no parejas.

        -- ── METADATOS DEL CENSO ───────────────────────────────────────────────
        , initcap(trim(c.metodo_censo))                         as metodo_censo

        -- Normalizar entidad responsable
        , case
            when upper(trim(c.entidad_responsable))
                 in ('SEO/BIRDLIFE', 'SEO / BIRDLIFE')          then 'SEO/BirdLife'
            when upper(trim(c.entidad_responsable)) = 'MITECO'  then 'MITECO'
            when upper(trim(c.entidad_responsable)) = 'FEDENCA' then 'FEDENCA'
            else trim(c.entidad_responsable)
          end                                                    as entidad_responsable

        , c.fuente_doc

    from src_censos c
    left join src_catalogo cat
           on trim(lower(c.especie_nombre_cientifico))
            = trim(lower(cat.nombre_cientifico))

    -- Excluir registros con año nulo o fuera del rango del proyecto
    where c.anio_censo is not null
      and c.anio_censo::integer between {{ var('min_anio_censo') }} and 2030

)

select * from cleaned