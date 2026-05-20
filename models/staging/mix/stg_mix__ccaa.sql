-- ===========================================================================
-- stg_mix__ccaa.sql
-- ===========================================================================
-- CAPA:   Staging Mix (Silver normalizado)
-- FUENTE: seed provincia_ccaa
-- MATERIALIZACIÓN: view
--
-- DIAGRAMA:
--   ccaa {
--     id_ccaa
--     nombre
--   }

-- ===========================================================================

with src as (

    select distinct
          trim(ccaa) as nombre
    from {{ ref('provincia_ccaa') }}
    where ccaa is not null

)

select
      {{ dbt_utils.generate_surrogate_key(['nombre']) }} as id_ccaa
    , nombre

from src