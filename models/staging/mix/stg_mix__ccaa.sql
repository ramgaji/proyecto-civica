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
--
-- DECISIÓN — surrogate key en lugar de row_number():
--   ROW_NUMBER() ORDER BY nombre es inestable: si se añade una nueva CCAA
--   (p.ej. una región extranjera de frontera) todas las CCAA posteriores
--   en orden alfabético cambian de ID. El surrogate key garantiza que
--   el ID de cada CCAA es siempre el mismo MD5 de su nombre.
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