# Use uma imagem base oficial do Python
FROM python:3.9-slim

# Instalar dependências básicas
RUN apt-get update && apt-get install -y \
    unixodbc-dev \
    gnupg2 \
    curl \
    gcc \
    g++

# Adicionar a chave e o repositório da Microsoft
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/debian/10/prod.list > /etc/apt/sources.list.d/mssql-release.list

# Atualizar e instalar o driver ODBC do SQL Server
RUN apt-get update && ACCEPT_EULA=Y apt-get install -y msodbcsql17

# Limpar cache do apt para reduzir o tamanho da imagem
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Instalar as dependências Python, incluindo xlrd
RUN pip install pandas pyodbc xlrd

# Define o diretório de trabalho
WORKDIR /app

# Copia o script Python e o arquivo Excel para o diretório de trabalho
COPY . /app

# Comando para rodar o script Python
CMD ["python", "init.py"]
