{# ===========================================================================
test que ve si las coordenadas de sources  tienen un limite correcto para que no se rompan en bi
=========================================================================== #}

{% test valid_coordinates(model, lat_column, lon_column) %}
select *
from {{ model }}
where {{ lat_column }} < -90 or {{ lat_column }} > 90
   or {{ lon_column }} < -180 or {{ lon_column }} > 180
{% endtest %}