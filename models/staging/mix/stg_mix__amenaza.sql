-- ===========================================================================
-- stg_mix__amenaza.sql
-- ===========================================================================
-- CAPA:   Staging Mix (Silver normalizado)
-- FUENTE: ref('stg_mix__especie')
-- SCHEMA: {{ env_var('DBT_ENVIRONMENTS') }}_SILVER_DB.mix
-- MATERIALIZACIÓN: view
--
-- OBJETIVO:
--   Normaliza el campo amenaza_raw (multi-valor separado por '|') en una
--   tabla con una fila por (especie, tipo_amenaza).
--   Granularidad: una fila por amenaza activa de cada especie.
--
-- SPLIT POR '|':
--   Se usa SPLIT_TO_TABLE — función nativa de Snowflake que divide un string
--   por un separador y devuelve una fila por elemento. Equivalente a UNNEST
--   en PostgreSQL o STRING_SPLIT en SQL Server.
--
-- CATÁLOGO CERRADO DE 6 TIPOS:
--   Pérdida de hábitat / Caza/Furtivismo / Atropellos /
--   Especies invasoras / Pesticidas/Contaminación / Cambio climático
--
-- EJEMPLO:
--   Lynx pardinus → amenaza_raw = 'Atropellos|Pérdida de hábitat|Caza/Furtivismo'
--   Resultado → 3 filas, una por amenaza
-- ===========================================================================

with especie as (

    select
          id_especie
        , nombre_cientifico
        , amenaza_raw
    from {{ ref('stg_mix__especie') }}
    where amenaza_raw is not null

),

-- SPLIT_TO_TABLE divide el string por '|' y genera una fila por elemento
amenazas_split as (

    select
          esp.id_especie
        , esp.nombre_cientifico
        , trim(s.value) as tipo_amenaza
    from especie esp
    , lateral split_to_table(esp.amenaza_raw, '|') s

)

select
      {{ dbt_utils.generate_surrogate_key(['id_especie', 'tipo_amenaza']) }}
                                                          as id_amenaza
    , id_especie
    , nombre_cientifico
    , tipo_amenaza

from amenazas_split
where tipo_amenaza is not null
  and tipo_amenaza != ''