#!/bin/bash

# Script: Git Commits & Code Changes Ranking
# Descrição: Gera ranking de commits e linhas alteradas por colaborador
# Uso: ./git-ranking.sh

# Cores
RESET='\033[0m'
BOLD='\033[1m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
MAGENTA='\033[35m'
RED='\033[31m'

# Função para criar barra de progresso
create_bar() {
  local value=$1
  local total=$2
  local bar_width=20

  if [ "$total" -eq 0 ]; then
    echo ""
    return
  fi

  local percentage=$((value * 100 / total))
  local filled=$((percentage * bar_width / 100))

  local bar=""
  for ((i = 0; i < filled; i++)); do
    bar="${bar}█"
  done

  for ((i = filled; i < bar_width; i++)); do
    bar="${bar}░"
  done

  echo "$bar"
}

# Inicializa arrays associativos temporários
declare -A author_lines
declare -A author_adds
declare -A author_dels

# Coleta dados de linhas por autor
while IFS=$'\t' read -r add del file; do
  add=${add:-0}
  del=${del:-0}

  # Pega o autor do arquivo
  author=$(git log --format='%an' -1 -- "$file" 2>/dev/null | head -1)

  if [ -n "$author" ]; then
    author_lines["$author"]=$((${author_lines["$author"]:-0} + add + del))
    author_adds["$author"]=$((${author_adds["$author"]:-0} + add))
    author_dels["$author"]=$((${author_dels["$author"]:-0} + del))
  fi
done < <(git log --all --no-merges --format=format: --numstat -- ':(exclude)dashboard-scripts-1/**' 2>/dev/null)

# ==================== HEADER ====================
echo -e "${BOLD}${CYAN}🏆 RANKING DE CONTRIBUIÇÕES - CESTAS DE COMPRAS${RESET}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${RESET}"
echo ""

TOTAL_COMMITS=$(git rev-list --all --count -- ':(exclude)dashboard-scripts-1/**')
TOTAL_COLLABORATORS=$(git shortlog -sn --all -- ':(exclude)dashboard-scripts-1/**' | wc -l)

TOTAL_ADDS=0
TOTAL_DELS=0
for author in "${!author_adds[@]}"; do
  TOTAL_ADDS=$((TOTAL_ADDS + ${author_adds[$author]:-0}))
  TOTAL_DELS=$((TOTAL_DELS + ${author_dels[$author]:-0}))
done

echo -e "${BOLD}📊 ESTATÍSTICAS GERAIS:${RESET}"
echo -e "   Total de commits: ${YELLOW}${TOTAL_COMMITS}${RESET}"
echo -e "   Total de colaboradores: ${YELLOW}${TOTAL_COLLABORATORS}${RESET}"
echo -e "   Total de linhas adicionadas: ${GREEN}+${TOTAL_ADDS}${RESET}"
echo -e "   Total de linhas removidas: ${RED}-${TOTAL_DELS}${RESET}"
echo -e "   Mudança líquida: ${MAGENTA}$((TOTAL_ADDS - TOTAL_DELS))${RESET}"
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${RESET}"
echo ""

# ==================== RANKING 1: POR COMMITS ====================
echo -e "${BOLD}${MAGENTA}📈 RANKING 1: POR COMMITS${RESET}"
echo -e "${MAGENTA}───────────────────────────────────────────────────────────────────${RESET}"
echo ""

RANK=1
MEDALS=("🥇" "🥈" "🥉")

git shortlog -sn --all --no-merges -- ':(exclude)dashboard-scripts-1/**' | while read count author; do
  author=$(echo "$author" | xargs)
  percentage=$((count * 100 / TOTAL_COMMITS))

  if [ $RANK -le 3 ]; then
    medal="${MEDALS[$((RANK - 1))]}"
    position_str="${medal} ${RANK}º"
  else
    position_str="   ${RANK}º"
  fi

  bar=$(create_bar $count $TOTAL_COMMITS)

  printf "${BOLD}%-8s${RESET} %-25s ${YELLOW}%3d commits${RESET} (${GREEN}%5.1f%%${RESET}) %s\n" \
    "$position_str" "$author" "$count" "$percentage" "$bar"

  RANK=$((RANK + 1))
done

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${RESET}"
echo ""

# ==================== RANKING 2: POR LINHAS ALTERADAS ====================
echo -e "${BOLD}${MAGENTA}💻 RANKING 2: POR LINHAS ALTERADAS${RESET}"
echo -e "${MAGENTA}───────────────────────────────────────────────────────────────────${RESET}"
echo ""

RANK=1
TOTAL_CHANGES=$((TOTAL_ADDS + TOTAL_DELS))

# Criar array ordenado
for author in "${!author_lines[@]}"; do
  echo "${author_lines[$author]}:${author}:${author_adds[$author]:-0}:${author_dels[$author]:-0}"
done | sort -t: -k1 -rn | while IFS=: read -r total author adds dels; do
  if [ -z "$author" ]; then
    continue
  fi

  percentage=$((total * 100 / TOTAL_CHANGES))

  if [ $RANK -le 3 ]; then
    medal="${MEDALS[$((RANK - 1))]}"
    position_str="${medal} ${RANK}º"
  else
    position_str="   ${RANK}º"
  fi

  bar=$(create_bar $total $TOTAL_CHANGES)

  printf "${BOLD}%-8s${RESET} %-25s ${GREEN}+%-5d${RESET} ${RED}-%-5d${RESET} (${MAGENTA}%d linhas${RESET}, ${GREEN}%5.1f%%${RESET}) %s\n" \
    "$position_str" "$author" "$adds" "$dels" "$total" "$percentage" "$bar"

  RANK=$((RANK + 1))
done

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${RESET}"
echo ""

# ==================== TOP 5 RESUMO ====================
echo -e "${BOLD}${GREEN}📊 TOP 5 CONTRIBUIDORES (RESUMO COMPLETO)${RESET}"
echo -e "${GREEN}───────────────────────────────────────────────────────────────────${RESET}"
echo ""
printf "${BOLD}%-5s %-25s %10s  %15s${RESET}\n" "Pos" "Nome" "Commits" "Linhas Alteradas"
echo -e "${GREEN}───────────────────────────────────────────────────────────────────${RESET}"

git shortlog -sn --all --no-merges -- ':(exclude)dashboard-scripts-1/**' | head -5 | nl | while read rank count author; do
  author=$(echo "$author" | xargs)
  lines=${author_lines[$author]:-0}

  if [ $rank -le 3 ]; then
    medals=("🥇" "🥈" "🥉")
    pos="${medals[$((rank-1))]} ${rank}º"
  else
    pos="   ${rank}º"
  fi

  printf "%-6s %-25s %10d  %15d\n" "$pos" "$author" "$count" "$lines"
done

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}✨ Relatório gerado em:${RESET} $(date '+%d/%m/%Y às %H:%M:%S')"
echo ""
