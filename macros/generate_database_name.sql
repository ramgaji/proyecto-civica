{# ===========================================================================
   generate_schema_name.sql
   ===========================================================================
   Override del macro por defecto de dbt para la generación de nombres de
   schema. En el repo del profe se usa para evitar que dbt añada el prefijo
   del target al schema (comportamiento por defecto en dbt Core).

   Con este override:
     - DEV:  ALUMNO_DEV_SILVER_DB.inaturalist.stg_inaturalist__avistamientos
     - PROD: ALUMNO_PROD_SILVER_DB.inaturalist.stg_inaturalist__avistamientos

   Sin el override dbt añadiría el target name al schema:
     - DEV:  ALUMNO_DEV_SILVER_DB.dev_inaturalist.stg_inaturalist__avistamientos
   =========================================================================== #}

{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}

    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}

{%- endmacro %}