-- ===========================================================================
-- stg_avistamientos__observaciones.sql
-- ===========================================================================
-- CAPA:   Staging (Silver)
-- FUENTE: source('avistamientos', 'observaciones')
-- SCHEMA: {{ env_var('DBT_ENVIRONMENTS') }}_SILVER_DB.avistamientos
-- MATERIALIZACIÓN: view (sin coste de almacenamiento)
--
-- LIMPIEZA APLICADA:
--   1. observed_on    → normaliza dos formatos de fecha (YYYY-MM-DD y DD/MM/YYYY)
--   2. latitude/lon   → reemplaza coma decimal por punto y castea a float
--   3. user_name      → elimina emails, imputa 'observador_anonimo' en nulls
--   4. place_country  → normaliza variantes (Spain/España/SPAIN → 'Spain')
--   5. iconic_taxon   → UPPER + TRIM para homogeneizar mayúsculas
--   6. verificado     → COALESCE a false si null
--   7. positional_accuracy → elimina ' m' y 'unknown', castea a número
--
-- COLUMNAS DESCARTADAS (redundantes o >80% null):
--   place_town_name   → 96.9% null
--   species_guess     → redundante con scientific_name
--   common_name       → ya está en dim_especie
--   taxon_id          → id interno iNaturalist, no se usa en Silver
--   taxon_genus_name  → redundante con scientific_name
--   taxon_species_name→ redundante con scientific_name
--
-- FILTROS:
--   - Solo Mammalia y Aves (iconic_taxon_name)
--   - Excluir registros sin coordenadas GPS
-- ===========================================================================

with src as (

    select *
    from {{ source('avistamientos', 'observaciones') }}
    -- Filtro taxonómico: solo los grupos que nos interesan
    where upper(trim(iconic_taxon_name)) in ('MAMMALIA', 'AVES')
    -- Excluir sin coordenadas GPS (no se pueden cruzar con áreas protegidas)
      and latitude  is not null
      and longitude is not null

),

cleaned as (

    select
        -- ── PK ──────────────────────────────────────────────────────────────
          id                                                as id_avistamiento

        -- ── TIMESTAMP COMPLETO ──────────────────────────────────────────────

        -- ── FECHA ───────────────────────────────────────────────────────────
        -- Se deriva del timestamp si existe; fallback a observed_on
        , coalesce(

            cast(
                try_to_timestamp_ntz(
                    trim(replace(time_observed_at::varchar, ' UTC', '')),
                    'YYYY-MM-DD HH24:MI:SS'
                ) as date
            ),

            case
                when observed_on like '__/__/____'
                    then to_date(observed_on, 'DD/MM/YYYY')

                when observed_on like '____/__/__'
                    then to_date(observed_on, 'YYYY/MM/DD')

                else
                    try_to_date(observed_on, 'YYYY-MM-DD')
            end

          )                                                     as fecha

        -- ── HORA UTC ────────────────────────────────────────────────────────
        -- Solo componente temporal del timestamp
        , cast(
                try_to_timestamp_ntz(
                trim(replace(time_observed_at::varchar, ' UTC', '')),
                'YYYY-MM-DD HH24:MI:SS'
                ) as time
                                                            ) as hora_utc
        -- ── OBSERVADOR ───────────────────────────────────────────────────────
        -- Eliminar emails mezclados, imputar anónimos
        , case
            when user_name like '%@%'   then null
            when user_name is null      then 'observador_anonimo'
            else trim(user_name)
          end                                                     as observador_raw

        -- ── COORDENADAS ──────────────────────────────────────────────────────
        -- Algunos valores tienen coma decimal en vez de punto (export Excel español)
        , try_to_double(replace(latitude,  ',', '.'))            as latitud
        , try_to_double(replace(longitude, ',', '.'))            as longitud

        -- Precisión GPS: eliminar ' m' y 'unknown', castear a número
        ,try_to_number(
            regexp_substr(positional_accuracy::varchar, '[0-9]+(\.[0-9]+)?')
        )                                                       as precision_gps_m

        -- ── LOCALIZACIÓN ─────────────────────────────────────────────────────
        , trim(place_county_name)                                as provincia_raw

        -- País normalizado: variantes Spain/España/SPAIN → 'Spain'
        , case 

            when place_country_name is null 
              or trim(place_country_name) = '' 
              then 'Unknown'

            when upper(trim(place_country_name)) = 'SPAIN'     
              then 'Spain'

            when upper(trim(place_country_name)) = 'ESPAÑA'    
              then 'Spain'

            when upper(trim(place_country_name)) = 'GIBRALTAR' 
              then 'Spain'

            when upper(trim(place_country_name)) = 'FRANCE'    
              then 'France'

            when upper(trim(place_country_name)) = 'FRANCIA'   
              then 'France'

            when upper(trim(place_country_name)) = 'PORTUGAL'  
              then 'Portugal'

            when upper(trim(place_country_name)) = 'MOROCCO'   
              then 'Morocco'

            when upper(trim(place_country_name)) = 'MARRUECOS' 
              then 'Morocco'

            when upper(trim(place_country_name)) = 'ALGERIA'   
              then 'Algeria'

            else trim(place_country_name)

          end                                                     as pais

        -- ── ESPECIE ───────────────────────────────────────────────────────────
        , trim(scientific_name)                                  as nombre_cientifico
        , upper(trim(iconic_taxon_name))                         as clase_raw
        , trim(taxon_class_name)                                 as taxon_clase
        , trim(taxon_family_name)                                as familia_raw

        -- ── CALIDAD DEL DATO ──────────────────────────────────────────────────
        -- null → false (observación pendiente de verificación por experto)
        , coalesce(verificado::boolean, false)                   as verificado

        -- Siempre iNaturalist en este source
        , 'iNaturalist'                                          as fuente

        -- ── COLUMNAS DESCARTADAS ──────────────────────────────────────────────
        -- place_town_name   → 96.9% null, no aporta granularidad útil
        -- species_guess     → redundante con scientific_name
        -- common_name       → ya está en dim_especie
        -- taxon_id          → id interno iNaturalist
        -- taxon_genus_name  → redundante con scientific_name
        -- taxon_species_name→ redundante con scientific_name

    from src
    -- ── ASEGURARSE DE QUE HAY 1 ID ──────────────────────────────────────────────
    qualify row_number() over (
        partition by id
        order by id
    ) = 1
)

select * from cleaned