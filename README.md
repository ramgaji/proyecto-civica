# 🦅 Proyecto Civica — Pipeline de Biodiversidad con dbt + Snowflake

Pipeline de datos end-to-end para análisis de biodiversidad en España, construido con dbt y Snowflake siguiendo arquitectura medallion Bronze → Silver → Gold. Los datos provienen de iNaturalist (avistamientos ciudadanos) y fuentes oficiales de censos de fauna.

---

## 📊 Casos de uso

### Alertas y Seguimiento de Campo
Monitorización en tiempo real de avistamientos de mamíferos y aves en España. Permite filtrar por provincia, especie, área protegida, estado de conservación y verificación del avistamiento. Incluye mapa de distribución con diferenciación dentro/fuera de área protegida, gráfico de avistamientos por franja horaria y tabla de avistamientos a última hora.

### Censos y Predicción de Poblaciones
Análisis de la evolución poblacional de especies a partir de censos oficiales. Visualiza la tendencia histórica por especie y provincia, variación respecto al año anterior y clasificación alza/baja/estable. Incluye el estado de conservación IUCN vigente obtenido del histórico SCD-2.

### Diversidad Ecológica por CCAA
Métricas de biodiversidad matemática por comunidad autónoma y año. Calcula los índices de Shannon y Simpson a partir de la combinación de avistamientos y censos. Incluye distribución de especies amenazadas (CR, EN, VU) y mapa coroplético de España.

---

## 🏗️ Arquitectura

```
Bronze (raw)
├── avistamientos.observaciones   ← iNaturalist API
├── avistamientos.areas           ← Áreas protegidas España
├── especies.catalogo             ← Catálogo de fauna
└── especies.censos               ← Censos oficiales (SEO/BirdLife, MITECO, FEDENCA)

Silver (limpieza y normalización)
├── stg_avistamientos__observaciones   view · dedup QUALIFY · multiformat fecha
├── stg_avistamientos__areas           view · try_to_double coordenadas bbox
├── stg_especies__catalogo             view · dedup QUALIFY · normalización IUCN/CITES
├── stg_especies__censos               view · replace tildes CCAA · positive_values
└── stg_mix__*                         view/incremental · catálogos normalizados · IDs MD5

Snapshots
└── especie_snapshot    SCD-2 · estrategia check · unique_key=nombre_cientifico

Gold (marts)
├── dim_especie              desde snapshot SCD-2 · versión vigente
├── dim_especie_censo        subconjunto con al menos un censo
├── dim_lugar                provincia + CCAA desnormalizados
├── dim_fecha                granularidad día · estación del año
├── dim_area_protegida       bbox · figuras de protección
├── fct_avistamiento         join espacial non-equi · hora local CET/CEST · franja horaria
├── fct_censo_anual          LAG window · variación y tendencia interanual
└── fct_diversidad_ccaa      UNION avi+censos · Shannon · Simpson · n_especies_cr/en/vu
```

---

## ⚙️ Decisiones técnicas principales

**Incremental merge en `stg_mix__avistamiento`**
iNaturalist puede actualizar observaciones existentes (corrección de especie, verificación). Se usa merge con `unique_key=id_avistamiento` y watermark `fecha > max(fecha) - 1h` para cubrir lag de sincronización. `on_schema_change=fail` para detectar cambios de esquema de forma ruidosa.

**Snapshot SCD-2 sobre `stg_mix__especie`**
El estado de conservación IUCN de una especie cambia a lo largo del tiempo (Lince ibérico: CR→EN→VU). Se usa estrategia `check` porque el catálogo fuente es un CSV sin campo `updated_at`. Se snapshottea sobre Silver normalizado y no sobre Bronze raw para evitar falsos cambios por ruido tipográfico.

**Surrogate keys MD5**
Las entidades sin PK natural estable (ccaa, entidad, especie, familia, clase, tipo_migración, área protegida) usan `generate_surrogate_key` de dbt-utils. `row_number()` cambia al añadir filas nuevas y rompe todas las FKs aguas abajo. Las entidades con PK natural estable (id_provincia=código INE, id_avistamiento=id iNaturalist) no usan MD5.

**Join espacial non-equi en `fct_avistamiento`**
Sin geometrías nativas, el cruce con áreas protegidas se hace mediante `BETWEEN lat_min/lat_max AND lon_min/lon_max`. Como una misma zona puede tener varias figuras de protección solapadas (Parque Nacional + ZEPA + LIC), `QUALIFY row_number()` prioriza la figura de mayor protección. Limitación conocida: bbox ≠ geometría real.

**Hora local en `fct_avistamiento`**
CET/CEST calculado a partir de `hora_utc` — meses 4-10 +2h, resto +1h. Vive en la fact y no en `dim_fecha` porque la dimensión de fecha tiene granularidad estricta de día.

**UNION en `fct_diversidad_ccaa`**
Los índices de diversidad se calculan sobre la combinación de avistamientos y censos. UNION (no UNION ALL) para evitar contar la misma especie dos veces si aparece en ambas fuentes. El conteo de avistamientos se calcula en CTE separado antes del UNION para no perder registros.

**Silver limpia, Gold decide**
Los filtros de negocio (es_catalogada=true, dentro_area_protegida) viven en Gold. Silver conserva todos los datos incluidos los avistamientos no catalogados, para que futuros modelos puedan consumirlos sin tocar la capa de limpieza.

---

## 🧪 Tests

| Capa | Qué se testea |
|------|--------------|
| Seeds | `accepted_values` en códigos IUCN, CITES, tipo amenaza |
| Silver | `unique` + `not_null` en PKs donde nacen · `relationships` en FKs · `valid_coordinates` en GPS · `positive_values` en n_individuos |
| Silver (relationships) | `severity: warn` cuando la ausencia de match es dato válido (avistamiento sin especie en catálogo) |
| Gold | Solo columnas computadas aquí: `accepted_values` en tendencia, estacion, franja_horaria · `unique` en PKs de facts |
| Principio | No repetir tests upstream en downstream — un `unique` de Silver no se repite en Gold |

---

## 🔧 Macros

- **`positive_values`** — verifica que una columna numérica sea mayor que cero. Usada en `n_individuos_estimados` para detectar errores de exportación Excel en censos.
- **`valid_coordinates`** — verifica que latitud y longitud estén en rangos globales válidos. Usada en observaciones para evitar que coordenadas corruptas lleguen al join espacial.
- **`generate_database_name`** — override del comportamiento por defecto de dbt para que los esquemas se nombren exactamente con `DBT_ENVIRONMENTS` sin prefijos adicionales del target.

---

## 🚀 Setup

### Requisitos
- dbt-core + dbt-snowflake
- Snowflake con warehouse y databases Bronze/Silver/Gold configurados

### Variables de entorno

La variable de entorno `DBT_ENVIRONMENTS` controla el entorno activo (`DEV`, `PRE`, `PRO`).

```bash
export DBT_ENVIRONMENTS=PRE
```

### Ejecución
```bash
# Build completo
dbt build

# Solo Silver
dbt build --select staging

# Solo Gold
dbt build --select marts

# Snapshot
dbt snapshot

# Solo el incremental
dbt run --select stg_mix__avistamiento

# Full refresh del incremental
dbt run --select stg_mix__avistamiento --full-refresh
```

---

## 📁 Estructura del proyecto

```
proyecto-civica/
├── models/
│   ├── staging/
│   │   ├── avistamientos/
│   │   └── especies/
│   ├── staging/mix/
│   └── marts/
│       ├── core/
│       ├── avistamientos/
│       ├── censos/
│       └── diversidad/
├── snapshots/
├── seeds/
├── macros/
└── dbt_project.yml
```

---

## 🗃️ Fuentes de datos

| Fuente | Descripción |
|--------|-------------|
| iNaturalist | Avistamientos ciudadanos verificados de mamíferos y aves en España |
| SEO/BirdLife | Censos oficiales de aves |
| MITECO | Censos oficiales de mamíferos y datos de áreas protegidas Red Natura 2000 |
| FEDENCA | Censos de fauna cinegética |

---

## 📎 Presentación

La presentación técnica del proyecto y casos de uso está disponible en [`docs/civica_presentacion_final.pptx`](docs/civica_presentacion_final.pptx).


## 👤 Autor

Ramón García · [github.com/ramgaji](https://github.com/ramgaji) · [linkedin.com/ramgaji](https://linkedin.com/ramgaji)