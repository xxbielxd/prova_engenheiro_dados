
# Prova para Engenheiro de Dados

Este projeto foi desenvolvido utilizando Docker para garantir a compatibilidade no momento da execução, como por exemplo a versão do banco de dados SQL Server. O objetivo é facilitar a importação de dados para uma tabela SQL Server a partir de um arquivo Excel.

## Requisitos

- **Docker**: Para rodar o banco de dados SQL Server e a aplicação de importação de dados.
- **Python**: Caso você opte por rodar o script manualmente, será necessário ter o Python instalado.

<p style="color: red;"><strong>Atenção:</strong> Por questões de segurança, o arquivo <code>notas.xls</code> não foi versionado no repositório. Certifique-se de colocar o arquivo na pasta com o nome exatamente como <code>notas.xls</code> antes de executar os scripts ou os comandos Docker.</p>

## Instruções para Configuração e Execução

### 1. Configuração do Banco de Dados com Docker

Se você ainda não possui um ambiente SQL Server configurado, siga os passos abaixo para configurar o banco de dados e importar os dados automaticamente:

#### 1.1. Levantar o Banco de Dados

Execute os comandos abaixo para levantar o banco de dados:

```bash
docker-compose down
docker-compose up -d
```

#### 1.2. Gerar a Imagem para Importação de Dados

Construa a imagem Docker para o processo de importação de dados:

```bash
docker build -t python-sql-server-importer .
```

#### 1.3. Executar a Importação dos Dados

Rode o contêiner para importar os dados do arquivo Excel para o banco de dados:

```bash
docker run --rm -v ${PWD}:/app --network sql_network_teste python-sql-server-importer
```

### 2. Acesso ao Banco de Dados

Após o banco de dados estar configurado e em execução, você pode acessá-lo usando as seguintes credenciais:

- **IP**: 127.0.0.1
- **Porta**: 1433
- **Login**: sa
- **Senha**: Senha123!

### 3. Execução Manual (Sem Docker)

Caso você já tenha um ambiente SQL Server configurado e deseje realizar a importação dos dados manualmente, siga os passos abaixo:

#### 3.1. Criação das Tabelas

O arquivo `init.sql` contém os comandos SQL para a criação das tabelas necessárias. Você pode executar esse script no SQL Server 2022 para preparar o banco de dados.

#### 3.2. Instalação das Dependências Python

Caso opte por rodar o script Python manualmente, siga os passos:

1. Certifique-se de que o Python está instalado em sua máquina.
2. Instale as dependências necessárias usando o arquivo `requirements.txt`:

   ```bash
   pip install -r requirements.txt
   ```

#### 3.3. Execução do Script Python

Após instalar as dependências, execute o script `init.py` para importar os dados:

```bash
python init.py
```

### 4. Observações

- **Compatibilidade**: Este projeto foi testado usando o SQL Server 2022.
- **Preferência por Docker**: Para um ambiente mais rápido e sem problemas de compatibilidade, recomendamos seguir os passos utilizando Docker.

### 5. Projeto

Todo o desenvolvimento foi realizado no arquivo `script.sql`, que inclui a criação da procedure `InserirRankingMerito` e os testes realizados. A procedure é responsável por calcular a média de mérito dos alunos e distribuir as bolsas com base na posição de cada aluno em seu curso e semestre.

#### 5.1. Detalhes da Procedure

- **Criação das Variáveis de Porcentagem**: As variáveis `@porcentagem_bolsa_primeiro`, `@porcentagem_bolsa_segundo` e `@porcentagem_bolsa_terceiro` são usadas para definir as porcentagens de bolsa que serão distribuídas entre os alunos de acordo com sua posição no ranking.
  
- **Cálculo da Média Semestral**: A procedure utiliza um `WITH` comum (CTE) chamado `MediaBolsaMerito` para calcular a média semestral de cada aluno em cada disciplina, considerando a carga horária e a nota final (para o semestre 2) ou a nota intermediária (para o semestre 1).

- **Distribuição de Bolsas**: A distribuição das bolsas é feita com base na posição do aluno no ranking (calculado usando `DENSE_RANK`). O rank é particionado por curso e série (identificado pelo primeiro caractere da turma). As bolsas são distribuídas de forma proporcional, sendo divididas igualmente entre alunos com a mesma posição.

- **Índices Criados**: Foram criados vários índices para otimizar a consulta e a execução das operações no banco de dados. Os índices foram criados nas colunas mais utilizadas nas consultas, como `RM`, `CodigoCurso`, `CodigoDisciplina`, e `Turma`.

#### 5.2. Testes e Execuções

- **Execução da Procedure**: A procedure é executada para calcular e distribuir as bolsas.
  
- **Verificação dos Resultados**: Após a execução, são realizadas várias consultas para verificar os resultados, incluindo o número de bolsas distribuídas, alunos aprovados e reprovados para acesso a plataformas como Alura.

### Conclusão

Se você deseja uma configuração rápida e sem problemas de compatibilidade, sugerimos seguir os passos utilizando Docker. No entanto, se preferir realizar a configuração manualmente, certifique-se de seguir os passos fornecidos para garantir que o ambiente esteja configurado corretamente.

