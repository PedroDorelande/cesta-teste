#!/bin/bash

# Para tornar este script executável, use o comando:
# chmod +x kill-all.sh
#
# O que o comando faz:
# - `chmod`: Abreviação de "change mode", altera as permissões do arquivo.
# - `+x`: Adiciona (+) a permissão de execução (x).
#
# Por padrão, arquivos de texto não têm permissão de execução por segurança.
# Este comando informa ao sistema que o arquivo é um programa confiável e pode ser executado.

# Encontra e finaliza o processo na porta 3000 (Frontend)
echo "Procurando e finalizando processo na porta 3000 (Frontend)..."
PID_FRONT=$(lsof -t -i:3000)
if [ -n "$PID_FRONT" ]; then
  kill -9 $PID_FRONT
  echo "Processo do Frontend (PID: $PID_FRONT) finalizado."
else
  echo "Nenhum processo do Frontend encontrado na porta 3000."
fi

echo ""

# Encontra e finaliza o processo na porta 3001 (Backend)
echo "Procurando e finalizando processo na porta 3001 (Backend)..."
PID_BACK=$(lsof -t -i:3001)
if [ -n "$PID_BACK" ]; then
  kill -9 $PID_BACK
  echo "Processo do Backend (PID: $PID_BACK) finalizado."
else
  echo "Nenhum processo do Backend encontrado na porta 3001."
fi

echo ""
echo "Operação concluída."
