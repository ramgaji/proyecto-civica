-- ===========================================================================
-- stg_especies__catalogo.sql
-- ===========================================================================
-- CAPA:   Staging (Silver)
-- FUENTE: source('especies', 'catalogo')
-- SCHEMA: {{ env_var('DBT_ENVIRONMENTS') }}_SILVER_DB.especies
-- MATERIALIZACIÓN: view
--
-- LIMPIEZA APLICADA:
--   1. nombre_cientifico → TRIM()
--   2. nombre_comun_es   → TRIM() + INITCAP para normalizar mayúsculas
--   3. estado_iucn       → UPPER(TRIM()) normaliza lc/LC/L.C. → 'LC'
--   4. estado_espana     → COALESCE con 'NE' (No Evaluado) para nulls
--   5. cites_apendice    → normaliza null/''/N/A → '–'
--   6. endemismo         → cast a boolean (viene como string 'true'/'false')
--   7. es_migratoria     → cast a boolean (viene como string 'true'/'false')
--   8. orden             → corregir typos (Carnívora → Carnivora)
--
-- DEDUPLICACIÓN:
--   QUALIFY ROW_NUMBER() por nombre_cientifico para eliminar duplicados
--   que pueden llegar por exports sucesivos del catálogo.
-- ===========================================================================

with src as (

    select *
    from {{ source('especies', 'catalogo') }}

),

deduped as (

    -- Eliminar duplicados por nombre_cientifico, conservar la primera ocurrencia
    select *
    from src
    qualify row_number() over (
        partition by trim(lower(nombre_cientifico))
        order by nombre_cientifico
    ) = 1

),

cleaned as (

    select
        -- ── TAXONOMÍA ────────────────────────────────────────────────────────
          trim(nombre_cientifico)                                as nombre_cientifico
        , initcap(trim(lower(nombre_comun_es)))                  as nombre_comun_es
        , trim(nombre_comun_en)                                  as nombre_comun_en
        , trim(clase)                                            as clase
        -- Corregir typos en orden taxonómico
        , case trim(orden)
            when 'Carnívora'     then 'Carnivora'
            when 'Artiodáctyla'  then 'Artiodactyla'
            when 'Paseriformes'  then 'Passeriformes'
            else trim(orden)
          end                                                    as orden
        , trim(familia)                                          as familia
        , trim(genero)                                           as genero
        , trim(especie)                                          as especie

        -- ── CONSERVACIÓN ─────────────────────────────────────────────────────
        -- Normalizar estado IUCN: lc/LC/L.C./LC  → 'LC'
        , upper(trim(replace(replace(estado_iucn, '.', ''), ' ', '')))
                                                                 as estado_iucn
        -- Null → 'NE' (No Evaluado por LESRPE)
        , coalesce(
            nullif(trim(upper(estado_espana)), ''),
            'NE'
          )                                                      as estado_espana

        -- ── ENDEMISMO Y MIGRACIÓN ─────────────────────────────────────────────
        -- Viene como string 'true'/'false' → cast a boolean
        , coalesce(endemismo::boolean, false)                    as endemismo
        , coalesce(es_migratoria::boolean, false)                as es_migratoria
        , trim(tipo_migracion)                                   as tipo_migracion

        -- ── CITES ─────────────────────────────────────────────────────────────
        -- Normalizar null / '' / 'N/A' → '–' (sin apéndice CITES)
        , case
            when cites_apendice is null                    then '–'
            when trim(cites_apendice) in ('', '-', '–')    then '–'
            when upper(trim(cites_apendice)) = 'N/A'       then '–'
            else trim(cites_apendice)
          end                                                    as cites_apendice

        -- ── DESCRIPCIÓN Y FUENTE ──────────────────────────────────────────────
        , trim(descripcion_txt)                                  as descripcion
        , trim(fuente_taxonomica)                                as fuente_taxonomica

        -- ── AMENAZAS ──────────────────────────────────────────────────────────
        -- Se mantiene raw aquí — se parsea por '|' en stg_core__amenaza
        , amenaza                                                as amenaza_raw

    from deduped

)

select * from cleaned