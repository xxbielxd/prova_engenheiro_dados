#!/bin/bash

# Define o máximo de tentativas de conexão
max_attempts=10
attempt=0

# Tenta conectar ao SQL Server até que seja bem-sucedido
until /opt/mssql-tools/bin/sqlcmd -S sqlserver -U sa -P Senha123! -Q "SELECT 1" > /dev/null 2>&1 || [ $attempt -eq $max_attempts ]; do
  echo "Tentativa de conexão ao SQL Server: $((++attempt))"
  sleep 5
done

if [ $attempt -eq $max_attempts ]; then
  echo "Falha ao conectar ao SQL Server após $max_attempts tentativas."
  exit 1
fi

echo "Conexão ao SQL Server bem-sucedida!"

# Verifica se o banco de dados já existe e cria se necessário
/opt/mssql-tools/bin/sqlcmd -S sqlserver -U sa -P Senha123! -Q "IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'Banco_Dados') BEGIN CREATE DATABASE Banco_Dados; END"
/opt/mssql-tools/bin/sqlcmd -S sqlserver -U sa -P Senha123! -i /init.sql

# Executa o script Python para importar os dados
python /app/init.py

echo "Processo de inicialização e importação de dados completo!"