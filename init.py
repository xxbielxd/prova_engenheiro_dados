import pandas as pd
import pyodbc

# Configuração da conexão ao SQL Server
conn_str = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=sqlserver;"
    "DATABASE=Banco_Dados;"
    "UID=sa;"
    "PWD=Senha123!"
)

# Conectar ao SQL Server
conn = pyodbc.connect(conn_str)
cursor = conn.cursor()

# Executar o script SQL para criar a tabela e configurar o banco de dados
with open('/app/init.sql', 'r') as sql_file:
    sql_script = sql_file.read()

# Executar o script SQL
cursor.execute(sql_script)

# Ler o arquivo Excel
file_path = r'/app/notas.xls'
sheet_name = 'Notas'
df = pd.read_excel(file_path, sheet_name=sheet_name)

# Converter todas as colunas numéricas para garantir que os valores sejam válidos
for col in df.select_dtypes(include=['float', 'int']).columns:
    df[col] = pd.to_numeric(df[col], errors='coerce')

# Tratar todos os campos NaN:
# Aqui, substituímos NaN por 0 para colunas numéricas e por '' (string vazia) para colunas de texto
df.fillna(value={
    'RM': 0,
    'Nome': '',
    'Ano': 0,
    'Semestre': 0,
    'Turma': '',
    'CodigoCurso': 0,
    'NomeCurso': '',
    'CodigoDisciplina': 0,
    'Disciplina': '',
    'CH': 0,
    'Nac1': 0.0,
    'PS1': 0.0,
    'Media1': 0.0,
    'Nac2': 0.0,
    'PS2': 0.0,
    'Media2': 0.0,
    'MediaParcial': 0.0,
    'NotaExame': 0.0,
    'MediaFinal': 0.0,
    'Resultado': ''
}, inplace=True)

print(df)
# Consulta SQL para inserção de dados
insert_query = """
    INSERT INTO Notas (
        RM, Nome, Ano, Semestre, Turma, CodigoCurso, NomeCurso, 
        CodigoDisciplina, Disciplina, CH, Nac1, PS1, Media1, 
        Nac2, PS2, Media2, MediaParcial, NotaExame, MediaFinal, Resultado
    ) 
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
"""

# Inserir dados no SQL Server
for _, row in df.iterrows():
    print(row['RM'])
    cursor.execute(insert_query, 
      row['RM'], row['Nome'], row['Ano'], row['Semestre'], 
      row['Turma'], row['CodigoCurso'], row['NomeCurso'], 
      row['CodigoDisciplina'], row['Disciplina'], row['CH'], 
      row['Nac1'], row['PS1'], row['Media1'], row['Nac2'], 
      row['PS2'], row['Media2'], row['MediaParcial'], 
      row['NotaExame'], row['MediaFinal'], row['Resultado']
    )

# Confirmar a transação e fechar a conexão
conn.commit()
cursor.close()
conn.close()
