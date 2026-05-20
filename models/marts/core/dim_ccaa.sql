-- ===========================================================================
-- dim_ccaa.sql
-- ===========================================================================
-- CAPA:        Gold — dimensión comunidades autónomas
-- FUENTE:      ref('stg_mix__ccaa')
-- MATERIALIZACIÓN: table
--
-- DIAGRAMA:
--   dim_ccaa {
--     id_ccaa   PK
--     ccaa
--   }
-- ===========================================================================
select
      id_ccaa
    , nombre as ccaa
from {{ ref('stg_mix__ccaa') }}