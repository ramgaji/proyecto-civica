-- ===========================================================================
-- fct_diversidad_ccaa.sql
-- ===========================================================================

with especie_estado as (

    -- Catálogo de especies con su estado para resolver códigos
    select
          esp.id_especie
        , est.codigo as estado_espana
    from {{ ref('stg_mix__especie') }} esp
    left join {{ ref('stg_mix__estado_conservacion') }} est
           on esp.id_estado_espana = est.id_estado

),

-- Avistamientos por CCAA y año
avistamientos as (

    select
          prov.id_ccaa
        , extract(year from avi.fecha) as anio
        , avi.id_especie

    from {{ ref('stg_mix__avistamiento') }} avi

    inner join {{ ref('stg_mix__localizacion') }} loc
            on avi.id_avistamiento = loc.id_avistamiento

    inner join {{ ref('stg_mix__provincia') }} prov
            on loc.id_provincia = prov.id_provincia

    where avi.es_catalogada = true

),

-- Censos por CCAA y año
censos as (

    select
          prov.id_ccaa
        , cen.anio
        , cen.id_especie

    from {{ ref('stg_mix__censo_poblacion') }} cen

    inner join {{ ref('stg_mix__provincia') }} prov
            on cen.id_provincia = prov.id_provincia

    where cen.id_especie is not null

),

-- Union de ambas fuentes
base_union as (

    select id_ccaa, anio, id_especie from avistamientos
    union
    select id_ccaa, anio, id_especie from censos

),

-- Añadir estado de conservación
base as (

    select
          b.id_ccaa
        , b.anio
        , b.id_especie
        , e.estado_espana

    from base_union b

    left join especie_estado e
           on b.id_especie = e.id_especie

),

conteos as (

    select
          id_ccaa
        , anio
        , id_especie
        , count(*) as n_avistamientos

    from base

    group by
          id_ccaa
        , anio
        , id_especie

),

totales as (

    select
          id_ccaa
        , anio
        , sum(n_avistamientos) as n_total

    from conteos

    group by
          id_ccaa
        , anio

),

proporciones as (

    select
          c.id_ccaa
        , c.anio
        , c.id_especie
        , c.n_avistamientos
        , t.n_total
        , c.n_avistamientos / t.n_total::float as p

    from conteos c

    inner join totales t
            on c.id_ccaa = t.id_ccaa
           and c.anio    = t.anio

),

indices as (

    select
          id_ccaa
        , anio
        , -sum(p * ln(p))      as shannon_h
        , 1 - sum(power(p, 2)) as simpson_d

    from proporciones

    group by
          id_ccaa
        , anio

),

resumen as (

    select
          b.id_ccaa
        , b.anio
        , count(distinct b.id_especie)                                           as n_especies
        , count(*)                                                               as n_avistamientos_total
        , count(distinct case when b.estado_espana = 'CR' then b.id_especie end) as n_especies_cr
        , count(distinct case when b.estado_espana = 'EN' then b.id_especie end) as n_especies_en
        , count(distinct case when b.estado_espana = 'VU' then b.id_especie end) as n_especies_vu

    from base b

    group by
          b.id_ccaa
        , b.anio

)

select
      r.id_ccaa
    , r.anio
    , r.n_especies
    , r.n_avistamientos_total
    , i.shannon_h
    , i.simpson_d
    , r.n_especies_cr
    , r.n_especies_en
    , r.n_especies_vu

from resumen r

left join indices i
       on r.id_ccaa = i.id_ccaa
      and r.anio    = i.anio