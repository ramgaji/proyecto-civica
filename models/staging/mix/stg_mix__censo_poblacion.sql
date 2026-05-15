-- ===========================================================================
-- stg_mix__censo_poblacion.sql
-- ===========================================================================
-- CAPA:   Staging Mix (Silver normalizado)
-- FUENTE: ref('stg_especies__censos')
--         ref('stg_mix__especie')
--         ref('stg_mix__provincia')
--         ref('stg_mix__entidad_gestora')
-- MATERIALIZACIÓN: view
--
-- DIAGRAMA:
--   censo_poblacion {
--     id_censo
--     id_especie
--     id_provincia
--     id_entidad
--     anio
--     n_individuos_estimados
--     n_parejas_reproductoras
--   }
-- ===========================================================================

with censos as (

    select *
    from {{ ref('stg_especies__censos') }}

),

especie as (

    select
          id_especie
        , nombre_cientifico
    from {{ ref('stg_mix__especie') }}

),

provincia as (

    select
          id_provincia
        , nombre
    from {{ ref('stg_mix__provincia') }}

),

entidad as (

    select
          id_entidad
        , nombre
    from {{ ref('stg_mix__entidad_gestora') }}

)

select
      {{ dbt_utils.generate_surrogate_key([
            'cen.nombre_cientifico',
            'cen.anio',
            'cen.provincia',
            'cen.entidad_responsable'
         ]) }}                                             as id_censo

    , esp.id_especie
    , prov.id_provincia
    , ent.id_entidad
    , cen.anio
    , cen.n_individuos_estimados
    , cen.n_parejas_reproductoras

from censos cen

left join especie esp
       on trim(lower(cen.nombre_cientifico))
       = trim(lower(esp.nombre_cientifico))

left join provincia prov
       on trim(lower(cen.provincia))
       = trim(lower(prov.nombre))

left join entidad ent
       on trim(lower(cen.entidad_responsable))
       = trim(lower(ent.nombre))