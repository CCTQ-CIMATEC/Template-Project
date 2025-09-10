#!/bin/bash

# Processar arquivos proj.config
for path in $(find ../ -name proj.config); do
    # Extrair apenas o valor de PROJNAME (até o ponto e vírgula)
    projname=$(grep -oP 'PROJNAME=\K[^;]*' "$path" | tr -d ' ')
    
    # Verificar se encontrou um nome válido
    if [ -n "$projname" ]; then
        # Definir a variável com o nome do projeto
        declare "$projname"="$(dirname "$path")"
        #echo "Definida variável: $projname = $(dirname "$path")"
    fi
done

# Função para processar listas de fontes
srclist2paths () {
    local srclist=$1
    local srcfile
    
    # Usar while read para lidar melhor com quebras de linha
    while IFS= read -r srcfile; do
        # Expandir variáveis se existirem no caminho
        srcfile=$(eval echo "$srcfile")
        
        if [[ $(basename "$srcfile") =~ ".srclist" ]]; then
            # Se for outra lista, processar recursivamente
            srclist2paths "$srcfile"
        else
            # Adicionar à lista se não estiver presente
            if [[ ! "$list" =~ "$srcfile" ]]; then
                list="${list} ${srcfile}"
            fi
        fi
    done < "$srclist"
}

# Processar arquivos
list=""
for srclist in "$@"; do
    srclist2paths "$srclist"
done

echo "${list}"