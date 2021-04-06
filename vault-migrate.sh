#!/bin/bash

chemin=""
source=""
sourceToken="";
target="";
targetToken="";

# On récupére les paramétres
while [ $# -gt 0 ]; do
  case "$1" in
    --source=*)
      source="${1#*=}"
      ;;
    --source-token=*)
      sourceToken="${1#*=}"
      ;;
    --path=*)
      chemin="${1#*=}"
      ;;
    --target=*)
      target="${1#*=}"
      ;;
    --target-token=*)
      targetToken="${1#*=}"
      ;;
  esac
  shift
done

#command -v vault >/dev/null 2>&1 || { echo >&2 "Vault est requis mais n'est pas installé..."; exit 1; }

if [[ -z "$source" || -z "$sourceToken" || -z "$chemin" || -z "$target" || -z "$targetToken" ]]; then
    echo -e "\nParamétre(s) manquant(s)"
    echo -e "\n--source=${source} \n--source-token=${sourceToken} \n--target=${target} \n--target-token=${targetToken} \n--path=${chemin}"
    exit;
fi

# on va lire des données de la source
sourceListe='source_list_vault.txt'
sourceGet='source_get_vault.txt'
VAULT_ADDR=${source}
VAULT_TOKEN=${sourceToken}
vault kv list ${chemin} > $sourceListe
if [ $? -eq 0 ]; then
    pattern='=|Key|-'
    while read sousDossier; do
        chainePut=""
        if [[ ! $sousDossier =~ ^[$pattern] ]]; then
            echo -e "${chemin}/${sousDossier}"
            sousChemin="${chemin}/${sousDossier}"
            VAULT_ADDR=${source}
            VAULT_TOKEN=${sourceToken}
            vault kv get --format=table ${sousChemin} > $sourceGet

            while read param; do
                if [[ $param != "="* && $param != "Key"* && $param != "---"* ]]; then
                    arrIN=(${param//\\t/-})
                    valeur=$(echo ${arrIN[1]} | sed 's/^@/\\@/')
                    chainePut+="${arrIN[0]}=${valeur} "
                fi
            done < $sourceGet
            VAULT_TOKEN=${targetToken}
            echo -e "vault write -address=${target} ${sousChemin} ${chainePut}"
            vault kv put -address=${target} ${sousChemin} ${chainePut}  
        fi
    done < $sourceListe
fi
