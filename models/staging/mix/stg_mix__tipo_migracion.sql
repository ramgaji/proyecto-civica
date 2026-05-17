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
-- DECISIÓN — surrogate key en lugar de row_number():
--   ROW_NUMBER() sobre un catálogo derivado de texto es inestable:
--   si el catálogo de especies incorpora un nuevo tipo de migración,
--   todos los tipos posteriores alfabéticamente cambian de ID.
--   El surrogate key produce un MD5 estable por nombre.
-- ===========================================================================

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