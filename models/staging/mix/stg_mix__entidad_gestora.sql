-- ===========================================================================
-- stg_mix__entidad_gestora.sql
-- ===========================================================================
-- CAPA:   Staging Mix (Silver normalizado)
-- FUENTE: ref('stg_avistamientos__areas')
--         ref('stg_especies__censos')
-- MATERIALIZACIÓN: view
--
-- DIAGRAMA:
--   entidad_gestora {
--     id_entidad
--     nombre
--   }
--
-- OBJETIVO:
--   Catálogo único de entidades responsables de:
--   - áreas protegidas
--   - censos poblacionales
--
-- DECISIÓN — surrogate key en lugar de row_number():
--   ROW_NUMBER() ORDER BY nombre genera IDs que cambian cuando se añade
--   una nueva entidad: todas las entidades posteriores alfabéticamente
--   recibirían un id_entidad distinto, rompiendo cualquier FK guardada
--   en tablas incrementales o snapshots.
--   generate_surrogate_key(['nombre']) produce un MD5 estable: el ID de
--   cada entidad es siempre el mismo independientemente de cuántas
--   entidades nuevas aparezcan.
-- ===========================================================================

with areas as (

    select distinct
          trim(entidad_gestora) as nombre
    from {{ ref('stg_avistamientos__areas') }}
    where entidad_gestora is not null

),

censos as (

    select distinct
          trim(entidad_responsable) as nombre
    from {{ ref('stg_especies__censos') }}
    where entidad_responsable is not null

),

union_entidades as (

    select nombre from areas
    union
    select nombre from censos

)

select
      {{ dbt_utils.generate_surrogate_key(['nombre']) }} as id_entidad
    , nombre

from union_entidades