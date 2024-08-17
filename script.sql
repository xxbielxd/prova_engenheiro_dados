use Banco_dados;

-- Vamos adicionar essa a coluna CodigoCurso ao Ranking
-- Como o ranking é por Série e Curso, achei muito pertinente ele estár na tabela ranking
ALTER TABLE Ranking ADD CodigoCurso INT NOT NULL;


CREATE PROCEDURE InserirRankingMerito
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        TRUNCATE TABLE Ranking;

        DECLARE @porcentagem_bolsa_primeiro DECIMAL = 70.00;
        DECLARE @porcentagem_bolsa_segundo DECIMAL = 50.00;
        DECLARE @porcentagem_bolsa_terceiro DECIMAL = 30.00;

        WITH MediaBolsaMerito AS (
            SELECT
                -- Esse Case Altera de onde a nota virá para a sua base de cálculo, Notas.Media1 ou Notas.MediaFinal, com base no Semestre 1 e 2 respectivamente
                Notas.CH * ((CASE WHEN Notas.Semestre = 1 THEN Notas.Media1 WHEN Notas.Semestre = 2 THEN Notas.MediaFinal ELSE NULL END))
                -- Nessa parte, eu retorno a soma da carga horária das matérias que o aluno está cursando,
                -- respeitando a regra de Disciplinas que não entram no calculo de acordo com o semestre
                / COALESCE(
                    (
                        SELECT SUM(CH)
                        FROM Notas as notas_carga_horaria
                        WHERE
                            notas_carga_horaria.RM = Notas.RM
                            AND notas_carga_horaria.CodigoCurso = Notas.CodigoCurso
                            AND notas_carga_horaria.Ano = Notas.Ano
                            AND notas_carga_horaria.Turma = Notas.Turma
                            AND notas_carga_horaria.Semestre = 1
                            -- Essas são as disciplinas que não entram no cálculo para o primeiro semestre
                            AND notas_carga_horaria.CodigoDisciplina not in (448,2627,3528,441)
                    ), (
                        SELECT SUM(CH)
                        FROM Notas as notas_carga_horaria
                        WHERE
                            notas_carga_horaria.RM = Notas.RM
                            AND notas_carga_horaria.CodigoCurso = Notas.CodigoCurso
                            AND notas_carga_horaria.Ano = Notas.Ano
                            AND notas_carga_horaria.Turma = Notas.Turma
                            AND notas_carga_horaria.Semestre = 2
                          -- Essas são as disciplinas que não entram no cálculo para o segundo semestre
                            AND notas_carga_horaria.CodigoDisciplina not in (448,441)
                    )

                ) as MediaSemestral,
                Notas.RM,
                Notas.Nome,
                Notas.Ano,
                Notas.Semestre,
                Notas.CodigoCurso,
                Notas.CodigoDisciplina,
                Notas.Turma,
                Notas.Media1,
                Notas.MediaFinal
            FROM Notas
            WHERE
                -- Retirar as disciplinas que não entram no cálculo
                (
                    (
                        Notas.Semestre = 1
                        AND Notas.CodigoDisciplina not in (448,2627,3528,441)
                    ) OR (
                        Notas.Semestre = 2
                        AND Notas.CodigoDisciplina not in (448, 441)
                    )
                )
        )
        INSERT INTO Ranking (RM, Nome, Ano, Semestre, Turma, CodigoCurso, QtdeDisciplina, MediaBolsaMerito, PosicaoBolsaMerito, MediaAcessoAlura)
        SELECT
            MediaBolsaMerito.RM,
            MediaBolsaMerito.Nome,
            MediaBolsaMerito.Ano,
            MediaBolsaMerito.Semestre,
            MediaBolsaMerito.Turma,
            MediaBolsaMerito.CodigoCurso,
            count(*) as QtdeDisciplina,
            -- usei o round, mas não foi especificado o tipo de arredondamento usado como floor ou ceiling
            ROUND(SUM(MediaBolsaMerito.MediaSemestral),3) as MediaBolsaMerito,
            -- O dense_rank da ranking aos registros ordenado pela média bolsa merito, cada curso e série do curso tem seu próprio ranking,
            -- quando a nota for igual o ranking será o mesmo
            DENSE_RANK() OVER (
                -- Adicionei esse LEFT, pois na documentação é informado que o semestre é informado pelo primeiro caracter da turma
                PARTITION BY LEFT(MediaBolsaMerito.Turma, 1), MediaBolsaMerito.CodigoCurso
                ORDER BY ROUND(SUM(MediaBolsaMerito.MediaSemestral),3) desc
            ) as PosicaoBolsaMerito,
            -- primeiramente coloquei a nota 0-10 e dei um arredondamento com duas casas decimais.
            -- Regra: se o aluno ficar com a média entre 7,75 e 7,99 a nota deve ser arredondada para 8
            CASE
                WHEN ROUND(SUM(MediaBolsaMerito.MediaSemestral)/10,2) >= 7.75 AND ROUND(SUM(MediaBolsaMerito.MediaSemestral)/10,2) < 8 THEN
                8
                ELSE ROUND(SUM(MediaBolsaMerito.MediaSemestral)/10,2)
            END as MediaAcessoAlura

        FROM MediaBolsaMerito
        GROUP BY
            MediaBolsaMerito.RM,
            MediaBolsaMerito.Nome,
            MediaBolsaMerito.Ano,
            MediaBolsaMerito.Semestre,
            MediaBolsaMerito.Turma,
            MediaBolsaMerito.CodigoCurso;
        -- Fiz separado a distribuição das bolsas para ficar menos complexo a Query
        -- Toda distribuição leva em conta o ranking do curso e semestre. Se tiver
        -- um aluno com a mesma média a porcentagem da bolsa será dividida entre eles.
        UPDATE
            Ranking
        SET PorcentagemBolsaMerito = ROUND(@porcentagem_bolsa_primeiro / (
                SELECT
                    count(*)
                FROM Ranking as sub_ranking
                WHERE
                    sub_ranking.CodigoCurso = Ranking.CodigoCurso
                    AND LEFT(sub_ranking.Turma, 1) = LEFT(Ranking.Turma, 1)
                    AND sub_ranking.PosicaoBolsaMerito = Ranking.PosicaoBolsaMerito
            ), 2)
        WHERE Ranking.PosicaoBolsaMerito = 1;
        -- Distribuição para o segundo lugar
        UPDATE
            Ranking
        SET PorcentagemBolsaMerito = ROUND(@porcentagem_bolsa_segundo / (
                SELECT
                    count(*)
                FROM Ranking as sub_ranking
                WHERE
                    sub_ranking.CodigoCurso = Ranking.CodigoCurso
                    AND LEFT(sub_ranking.Turma, 1) = LEFT(Ranking.Turma, 1)
                    AND sub_ranking.PosicaoBolsaMerito = Ranking.PosicaoBolsaMerito
            ),2)
        WHERE Ranking.PosicaoBolsaMerito = 2;
        -- Distribuição para o terceiro lugar
        UPDATE
            Ranking
        SET PorcentagemBolsaMerito = ROUND(@porcentagem_bolsa_terceiro / (
                SELECT
                    count(*)
                FROM Ranking as sub_ranking
                WHERE
                    sub_ranking.CodigoCurso = Ranking.CodigoCurso
                    AND LEFT(sub_ranking.Turma, 1) = LEFT(Ranking.Turma, 1)
                    AND sub_ranking.PosicaoBolsaMerito = Ranking.PosicaoBolsaMerito
            ), 2)
        WHERE Ranking.PosicaoBolsaMerito = 3;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW 500, 'Ocorreu um erro!.', 1;
    END CATCH
END;

-- Pensando no longo prazo, vamos criar alguns indices

-- Escolhi o DESC pois acredito que o sistema usará frequentemente dados mais recentes em suas funcionalidades
-- O que acredito que a longo prazo, manterá o alto desempenho

-- Index RM
CREATE INDEX idx_rm_notas ON Notas (RM DESC);
CREATE INDEX idx_rm_ranking ON Ranking (RM DESC);

-- Index CodigoCurso
CREATE INDEX idx_codigo_curso_notas ON Notas (CodigoCurso DESC);
CREATE INDEX idx_codigo_curso_ranking ON Ranking (CodigoCurso DESC);

-- Index CodigoDisciplina
CREATE INDEX idx_codigo_disciplina_notas ON Notas (CodigoDisciplina DESC);

-- Index Turma - Coloquei ASC só para manter o padrão, pois não fará diferença para esse campo o DESC
CREATE INDEX idx_turma_notas ON Notas (Turma ASC);
CREATE INDEX idx_turma_ranking ON Ranking (Turma ASC);

-- Acredito que há mais index para ser criado, mas inicialmente para o nosso propósito está ok.
-- Devemos tomar cuidado na criação de muitos indices, pois invés de ajudar pode atrapalhar, causando lentidão que é a ideia contrária dos índices.

-- Vamos executar a procedure
EXEC InserirRankingMerito;

-- Vamos verificar o resultado
SELECT
    Ranking.CodigoCurso,
    Ranking.Turma,
    Ranking.MediaBolsaMerito,
    Ranking.PosicaoBolsaMerito,
    Ranking.PorcentagemBolsaMerito,
    Ranking.MediaAcessoAlura
FROM Ranking
ORDER BY
    Ranking.CodigoCurso ASC,
    LEFT(Ranking.Turma, 1) ASC;


-- Exemplo de bolsa compartilhada
SELECT
    Ranking.CodigoCurso,
    Ranking.Turma,
    Ranking.MediaBolsaMerito,
    Ranking.PosicaoBolsaMerito,
    Ranking.PorcentagemBolsaMerito,
    Ranking.MediaAcessoAlura
FROM Ranking
WHERE
    Ranking.CodigoCurso = 189
ORDER BY
    Ranking.CodigoCurso ASC,
    LEFT(Ranking.Turma, 1) ASC;

-- Quantidade de bolsas liberadas
SELECT
    Count(*)
FROM Ranking
WHERE Ranking.PorcentagemBolsaMerito IS NOT NULL;

-- Quantidade de aprovados Alura
SELECT
    Count(*)
FROM Ranking
WHERE Ranking.MediaAcessoAlura >= 8;

-- Quantidade de reprovados acesso Alura
SELECT
    Count(*)
FROM Ranking
WHERE Ranking.MediaAcessoAlura < 8;
