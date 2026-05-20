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