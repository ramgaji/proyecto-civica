-- ===========================================================================
-- stg_mix__taxonomia_orden.sql
-- ===========================================================================
-- CAPA:   Staging Mix (Silver normalizado)
-- FUENTE: ref('stg_especies__catalogo') + ref('stg_mix__taxonomia_clase')
-- SCHEMA: {{ env_var('DBT_ENVIRONMENTS') }}_SILVER_DB.mix
-- MATERIALIZACIÓN: view
--
-- OBJETIVO:
--   Extrae los valores únicos de orden taxonómico y los enlaza con su clase
--   padre mediante FK. Segunda tabla de la jerarquía taxonómica.
--
-- SURROGATE KEY:
--   Se genera sobre (orden) porque el orden es único dentro del proyecto.
--   Si en el futuro hubiese órdenes con el mismo nombre en distintas clases
--   habría que incluir clase en la key: generate_surrogate_key(['clase','orden'])
-- ===========================================================================

with src as (

    select distinct
          clase
        , orden
    from {{ ref('stg_especies__catalogo') }}
    where orden is not null

),

clase as (

    select id_clase, nombre_clase
    from {{ ref('stg_mix__taxonomia_clase') }}

)

select
      {{ dbt_utils.generate_surrogate_key(['src.orden']) }}  as id_orden
    , src.orden                                               as nombre_orden
    , clase.id_clase

from src
left join clase
       on src.clase = clase.nombre_clase