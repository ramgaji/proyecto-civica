-- ===========================================================================
-- dim_ccaa.sql
-- ===========================================================================
-- CAPA:   Gold — Dimensiones
-- FUENTE: stg_mix__ccaa
-- SCHEMA: GOLD_DB.dimensions
-- MATERIALIZACIÓN: table
--
-- OBJETIVO:
--   Dimensión de comunidad autónoma. Usada por fct_diversidad_ccaa
--   y fct_censo_anual para agrupar por CCAA.
-- ===========================================================================

select
      id_ccaa
    , nombre

from {{ ref('stg_mix__ccaa') }}