# cc [projeto] [args do claude] — entra na pasta do projeto e abre o Claude Code ali.
#
# Instalar: acrescentar no ~/.bashrc a linha
#   source /caminho/para/cc-projeto.sh
# e abrir um terminal novo (ou `source ~/.bashrc`).
#
# Uso:
#   cc portal        → cd ~/projetos/portal && claude
#   cc port          → nome parcial: um achado vai direto, vários mostram lista numerada
#   cc portal -c     → idem, continuando a última conversa daquele projeto
#   cc               → abre o Claude na pasta atual
#
# Ajustes por variável de ambiente (opcionais):
#   CC_BASE      pasta dos projetos            (padrão: ~/projetos)
#   CC_LAUNCHER  script que abre o Claude      (padrão: $CC_BASE/cc.sh, senão o cc.sh ao lado
#                deste arquivo, senão `claude`)
#
# Obs.: no terminal interativo, `cc` passa a ser esta função em vez do compilador C
# (/usr/bin/cc). make/gcc e scripts não são afetados — funções não são herdadas.

_CC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cc() {
  local base="${CC_BASE:-$HOME/projetos}" alvo="" q="${1:-}" n
  if [[ -n "$q" && "$q" != -* ]]; then
    shift
    if [[ -d "$base/$q" ]]; then
      alvo="$base/$q"
    else
      local -a achados
      mapfile -t achados < <(find "$base" -mindepth 1 -maxdepth 1 -type d -iname "*$q*" -printf '%f\n' | sort)
      case ${#achados[@]} in
        0) echo "Nenhum projeto com '$q' em $base"; return 1 ;;
        1) alvo="$base/${achados[0]}" ;;
        *) echo "Projetos com '$q':"
           local PS3="Número (outro valor cancela): "
           select n in "${achados[@]}"; do [[ -n "$n" ]] && alvo="$base/$n"; break; done
           [[ -z "$alvo" ]] && { echo "Cancelado"; return 1; } ;;
      esac
    fi
    cd "$alvo" || return 1
    echo "→ $alvo"
  fi
  if [[ -n "${CC_LAUNCHER:-}" ]]; then
    "$CC_LAUNCHER" "$@"
  elif [[ -x "$base/cc.sh" ]]; then
    "$base/cc.sh" "$@"
  elif [[ -x "$_CC_DIR/cc.sh" ]]; then
    "$_CC_DIR/cc.sh" "$@"
  else
    command claude "$@"
  fi
}
