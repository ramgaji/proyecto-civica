{# ===========================================================================
   _core__docs.md
   ===========================================================================
   Bloques reutilizables de documentación para dbt Docs.
   Uso:
       description: '{{ doc("nombre_bloque") }}'
   =========================================================================== #}


{% docs join_espacial_bbox %}

Join espacial aproximado mediante bounding box rectangular.

Se comprueba si la latitud y longitud de un avistamiento caen dentro del
rectángulo definido por:

- lat_min / lat_max
- lon_min / lon_max

Si un avistamiento cae en varias áreas protegidas solapadas, se selecciona
la más restrictiva usando:

Parque Nacional > ZEPA > LIC

Limitación:
El bounding box es una aproximación geométrica simple y no representa el
polígono real del área protegida.

{% enddocs %}



{% docs estado_conservacion %}

Estado de conservación de especies según criterios oficiales.

Fuentes utilizadas:

| fuente  | descripción |
|---------|-------------|
| IUCN    | Clasificación global internacional |
| LESRPE  | Clasificación oficial española |

Códigos utilizados:

| código | significado |
|--------|-------------|
| LC | Preocupación menor |
| NT | Casi amenazada |
| VU | Vulnerable |
| EN | En peligro |
| CR | En peligro crítico |
| EX | Extinta |
| NE | No evaluada |

{% enddocs %}



{% docs especie_catalogada %}

Indicador booleano que determina si la especie observada existe en el
catálogo maestro de especies (`dim_especie`).

| valor | significado |
|-------|-------------|
| TRUE  | especie catalogada |
| FALSE | especie no encontrada en catálogo |

Permite excluir observaciones no clasificadas en análisis ecológicos.

{% enddocs %}



{% docs cites_apendice %}

Clasificación CITES sobre regulación internacional de comercio de especies.

| apéndice | significado |
|----------|-------------|
| I   | Comercio prohibido |
| II  | Comercio permitido con permisos |
| III | Protección regional específica |
| –   | Sin regulación CITES |

{% enddocs %}



{% docs indice_shannon %}

Índice de diversidad de Shannon.

Fórmula:

H = -SUM(p * LN(p))

donde:

- p = proporción relativa de cada especie

Interpretación:

| valor | interpretación |
|-------|----------------|
| bajo  | baja diversidad |
| alto  | alta diversidad |

{% enddocs %}



{% docs indice_simpson %}

Índice de diversidad de Simpson.

Fórmula:

1 - SUM(p²)

Interpretación:

| valor | interpretación |
|-------|----------------|
| cercano a 0 | dominancia de pocas especies |
| cercano a 1 | diversidad alta |

{% enddocs %}



{% docs especies_migratorias %}

Clasificación de especies según comportamiento migratorio.

Tipos utilizados:

| tipo_migracion |
|----------------|
| Estival |
| Invernante |
| Residente |
| Transeúnte |

Una especie puede tener:

- comportamiento residente
- migraciones estacionales
- migración de paso

{% enddocs %}



{% docs avistamiento_verificado %}

Indicador de calidad del dato procedente de iNaturalist.

| valor | significado |
|-------|-------------|
| TRUE  | identificación validada por expertos/comunidad |
| FALSE | observación sin validar |

Se utiliza para medir calidad y fiabilidad del dato ciudadano.

{% enddocs %}



{% docs late_arriving_data %}

Registros que llegan tarde al sistema fuente respecto a su fecha real
de generación.

El modelo incremental utiliza una ventana de seguridad de 1 hora:

dateadd('hour', -1, max(fecha))

Esto evita perder registros retrasados en sincronizaciones incrementales.

{% enddocs %}