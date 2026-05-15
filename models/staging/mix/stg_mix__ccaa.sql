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
--
-- OBJETIVO:
--   Generar catálogo único de comunidades autónomas españolas
--   a partir del seed provincia_ccaa.
-- ===========================================================================

with src as (

    select distinct
          trim(ccaa) as nombre
    from {{ ref('provincia_ccaa') }}
    where ccaa is not null

)

select
      row_number() over (order by nombre) as id_ccaa
    , nombre

from src