-- ===========================================================================
-- stg_mix__observador.sql
-- ===========================================================================
-- CAPA:   Staging Mix (Silver normalizado)
-- FUENTE: ref('stg_avistamientos__observaciones')
-- SCHEMA: {{ env_var('DBT_ENVIRONMENTS') }}_SILVER_DB.mix
-- MATERIALIZACIÓN: view
--
-- OBJETIVO:
--   Extrae los observadores únicos de los avistamientos.
--   Granularidad: una fila por observador distinto.
--
-- TIPO DE OBSERVADOR:
--   Se clasifica como 'Científico' si el nombre contiene patrones habituales
--   de usuarios institucionales, 'Ciudadano' en el resto de casos.
--   Es una aproximación — en iNaturalist no hay distinción formal entre tipos.
-- ===========================================================================

with src as (

    select distinct observador_raw
    from {{ ref('stg_avistamientos__observaciones') }}
    where observador_raw is not null

)

select
      {{ dbt_utils.generate_surrogate_key(['observador_raw']) }}
                                                          as id_observador
    , observador_raw                                      as nombre
    , case
        when lower(observador_raw) like '%universidad%'
          or lower(observador_raw) like '%museum%'
          or lower(observador_raw) like '%institute%'
          or lower(observador_raw) like '%csic%'
          or lower(observador_raw) like '%seo%'
          then 'Científico'
        when observador_raw = 'observador_anonimo'
          then 'Anónimo'
        else 'Ciudadano'
      end                                                 as tipo

from src