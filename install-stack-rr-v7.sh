#!/bin/bash

# Script para automatizar a criação de um projeto React Router com shadcn/ui
# usando a abordagem de flags do CLI.

# --- Configuração ---
PROJECT_NAME=$1
BASE_COLOR="stone" # Cores disponíveis: slate, gray, zinc, neutral, stone
DIR_ATUAL=$(pwd)
PATH_COMPLETO=$DIR_ATUAL/$PROJECT_NAME

# --- Funções Auxiliares ---
print_message() {
  echo "-----------------------------------------------------"
  echo "$1"
  echo "-----------------------------------------------------"
}

# --- Script Principal ---

# 0. Criar e entrar no diretório do projeto
print_message "Criando diretório do projeto: $PROJECT_NAME"
print_message "Criando diretório do projeto: $PATH_COMPLETO"

mkdir "$PROJECT_NAME"
cd "$PROJECT_NAME" || exit

print_message "Diretório atual: $DIR_ATUAL"

# 1. Criar projeto React Router no diretório atual (.)
print_message "Criando projeto React Router (usando create-react-router)..."
# O -y tenta aceitar os padrões
pnpm dlx create-react-router@latest . -y

# Verificar se a criação do projeto foi bem-sucedida (ex: package.json existe)
if [ ! -f "package.json" ]; then
  echo "Erro: A criação do projeto React Router falhou."
  exit 1
fi
print_message "Projeto React Router criado."

# 2. Inicializar shadcn/ui
print_message "Inicializando shadcn/ui..."
# Usamos --yes para os prompts e especificamos a cor base.
# O shadcn/ui init com --yes deve tentar configurar os caminhos (components, utils, tailwind.css, etc.)
# de forma inteligente com base no projeto existente.
# A flag --overwrite é para o caso de o components.json já existir.
pnpm dlx shadcn@latest init -b "$BASE_COLOR" -y -f --no-src-dir
 
  # Nota: A flag --no-src-dir não é uma flag padrão explícita do 'init'.
  # No entanto, ao não usar '--src' e se o 'create-react-router' configurar
  # os aliases no tsconfig.json para 'app/' (ex: "~/*": ["./app/*"]),
  # o 'shadcn-ui init' com '--yes' deve respeitar essa estrutura não baseada em 'src/'.

# Verificar se components.json foi criado
if [ ! -f "components.json" ]; then
  echo "Erro: A inicialização do shadcn/ui falhou (components.json não encontrado)."
  echo "Pode ser necessário ajustar as flags do 'init' ou configurar manualmente."
  exit 1
fi
print_message "shadcn/ui inicializado. O ficheiro components.json foi criado/atualizado."
echo "Verifique o 'components.json' gerado para confirmar as configurações (especialmente os caminhos dos aliases)."




# 3. Adicionar todos os componentes shadcn/ui
print_message "Adicionando todos os componentes shadcn/ui..."
pnpm dlx shadcn@latest add --all -o

print_message "Configuração concluída!"
echo "Projeto '$PROJECT_NAME' está pronto em $(pwd)"
echo "LEMBRE-SE de verificar se os aliases de caminho no 'tsconfig.json'"
echo "(ex: '@/*' ou '~/*') estão configurados corretamente e apontam para a estrutura correta (ex: 'app/')."
echo "O 'shadcn/ui init' deve ter tentado alinhar o 'components.json' com isso."
echo "Para iniciar o servidor de desenvolvimento: pnpm dev"

cd "$PATH_COMPLETO"
cd "$PATH_COMPLETO"
