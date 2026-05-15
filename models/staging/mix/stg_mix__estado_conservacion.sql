-- ===========================================================================
-- stg_mix__estado_conservacion.sql
-- ===========================================================================
-- CAPA:   Staging Mix (Silver normalizado)
-- FUENTE: ref('seed_data.estado_conservacion')
-- SCHEMA: {{ env_var('DBT_ENVIRONMENTS') }}_SILVER_DB.mix
-- MATERIALIZACIÓN: view
--
-- OBJETIVO:
--   Expone el seed de estados de conservación como modelo Silver normalizado.
--   Catálogo de 13 filas (6 códigos IUCN + 7 LESRPE) con nivel de riesgo
--   numérico para ordenar y filtrar sin joins adicionales en Gold.
--
-- NOTA:
--   Una especie tiene DOS estados: uno IUCN (global) y uno LESRPE (España).
--   Esto permite comparar si España tiene una especie más amenazada que el
--   criterio global — caso real del Lobo ibérico (LC global / VU España).
-- ===========================================================================

select
      id_estado
    , codigo
    , descripcion
    , nivel_riesgo

from {{ ref('estado_conservacion') }}