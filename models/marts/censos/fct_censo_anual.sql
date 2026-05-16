-- ===========================================================================
-- fct_censo_anual.sql
-- ===========================================================================

with censo as (

    select *
    from {{ ref('stg_mix__censo_poblacion') }}

),

provincia as (

    select *
    from {{ ref('dim_lugar') }}

),

base as (

    select
          c.id_censo
        , c.id_especie
        , c.id_provincia
        , p.ccaa
        , c.anio
        , c.n_individuos_estimados
        , c.n_parejas_reproductoras

        , lag(c.n_individuos_estimados) over (
            partition by c.id_especie, c.id_provincia
            order by c.anio
          ) as n_individuos_anterior

    from censo c

    left join provincia p
           on c.id_provincia = p.id_provincia

)

select
      id_censo
    , id_especie
    , id_provincia
    , ccaa
    , anio
    , n_individuos_estimados
    , n_parejas_reproductoras

    , n_individuos_estimados - n_individuos_anterior
        as variacion_vs_anterior

    , case
        when n_individuos_anterior is null then null
        when n_individuos_anterior = 0 then null
        else round(
            ((n_individuos_estimados - n_individuos_anterior)
             / n_individuos_anterior) * 100,
            2
        )
      end as variacion_pct_vs_anterior

    , case
        when n_individuos_anterior is null then 'sin_referencia'
        when n_individuos_estimados > n_individuos_anterior then 'alza'
        when n_individuos_estimados < n_individuos_anterior then 'baja'
        else 'estable'
      end as tendencia

from base