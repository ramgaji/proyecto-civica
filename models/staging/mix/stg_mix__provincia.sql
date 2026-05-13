-- ===========================================================================
-- stg_mix__provincia.sql
-- ===========================================================================
-- CAPA:   Staging Mix (Silver normalizado)
-- FUENTE: ref('provincia_ccaa')  ← seed
-- SCHEMA: {{ env_var('DBT_ENVIRONMENTS') }}_SILVER_DB.mix
-- MATERIALIZACIÓN: view
--
-- OBJETIVO:
--   Expone el seed de provincias como modelo Silver. Cubre las 50 provincias
--   españolas más las regiones de Francia, Portugal y Marruecos que aparecen
--   en los datos de avistamientos y censos.
--
--   Usado como lookup por stg_mix__localizacion y stg_mix__censo_poblacion
--   para enriquecer con CCAA y código INE.
-- ===========================================================================

select
      id_provincia
    , nombre
    , ccaa
    , codigo_ine
    , pais

from {{ ref('provincia_ccaa') }}