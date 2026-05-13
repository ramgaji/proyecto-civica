-- ===========================================================================
-- stg_mix__especie.sql
-- ===========================================================================
-- CAPA:   Staging Mix (Silver normalizado)
-- FUENTE: ref('stg_especies__catalogo')
--         ref('stg_mix__taxonomia_familia')
--         ref('stg_mix__estado_conservacion')
--         ref('stg_mix__cites_apendice')
-- SCHEMA: {{ env_var('DBT_ENVIRONMENTS') }}_SILVER_DB.mix
-- MATERIALIZACIÓN: view
--
-- OBJETIVO:
--   Tabla maestra de especies. Integra la taxonomía, los estados de
--   conservación (IUCN global y LESRPE España) y CITES en una sola entidad
--   con FKs explícitas. Base del snapshot SCD2 y de dim_especie en Gold.
--
-- DOS FKs A ESTADO_CONSERVACION:
--   id_estado_iucn  → estado según criterio IUCN global
--   id_estado_espana→ estado según catálogo LESRPE español
--   Esto permite comparar ambos criterios en Gold — caso del Lobo ibérico:
--   LC global (hay miles en Rusia) vs VU en España (subespecie ibérica).
-- ===========================================================================

with catalogo as (

    select *
    from {{ ref('stg_especies__catalogo') }}

),

familia as (

    select id_familia, nombre_familia
    from {{ ref('stg_mix__taxonomia_familia') }}

),

estado as (

    select id_estado, codigo, fuente
    from {{ ref('stg_mix__estado_conservacion') }}

),

cites as (

    select id_cites, apendice
    from {{ ref('stg_mix__cites_apendice') }}

)

select
      {{ dbt_utils.generate_surrogate_key(['cat.nombre_cientifico']) }}
                                                          as id_especie
    , cat.nombre_cientifico
    , cat.nombre_comun_es
    , cat.nombre_comun_en
    , cat.clase

    -- FK taxonomía
    , fam.id_familia

    -- FK estado conservación IUCN (criterio global)
    , est_iucn.id_estado                                  as id_estado_iucn

    -- FK estado conservación España (criterio LESRPE)
    , est_esp.id_estado                                   as id_estado_espana

    , cat.endemismo
    , cat.es_migratoria
    , cat.tipo_migracion

    -- FK CITES
    , cit.id_cites

    , cat.descripcion
    , cat.fuente_taxonomica

    -- amenaza_raw se parsea en stg_mix__amenaza
    , cat.amenaza_raw

from catalogo cat

left join familia fam
       on cat.familia = fam.nombre_familia

left join estado est_iucn
       on cat.estado_iucn = est_iucn.codigo
      and est_iucn.fuente = 'IUCN'

left join estado est_esp
       on cat.estado_espana = est_esp.codigo
      and est_esp.fuente = 'LESRPE'

left join cites cit
       on cat.cites_apendice = cit.apendice