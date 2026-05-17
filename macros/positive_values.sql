{# ===========================================================================
   positive_values.sql — Test genérico custom
   ===========================================================================
   Valida que los valores de una columna son estrictamente > 0.

   Casos de uso en este proyecto:
     - n_individuos_estimados en censos_raw y fct_censo_anual
       (valores 0 o -1 son errores de exportación desde Excel)
     - superficie_ha en areas_protegidas
       (un área con superficie <= 0 es un error de datos)

   USO en cualquier _models.yml o _sources.yml:
     columns:
       - name: n_individuos_estimados
         tests:
           - positive_values

   El test FALLA si la query devuelve filas (valores que NO son positivos).
   Los nulls no se comprueban aquí — usar not_null por separado si se necesita.
   =========================================================================== #}

{% test positive_values(model, column_name) %}

    select *
    from {{ model }}
    where {{ column_name }} <= 0

{% endtest %}