-- ===========================================================================
-- stg_mix__localizacion.sql
-- ===========================================================================
-- CAPA:   Staging Mix (Silver normalizado)
-- FUENTE: ref('stg_avistamientos__observaciones')
--         ref('stg_mix__provincia')
-- SCHEMA: {{ env_var('DBT_ENVIRONMENTS') }}_SILVER_DB.mix
-- MATERIALIZACIÓN: view
--
-- OBJETIVO:
--   Tabla de localización geográfica de cada avistamiento.
--   Solo coordenadas y FK a provincia — sin lógica de área protegida.
--
-- DECISIÓN DE ARQUITECTURA:
--   El join espacial con área protegida (bounding box) es lógica de negocio
--   — determinar si un avistamiento está dentro o fuera de una zona protegida
--   es una pregunta analítica, no una normalización estructural.
--   Por tanto ese join vive en Gold (fct_avistamiento), no en Silver.
--   Silver solo almacena el dato geográfico limpio.
--
-- GRANULARIDAD: una fila por avistamiento.
-- ===========================================================================

with obs as (

    select
          id_avistamiento
        , latitud
        , longitud
        , provincia_raw
    from {{ ref('stg_avistamientos__observaciones') }}
    where latitud is not null
      and longitud is not null

),

provincia as (

    select
          id_provincia
        , nombre
    from {{ ref('stg_mix__provincia') }}

)

select
      {{ dbt_utils.generate_surrogate_key(['obs.id_avistamiento']) }}
                                                          as id_localizacion
    , obs.id_avistamiento
    , obs.latitud
    , obs.longitud
    , prov.id_provincia

from obs
left join provincia prov
       on trim(lower(obs.provincia_raw)) = trim(lower(prov.nombre))