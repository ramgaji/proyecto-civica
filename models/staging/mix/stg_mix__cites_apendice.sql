-- ===========================================================================
-- stg_mix__cites_apendice.sql
-- ===========================================================================
-- CAPA:   Staging Mix (Silver normalizado)
-- FUENTE: ref('stg_especies__catalogo')
-- SCHEMA: {{ env_var('DBT_ENVIRONMENTS') }}_SILVER_DB.mix
-- MATERIALIZACIÓN: view
--
-- OBJETIVO:
--   Genera la tabla de lookup de apéndices CITES a partir de los valores
--   distintos que aparecen en el catálogo de especies.
--   CITES regula el comercio internacional de especies silvestres:
--     I  → comercio prohibido (Lince, Oso, Foca monje)
--     II → comercio con permisos (Delfines, Murciélagos, Buitres)
--     III → protección en países concretos
--     –  → sin regulación CITES
-- ===========================================================================

with src as (

    select distinct cites_apendice
    from {{ ref('stg_especies__catalogo') }}
    where cites_apendice is not null

)

select
      {{ dbt_utils.generate_surrogate_key(['cites_apendice']) }}  as id_cites
    , cites_apendice                                               as apendice
    , case cites_apendice
        when 'I'  then 'Comercio prohibido totalmente'
        when 'II' then 'Comercio permitido con permisos'
        when 'III'then 'Protección en países específicos'
        when '–'  then 'Sin regulación CITES'
        else 'Desconocido'
      end                                                          as descripcion

from src