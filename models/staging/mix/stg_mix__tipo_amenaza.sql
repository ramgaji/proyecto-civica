-- ===========================================================================
-- stg_mix__tipo_amenaza.sql
-- ===========================================================================
-- CAPA:   Staging Mix (Silver normalizado)
-- FUENTE: seed tipo_amenaza
-- MATERIALIZACIÓN: view
--
-- DIAGRAMA:
--   tipo_amenaza {
--     id_tipo_amenaza
--     nombre
--     descripcion
--   }
-- ===========================================================================

select
      id_tipo_amenaza
    , trim(nombre)      as nombre
    , trim(descripcion) as descripcion

from {{ ref('tipo_amenaza') }}