-- ===========================================================================
-- stg_mix__estado_conservacion.sql
-- ===========================================================================
-- CAPA:        Staging Mix (Silver normalizado)
-- FUENTE:      ref('estado_conservacion')  ← seed
-- SCHEMA:      {{ env_var('DBT_ENVIRONMENTS') }}_SILVER_DB.mix
-- MATERIALIZACIÓN: view
--
-- DIAGRAMA:
--   estado_conservacion {
--     id_estado    PK
--     codigo           -- LC, NT, VU, EN, CR, EX, NE, EEI
--     descripcion
--     nivel_riesgo     -- 0 (sin riesgo) → 5 (crítico)
--   }
-- ===========================================================================

select
      id_estado
    , codigo
    , descripcion
    , nivel_riesgo

from {{ ref('estado_conservacion') }}