-- ===========================================================================
-- stg_avistamientos__observaciones.sql
-- ===========================================================================
-- CAPA:   Staging (Silver)
-- FUENTE: source('avistamientos', 'observaciones')
-- OBJETIVO:
--   Limpieza mínima de observaciones iNaturalist para construir:
--   - avistamiento
--   - localizacion
--   - especie
--   - taxonomia_familia
--   - taxonomia_clase
--
-- FILTROS:
--   - Solo Mammalia y Aves
--   - Solo registros con coordenadas GPS
--   - Solo España
-- ===========================================================================

with src as (

    select *
    from {{ source('avistamientos', 'observaciones') }}
    where upper(trim(iconic_taxon_name)) in ('MAMMALIA', 'AVES')
      and latitude is not null
      and longitude is not null
      and upper(trim(place_country_name)) in ('SPAIN', 'ESPAÑA', 'GIBRALTAR')

),

cleaned as (

    select
          id                                                   as id_avistamiento

        -- ── FECHA ───────────────────────────────────────────────────────────
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
          )                                                    as fecha

        -- ── HORA UTC ────────────────────────────────────────────────────────
        , cast(
            try_to_timestamp_ntz(
                trim(replace(time_observed_at::varchar, ' UTC', '')),
                'YYYY-MM-DD HH24:MI:SS'
            ) as time
          )                                                    as hora_utc

        -- ── ESPECIE / TAXONOMÍA ─────────────────────────────────────────────
        , trim(scientific_name)                                as nombre_cientifico
        , upper(trim(iconic_taxon_name))                       as nombre_clase
        , trim(taxon_family_name)                              as nombre_familia

        -- ── LOCALIZACIÓN ────────────────────────────────────────────────────
        , try_to_double(replace(latitude, ',', '.'))            as latitud
        , try_to_double(replace(longitude, ',', '.'))           as longitud
        , trim(place_county_name)                              as provincia_raw

        -- ── CALIDAD / METADATOS ─────────────────────────────────────────────
        , coalesce(verificado::boolean, false)                 as verificado

        , try_to_number(
            regexp_substr(positional_accuracy::varchar, '[0-9]+(\.[0-9]+)?')
          )                                                    as precision_gps_m


    from src

    qualify row_number() over (
        partition by id
        order by id
    ) = 1

)

select *
from cleaned