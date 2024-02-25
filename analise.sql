-- Quantos chamados foram abertos no dia 01/04/2023?
SELECT count(distinct id_chamado) FROM `datario.administracao_servicos_publicos.chamado_1746`
where DATE(data_inicio) = '2023-04-01'
-- Resposta: 73

-- Qual o tipo de chamado que teve mais teve chamados abertos no dia 01/04/2023?
SELECT count( distinct id_chamado) as total_chamados, id_tipo, tipo FROM `datario.administracao_servicos_publicos.chamado_1746`
where DATE(data_inicio) = '2023-04-01'
group by 2, 3
order by 1 desc
limit 1
-- Reposta: Chamado 1393 - Poluição Sonora

-- Quais os nomes dos 3 bairros que mais tiveram chamados abertos nesse dia?
SELECT count( distinct t1.id_chamado) as total_chamados, t2.nome as bairro
FROM `datario.administracao_servicos_publicos.chamado_1746` t1
left join `datario.dados_mestres.bairro` t2
on t1.id_bairro = t2.id_bairro
where DATE(t1.data_inicio) = '2023-04-01'
group by 2
order by 1 desc
limit 3
-- Resposta: Engenho de Dentro, Leblon e Campo Grande.


-- Qual o nome da subprefeitura com mais chamados abertos nesse dia?
SELECT count( distinct t1.id_chamado) as total_chamados, t2.subprefeitura
FROM `datario.administracao_servicos_publicos.chamado_1746` t1
left join `datario.dados_mestres.bairro` t2
on t1.id_bairro = t2.id_bairro
where DATE(t1.data_inicio) = '2023-04-01'
group by 2
order by 1 desc
limit 1

-- Resposta: Zona Norte, 25 chamados.

-- Existe algum chamado aberto nesse dia que não foi associado a um bairro ou subprefeitura na tabela de bairros? Se sim, por que isso acontece?
SELECT t1.id_chamado, t1.tipo, t1.subtipo
FROM `datario.administracao_servicos_publicos.chamado_1746` t1
left join `datario.dados_mestres.bairro` t2
on t1.id_bairro = t2.id_bairro
where DATE(t1.data_inicio) = '2023-04-01' and (t1.id_bairro is null or t2.subprefeitura is null )
-- Resposta: Sim, o identificado por 18516246. Por ser um chamado de ônibus, para a verificação do funcionamento do ar condicionado, é dificil precisar a localização do ocorrido.

-- Quantos chamados com o subtipo "Perturbação do sossego" foram abertos desde 01/01/2022 até 31/12/2023 (incluindo extremidades)?
-- Perturbação de sossego: 5071
SELECT count( distinct id_chamado)
FROM `datario.administracao_servicos_publicos.chamado_1746` 
where DATE(data_inicio) between '2022-01-01' and '2023-12-31' and id_subtipo = '5071'

-- Resposta: 42408 chamados.

-- Selecione os chamados com esse subtipo que foram abertos durante os eventos contidos na tabela de eventos (Reveillon, Carnaval e Rock in Rio).
SELECT
  t1.evento,
  t2.id_chamado
FROM
  `datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos` t1
LEFT JOIN
  `datario.administracao_servicos_publicos.chamado_1746` t2
ON
  DATE(data_inicio) BETWEEN t1.data_inicial AND t1.data_final
WHERE id_subtipo = '5071'

-- Quantos chamados desse subtipo foram abertos em cada evento?
SELECT
  t1.data_inicial,
  t1.data_final,
  t1.evento,
  COUNT(distinct id_chamado) AS total_chamados
FROM
  `datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos` t1
LEFT JOIN
  `datario.administracao_servicos_publicos.chamado_1746` t2
ON
  DATE(data_inicio) BETWEEN t1.data_inicial AND t1.data_final
WHERE id_subtipo = '5071'
GROUP BY
  t1.data_inicial,
  t1.data_final,
  t1.evento
ORDER BY
  t1.data_inicial;

-- Qual evento teve a maior média diária de chamados abertos desse subtipo?

with eventos as(
SELECT
  t1.evento,
  (count(distinct id_chamado) ) as chamados
FROM
  `datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos` t1
LEFT JOIN
  `datario.administracao_servicos_publicos.chamado_1746` t2
ON
  DATE(data_inicio) BETWEEN t1.data_inicial AND t1.data_final
WHERE id_subtipo = '5071'
GROUP BY 1),
dias_eventos as (
select evento, SUM(DATE_DIFF(data_final, data_inicial, DAY) + 1) total_dias
from `datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos`
group by 1)
select t1.*, ROUND(t1.chamados / t2.total_dias, 2) as media_diaria
from eventos t1
left join dias_eventos t2
on t1.evento = t2.evento
order by 3 desc
limit 1
-- Resposta: Rock in Rio, 119.14

-- Compare as médias diárias de chamados abertos desse subtipo durante os eventos específicos (Reveillon, Carnaval e Rock in Rio) e a média diária de chamados abertos desse subtipo considerando todo o período de 01/01/2022 até 31/12/2023.

with eventos as(
SELECT
  t1.evento,
  (count(distinct id_chamado) ) as chamados
FROM
  `datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos` t1
LEFT JOIN
  `datario.administracao_servicos_publicos.chamado_1746` t2
ON
  DATE(data_inicio) BETWEEN t1.data_inicial AND t1.data_final
WHERE id_subtipo = '5071'
GROUP BY 1),
dias_eventos as (
select evento, SUM(DATE_DIFF(data_final, data_inicial, DAY) + 1) total_dias
from `datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos`
group by 1),
media_total as (
SELECT count( distinct id_chamado) / (DATE_DIFF('2023-12-31', '2022-01-01', DAY) + 1) as media_diaria, count( distinct id_chamado) chamados
FROM `datario.administracao_servicos_publicos.chamado_1746` 
where DATE(data_inicio) between '2022-01-01' and '2023-12-31' and id_subtipo = '5071'

)
select t1.*, ROUND(t1.chamados / t2.total_dias, 2) as media_diaria
from eventos t1
left join dias_eventos t2
on t1.evento = t2.evento
union all
select 'Total' as evento, chamados, ROUND(media_diaria, 2) from media_total