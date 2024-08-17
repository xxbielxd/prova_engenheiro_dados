IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'Banco_Dados')
BEGIN
    CREATE DATABASE Banco_Dados;
END
GO
USE Banco_Dados
GO
IF EXISTS(SELECT * FROM SysObjects WHERE xtype='U' AND name = 'Notas')
BEGIN
	DROP TABLE Notas
END
GO
IF EXISTS(SELECT * FROM SysObjects WHERE xtype='U' AND name = 'Ranking')
BEGIN
	DROP TABLE Ranking
END
GO
CREATE TABLE Notas (
	Codigo INT NOT NULL IDENTITY,
	RM INT NOT NULL,
	Nome VARCHAR(255) NOT NULL,
	Ano INT NOT NULL,
	Semestre INT NOT NULL,
	Turma VARCHAR(10) NOT NULL,
	CodigoCurso INT NOT NULL,
	NomeCurso VARCHAR(255) NOT NULL,
	CodigoDisciplina INT NOT NULL,
	Disciplina VARCHAR(255) NOT NULL,
	CH INT NOT NULL,
	Nac1 FLOAT,
	PS1 FLOAT,
	Media1 FLOAT,
	Nac2 FLOAT,
	PS2 FLOAT,
	Media2 FLOAT,
	MediaParcial FLOAT,
	NotaExame FLOAT,
	MediaFinal FLOAT,
	Resultado VARCHAR(30)
)
GO
CREATE TABLE Ranking (
	Codigo INT NOT NULL IDENTITY,
	RM INT NOT NULL,
	Nome VARCHAR(255) NOT NULL,
	Ano INT NOT NULL,
	Semestre INT NOT NULL,
	Turma VARCHAR(10) NOT NULL,
	QtdeDisciplina INT,
	MediaBolsaMerito FLOAT,
	PosicaoBolsaMerito INT,
	PorcentagemBolsaMerito FLOAT,
	MediaAcessoAlura FLOAT
)
