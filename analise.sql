-- Quantos chamados foram abertos no dia 01/04/2023?
SELECT COUNT(DISTINCT id_chamado) AS total_chamados 
FROM `datario.administracao_servicos_publicos.chamado_1746`
WHERE DATE(data_inicio) = '2023-04-01';
-- Resposta: 73

-- Qual o tipo de chamado que teve mais teve chamados abertos no dia 01/04/2023?
SELECT COUNT(DISTINCT id_chamado) AS total_chamados, id_tipo, tipo 
FROM `datario.administracao_servicos_publicos.chamado_1746`
WHERE DATE(data_inicio) = '2023-04-01'
GROUP BY id_tipo, tipo
ORDER BY total_chamados DESC
LIMIT 1;
-- Reposta: Chamado 1393 - Poluição Sonora

-- Quais os nomes dos 3 bairros que mais tiveram chamados abertos nesse dia?
SELECT COUNT(DISTINCT t1.id_chamado) AS total_chamados, t2.nome AS bairro
FROM `datario.administracao_servicos_publicos.chamado_1746` t1
LEFT JOIN `datario.dados_mestres.bairro` t2 ON t1.id_bairro = t2.id_bairro
WHERE DATE(t1.data_inicio) = '2023-04-01'
GROUP BY t2.nome
ORDER BY total_chamados DESC
LIMIT 3;
-- Resposta: Engenho de Dentro, Leblon e Campo Grande.


-- Qual o nome da subprefeitura com mais chamados abertos nesse dia?
SELECT COUNT(DISTINCT t1.id_chamado) AS total_chamados, t2.subprefeitura
FROM `datario.administracao_servicos_publicos.chamado_1746` t1
LEFT JOIN `datario.dados_mestres.bairro` t2 ON t1.id_bairro = t2.id_bairro
WHERE DATE(t1.data_inicio) = '2023-04-01'
GROUP BY t2.subprefeitura
ORDER BY total_chamados DESC
LIMIT 1;

-- Resposta: Zona Norte, 25 chamados.

-- Existe algum chamado aberto nesse dia que não foi associado a um bairro ou subprefeitura na tabela de bairros? Se sim, por que isso acontece?
SELECT t1.id_chamado, t1.tipo, t1.subtipo
FROM `datario.administracao_servicos_publicos.chamado_1746` t1
LEFT JOIN `datario.dados_mestres.bairro` t2 ON t1.id_bairro = t2.id_bairro
WHERE DATE(t1.data_inicio) = '2023-04-01' AND (t1.id_bairro IS NULL OR t2.subprefeitura IS NULL);
-- Resposta: Sim, o identificado por 18516246. Por ser um chamado de ônibus, para a verificação do funcionamento do ar condicionado, é dificil precisar a localização do ocorrido.

-- Quantos chamados com o subtipo "Perturbação do sossego" foram abertos desde 01/01/2022 até 31/12/2023 (incluindo extremidades)?
-- Perturbação de sossego: 5071
SELECT COUNT(DISTINCT id_chamado)
FROM `datario.administracao_servicos_publicos.chamado_1746` 
WHERE DATE(data_inicio) BETWEEN '2022-01-01' AND '2023-12-31' AND id_subtipo = '5071';


-- Resposta: 42408 chamados.

-- Selecione os chamados com esse subtipo que foram abertos durante os eventos contidos na tabela de eventos (Reveillon, Carnaval e Rock in Rio).
SELECT t1.evento, t2.id_chamado
FROM `datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos` t1
LEFT JOIN `datario.administracao_servicos_publicos.chamado_1746` t2 
ON DATE(data_inicio) BETWEEN t1.data_inicial AND t1.data_final
WHERE id_subtipo = '5071';

-- Quantos chamados desse subtipo foram abertos em cada evento?
SELECT t1.data_inicial, t1.data_final, t1.evento, COUNT(DISTINCT t2.id_chamado) AS total_chamados
FROM `datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos` t1
LEFT JOIN `datario.administracao_servicos_publicos.chamado_1746` t2 
ON DATE(data_inicio) BETWEEN t1.data_inicial AND t1.data_final
WHERE id_subtipo = '5071'
GROUP BY t1.data_inicial, t1.data_final, t1.evento
ORDER BY t1.data_inicial;

-- Qual evento teve a maior média diária de chamados abertos desse subtipo?

WITH eventos AS (
    SELECT t1.evento, COUNT(DISTINCT t2.id_chamado) AS chamados
    FROM `datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos` t1
    LEFT JOIN `datario.administracao_servicos_publicos.chamado_1746` t2 
    ON DATE(data_inicio) BETWEEN t1.data_inicial AND t1.data_final
    WHERE id_subtipo = '5071'
    GROUP BY t1.evento
),
dias_eventos AS (
    SELECT evento, SUM(DATE_DIFF(data_final, data_inicial, DAY) + 1) AS total_dias
    FROM `datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos`
    GROUP BY evento
)
SELECT t1.*, ROUND(t1.chamados / t2.total_dias, 2) AS media_diaria
FROM eventos t1
LEFT JOIN dias_eventos t2 ON t1.evento = t2.evento
ORDER BY media_diaria DESC
LIMIT 1;
-- Resposta: Rock in Rio, 119.14

-- Compare as médias diárias de chamados abertos desse subtipo durante os eventos específicos (Reveillon, Carnaval e Rock in Rio) e a média diária de chamados abertos desse subtipo considerando todo o período de 01/01/2022 até 31/12/2023.
WITH eventos AS (
    SELECT t1.evento, COUNT(DISTINCT t2.id_chamado) AS chamados
    FROM `datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos` t1
    LEFT JOIN `datario.administracao_servicos_publicos.chamado_1746` t2 
    ON DATE(data_inicio) BETWEEN t1.data_inicial AND t1.data_final
    WHERE id_subtipo = '5071'
    GROUP BY t1.evento
),
dias_eventos AS (
    SELECT evento, SUM(DATE_DIFF(data_final, data_inicial, DAY) + 1) AS total_dias
    FROM `datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos`
    GROUP BY evento
),
media_total AS (
    SELECT COUNT(DISTINCT id_chamado) / (DATE_DIFF('2023-12-31', '2022-01-01', DAY) + 1) AS media_diaria, COUNT(DISTINCT id_chamado) AS chamados
    FROM `datario.administracao_servicos_publicos.chamado_1746` 
    WHERE DATE(data_inicio) BETWEEN '2022-01-01' AND '2023-12-31' AND id_subtipo = '5071'
)
SELECT t1.evento, t1.chamados, ROUND(t1.chamados / t2.total_dias, 2) AS media_diaria
FROM eventos t1
LEFT JOIN dias_eventos t2 ON t1.evento = t2.evento
UNION ALL
SELECT 'Total' AS evento, chamados, ROUND(media_diaria, 2)
FROM media_total;