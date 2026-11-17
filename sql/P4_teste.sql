SELECT tipo, COUNT(*) AS quantidade
FROM users
GROUP BY tipo
ORDER BY tipo;

SELECT * FROM dashboard_admin_totais();
SELECT COUNT(*) AS total_corridas FROM relatorio_admin_corridas_total();

SELECT COUNT(*) AS total_status_admin
FROM relatorio_admin_status();

SELECT COUNT(*) AS total_aeroportos_sao_paulo
FROM relatorio_admin_aeroportos_por_cidade('São Paulo');

SELECT COUNT(*) AS total_escuderias_relatorio
FROM relatorio_admin_escuderias_pilotos();

SELECT COUNT(*) AS total_circuitos_relatorio
FROM relatorio_admin_corridas_por_circuito();

SELECT COUNT(*) AS total_corridas_detalhe
FROM relatorio_admin_corridas_detalhe();

SELECT COUNT(*) AS total_pilotos_mclaren
FROM relatorio_escuderia_vitorias_pilotos(20);

SELECT COUNT(*) AS total_status_mclaren
FROM relatorio_escuderia_status(20);

SELECT COUNT(*) AS total_corridas_pontuadas_hamilton
FROM relatorio_piloto_pontos_ano_corrida(83);

SELECT COUNT(*) AS total_status_hamilton
FROM relatorio_piloto_status(83);

SELECT *
FROM consultar_piloto_escuderia_por_sobrenome(20, 'Senna');

SELECT COUNT(*) AS total_associacoes_manuais
FROM constructor_drivers_manual;
