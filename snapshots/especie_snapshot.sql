-- ===========================================================================
-- especie_snapshot.sql — SCD Tipo 2 sobre el catálogo de especies
-- ===========================================================================
-- TIPO: Snapshot (estrategia check)
-- DESTINO: SILVER_DB.snapshots.especie_snapshot
-

-- ESTRATEGIA: check
--   No necesita columna updated_at — compara directamente los valores
--   de las columnas indicadas en check_cols entre ejecuciones.
--   Si cualquiera cambia → cierra la versión anterior + abre nueva.
--
-- COLUMNAS GENERADAS POR dbt:
--   dbt_scd_id       → ID único de cada versión histórica
--   dbt_valid_from   → timestamp desde el que esta versión es válida
--   dbt_valid_to     → timestamp hasta el que era válida (NULL = vigente)
--   dbt_updated_at   → última actualización
--

-- COMANDOS:
--   dbt snapshot
--   dbt snapshot --select especie_snapshot
-- ===========================================================================

{% snapshot especie_snapshot %}

    {{
        config(
            target_schema='snapshots',
            unique_key='nombre_cientifico',
            strategy='check',
            check_cols=[
                'id_estado_iucn',
                'id_estado_espana',
                'endemismo',
                'id_cites',
                'id_tipo_migracion',
            ]
        )
    }}

    select
          id_especie
        , nombre_cientifico
        , nombre_comun_es
        , nombre_comun_en
        , id_familia
        , id_estado_iucn
        , id_estado_espana
        , endemismo
        , id_tipo_migracion
        , id_cites

    from {{ ref('stg_mix__especie') }}

{% endsnapshot %}