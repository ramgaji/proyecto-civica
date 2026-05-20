-- ===========================================================================
-- stg_mix__localizacion.sql
-- ===========================================================================
-- CAPA:        Staging Mix (Silver normalizado)
-- FUENTE:      ref('stg_avistamientos__observaciones')
--              ref('stg_mix__provincia')
-- SCHEMA:      {{ env_var('DBT_ENVIRONMENTS') }}_SILVER_DB.mix
-- MATERIALIZACIÓN: view
--
-- DIAGRAMA:
--   localizacion {
--     id_localizacion   PK  surrogate MD5(id_avistamiento)
--     id_avistamiento   FK  1:1 con avistamiento
--     latitud
--     longitud
--     id_provincia      FK  nullable — Gibraltar y frontera no matchan
--   }

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