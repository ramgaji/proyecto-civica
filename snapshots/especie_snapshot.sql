-- ===========================================================================
-- especie_snapshot.sql — SCD Tipo 2 sobre el catálogo de especies
-- ===========================================================================
-- TIPO: Snapshot (estrategia check)
-- DESTINO: SILVER_DB.snapshots.especie_snapshot
--
-- OBJETIVO:
--   Trackear cambios en los atributos de conservación de cada especie
--   a lo largo del tiempo. Cada vez que cambia el estado IUCN, estado
--   España, endemismo o CITES, dbt cierra la versión anterior y abre
--   una nueva con fecha de inicio.
--
-- CASO DE USO REAL — Lince Ibérico (Lynx pardinus):
--   2002 → CR (En peligro crítico) — menos de 100 ejemplares
--   2015 → EN (En peligro)         — programa de cría en cautividad
--   2024 → VU (Vulnerable)         — >1.000 ejemplares, éxito de recuperación
--
--   Con este snapshot podemos responder:
--   "¿Cuántos avistamientos de Lince había cuando era CR?"
--   "¿En qué provincias empezó la recuperación primero?"
--   "¿Qué tasa de crecimiento del censo hubo bajo cada estado IUCN?"
--
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
-- DEMO EN PRESENTACIÓN:
--   1. dbt snapshot → Lince con id_estado_iucn=VU, dbt_valid_to=NULL
--   2. Cambiar VU→EN en el CSV del catálogo
--   3. dbt seed --full-refresh --select catalogo_especies_raw
--   4. dbt snapshot → ahora 2 filas del Lince:
--        fila 1: VU | dbt_valid_to=ahora
--        fila 2: EN | dbt_valid_to=NULL  ← vigente
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