-- ===========================================================================
-- stg_mix__cites_apendice.sql
-- ===========================================================================
-- CAPA:   Staging Mix (Silver normalizado)
-- FUENTE: ref('stg_especies__catalogo')
-- MATERIALIZACIÓN: view
--
-- DIAGRAMA:
--   cites_apendice {
--     id_cites
--     apendice
--     descripcion
--   }
-- ===========================================================================

with src as (

    select distinct
          cites_apendice as apendice
    from {{ ref('stg_especies__catalogo') }}
    where cites_apendice is not null

)

select
      case apendice
        when 'I'   then 1
        when 'II'  then 2
        when 'III' then 3
        when '–'   then 4
      end                                                   as id_cites

    , apendice

    , case apendice
        when 'I'   then 'Comercio prohibido totalmente'
        when 'II'  then 'Comercio permitido con permisos'
        when 'III' then 'Protección en países específicos'
        when '–'   then 'Sin regulación CITES'
        else 'Desconocido'
      end                                                   as descripcion

from src