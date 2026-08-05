#!/bin/bash
# Statusline: user@host:cwd · ctx N% · 5h:X% · w:Y% · d:TOK
#
# 5h% e w% vêm do endpoint oficial do Claude Code:
#   GET https://api.anthropic.com/api/oauth/usage
#   header: Authorization: Bearer <accessToken de ~/.claude/.credentials.json>
#   header: anthropic-beta: oauth-2025-04-20
# Resposta:
#   { "five_hour":{"utilization":20.0,"resets_at":"..."},
#     "seven_day":{"utilization":83.0,"resets_at":"..."}, ... }
# Cache 300s em /tmp/cc_limits_<uid>.json pra não martelar a API a cada tecla
# (TTL elevado de 60s → 300s em 2026-05-13 após 429 rate_limit_error com 4
# sessões Claude simultâneas batendo na API a cada minuto).
#
# d:TOK continua sendo a contagem local (JSONL) — útil pra ver volume absoluto
# do dia; a API não retorna bucket "hoje".

set -u
input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd // ""' 2>/dev/null)
transcript=$(echo "$input" | jq -r '.transcript_path // ""' 2>/dev/null)

# ── Context % (última usage do transcript / context window do modelo ativo) ─
# Opus 4.x → 1M. Sonnet/Haiku → 200k (1M se beta ativo). Detecta o modelo via
# .model.id no input do Claude Code; fallback olha a última message no transcript.
# Heurística do beta 1M: se tok já passou 200k num Sonnet/Haiku, só é possível
# se a sessão estiver com context-1m-2025-08-07, então assume 1M.
ctx=""
model_id=$(echo "$input" | jq -r '.model.id // .model.display_name // empty' 2>/dev/null | tr '[:upper:]' '[:lower:]')
if [[ -n "$transcript" && -f "$transcript" ]]; then
  tok=$(tac "$transcript" 2>/dev/null | grep -m1 '"usage"' | \
        jq -r 'try ((.message.usage.input_tokens // 0) + (.message.usage.cache_read_input_tokens // 0) + (.message.usage.cache_creation_input_tokens // 0)) catch 0' 2>/dev/null)
  # fallback do modelo: última message do transcript
  if [[ -z "$model_id" ]]; then
    model_id=$(tac "$transcript" 2>/dev/null | grep -m1 '"model"' | \
               jq -r 'try .message.model catch empty' 2>/dev/null | tr '[:upper:]' '[:lower:]')
  fi
  if [[ -n "$tok" && "$tok" != "0" && "$tok" != "null" ]]; then
    if [[ "$model_id" == *opus* ]]; then
      ctx_window=1000000
    elif (( tok > 200000 )); then
      ctx_window=1000000   # heurística: passou 200k → beta 1M ativo
    else
      ctx_window=200000
    fi
    pct=$(( tok * 100 / ctx_window ))
    ctx=" ctx ${pct}%"
  fi
fi

# ── 5h% + w% via API (cache 300s) ────────────────────────────────────────
LIMITS_CACHE="/tmp/cc_limits_${UID}.json"
refresh_api=1
if [[ -f "$LIMITS_CACHE" ]]; then
  age=$(( $(date +%s) - $(stat -c %Y "$LIMITS_CACHE" 2>/dev/null || echo 0) ))
  [[ $age -lt 300 ]] && refresh_api=0
fi

if [[ $refresh_api -eq 1 ]]; then
  # Refetch em background pra não bloquear render
  (
    TOKEN=$(jq -r '.claudeAiOauth.accessToken // empty' ~/.claude/.credentials.json 2>/dev/null)
    if [[ -n "$TOKEN" ]]; then
      tmp=$(mktemp)
      code=$(curl -s --max-time 4 \
        -H "Authorization: Bearer $TOKEN" \
        -H "anthropic-beta: oauth-2025-04-20" \
        -w "%{http_code}" -o "$tmp" \
        https://api.anthropic.com/api/oauth/usage 2>/dev/null)
      if [[ "$code" == "200" ]] && [[ -s "$tmp" ]]; then
        mv "$tmp" "$LIMITS_CACHE"
      else
        rm -f "$tmp"
      fi
    fi
  ) &
  disown
fi

h5_pct=""; h5_reset=""; w_pct=""; w_reset=""
if [[ -f "$LIMITS_CACHE" ]]; then
  h5_pct=$(jq -r 'try (.five_hour.utilization | round | tostring) catch empty' "$LIMITS_CACHE" 2>/dev/null)
  w_pct=$(jq -r  'try (.seven_day.utilization | round | tostring) catch empty' "$LIMITS_CACHE" 2>/dev/null)
  h5_iso=$(jq -r 'try .five_hour.resets_at catch empty' "$LIMITS_CACHE" 2>/dev/null)
  w_iso=$(jq -r  'try .seven_day.resets_at catch empty' "$LIMITS_CACHE" 2>/dev/null)
  # 5h reset: só hora local (HH:MM) — reset dentro de ≤5h
  [[ -n "$h5_iso" ]] && h5_reset=$(date -d "$h5_iso" +%H:%M 2>/dev/null)
  # weekly reset: dia/mês hora local (dd/mm HH:MM)
  [[ -n "$w_iso"  ]] && w_reset=$(date -d "$w_iso"  +"%d/%m %H:%M" 2>/dev/null)
fi

# ── Daily tokens (JSONL local, cache 60s) ────────────────────────────────
CACHE="/tmp/cc_usage_${UID}.txt"
refresh=1
if [[ -f "$CACHE" ]]; then
  age=$(( $(date +%s) - $(stat -c %Y "$CACHE" 2>/dev/null || echo 0) ))
  [[ $age -lt 60 ]] && refresh=0
fi
if [[ $refresh -eq 1 ]]; then
  T=$(date +%Y-%m-%d)
  (
    tmp=$(mktemp)
    find "$HOME/.claude/projects" -name "*.jsonl" -mtime -2 -print0 2>/dev/null | \
      xargs -0 cat 2>/dev/null | \
      jq -R 'fromjson? | select(.timestamp) | {day: .timestamp[0:10], u: (.message.usage // {})}' | \
      jq -s --arg t "$T" -r '
        def sum: map((.u.input_tokens // 0) + (.u.output_tokens // 0) + (.u.cache_creation_input_tokens // 0)) | add // 0;
        "\([.[] | select(.day == $t)] | sum)"
      ' > "$tmp" 2>/dev/null
    [[ -s "$tmp" ]] && mv "$tmp" "$CACHE" || rm -f "$tmp"
  ) &
  disown
fi
d=0
[[ -f "$CACHE" ]] && read -r d < "$CACHE"

fmt() {
  local n=${1:-0}
  if (( n >= 1000000 )); then awk -v x="$n" 'BEGIN{printf "%.1fM", x/1000000}'
  elif (( n >= 1000 )); then awk -v x="$n" 'BEGIN{printf "%.0fk", x/1000}'
  else echo "$n"
  fi
}

# ── Modelo + esforço ──────────────────────────────────────────────────────
# Preferência: payload da statusline (reflete o /model da sessão). Fallback:
# settings.json (model + effortLevel), que é o default quando a sessão não
# sobrescreveu nada.
model_name=$(echo "$input" | jq -r '.model.display_name // empty' 2>/dev/null)
effort=$(echo "$input" | jq -r '
  [.effort.level?, .model.effort?, .model.effortLevel?, .effortLevel?, .reasoning_effort?]
  | map(select(. != null and . != "")) | first // empty' 2>/dev/null)
if [[ -z "$model_name" || -z "$effort" ]]; then
  s="$HOME/.claude/settings.json"
  [[ -z "$model_name" ]] && model_name=$(jq -r '.model // empty' "$s" 2>/dev/null)
  [[ -z "$effort"     ]] && effort=$(jq -r '.effortLevel // empty' "$s" 2>/dev/null)
fi
me=""
[[ -n "$model_name" ]] && me=" ${model_name}"
[[ -n "$effort"     ]] && me+="/${effort}"

# Monta trinca de limits. Se API ainda não populou cache, omite graciosamente.
limits=""
if [[ -n "$h5_pct" ]]; then
  limits+=" 5h:${h5_pct}%"
  [[ -n "$h5_reset" ]] && limits+="→${h5_reset}"
fi
if [[ -n "$w_pct" ]]; then
  limits+=" w:${w_pct}%"
  [[ -n "$w_reset" ]] && limits+="→${w_reset}"
fi
limits+=" d:$(fmt "$d")"

printf "\033[01;32m%s@%s\033[00m:\033[01;34m%s\033[00m\033[38;5;180m%s\033[00m%s\033[38;5;244m%s\033[00m" \
  "$(whoami)" "$(hostname -s)" "$cwd" "$me" "$ctx" "$limits"
