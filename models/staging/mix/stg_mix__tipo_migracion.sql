-- ===========================================================================
-- stg_mix__tipo_migracion.sql
-- ===========================================================================
-- CAPA:   Staging Mix (Silver normalizado)
-- FUENTE: ref('stg_especies__catalogo')
-- MATERIALIZACIÓN: view
--
-- DIAGRAMA:
--   tipo_migracion {
--     id_tipo_migracion
--     nombre
--   }
--

with src as (

    select distinct
          tipo_migracion
    from {{ ref('stg_especies__catalogo') }}
    where tipo_migracion is not null

)

select
      {{ dbt_utils.generate_surrogate_key(['tipo_migracion']) }} as id_tipo_migracion
    , tipo_migracion                                             as nombre

from src