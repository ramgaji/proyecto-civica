-- ===========================================================================
-- stg_mix__censo_poblacion.sql
-- ===========================================================================
-- CAPA:   Staging Mix (Silver normalizado)
-- FUENTE: ref('stg_especies__censos')
--         ref('stg_mix__especie')
--         ref('stg_mix__provincia')
-- SCHEMA: {{ env_var('DBT_ENVIRONMENTS') }}_SILVER_DB.mix
-- MATERIALIZACIÓN: view
--
-- OBJETIVO:
--   Tabla de censos de población normalizada con FKs a especie y provincia.
--   Granularidad: una fila por (especie, provincia, año).
--   Base de fct_censo_anual en Gold donde se calculan tendencias con LAG().
--
-- APLICA_PAREJAS:
--   Campo derivado del JOIN con especie — TRUE si es Aves, FALSE si Mammalia.
--   Indica si n_parejas_reproductoras tiene sentido para esa especie.
-- ===========================================================================

with censos as (

    select *
    from {{ ref('stg_especies__censos') }}

),

especie as (

    select id_especie, nombre_cientifico, clase
    from {{ ref('stg_mix__especie') }}

),

provincia as (

    select id_provincia, nombre, pais
    from {{ ref('stg_mix__provincia') }}

)

select
      {{ dbt_utils.generate_surrogate_key([
            'cen.nombre_cientifico',
            'cen.anio_censo',
            'cen.provincia'
         ]) }}                                             as id_censo
    , esp.id_especie
    , prov.id_provincia
    , cen.anio_censo                                      as anio
    , cen.provincia
    , cen.ccaa
    , cen.n_individuos_estimados
    , cen.n_parejas_reproductoras
    -- TRUE si es Aves — n_parejas_reproductoras tiene sentido
    , case
        when upper(esp.clase) = 'AVES' then true
        else false
      end                                                 as aplica_parejas
    , cen.metodo_censo
    , cen.entidad_responsable
    , cen.fuente_doc

from censos cen
left join especie esp
       on trim(lower(cen.nombre_cientifico)) = trim(lower(esp.nombre_cientifico))
left join provincia prov
       on trim(lower(cen.provincia)) = trim(lower(prov.nombre))