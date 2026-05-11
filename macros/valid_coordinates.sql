{# ===========================================================================
test que ve si las coordenadas estan dentro del area de observaciones de las zonas que se han acordado
=========================================================================== #}

{% test valid_coordinates(model, lat_column, lon_column) %}
select *
from {{ model }}
where {{ lat_column }} < -90 or {{ lat_column }} > 90
   or {{ lon_column }} < -180 or {{ lon_column }} > 180
{% endtest %}