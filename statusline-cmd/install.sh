#!/usr/bin/env bash
# Instala a statusline INEMA no Claude Code do usuário atual.
#
# Uso:
#   bash install.sh              # instala/atualiza
#   bash install.sh --uninstall  # remove a entrada statusLine do settings.json
#
# Requisitos: jq, curl, python3, date do GNU (coreutils).
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$HOME/.claude/statusline-command.sh"
SETTINGS="$HOME/.claude/settings.json"

if [[ "${1:-}" == "--uninstall" ]]; then
  python3 - "$SETTINGS" <<'PY'
import json, sys, pathlib
p = pathlib.Path(sys.argv[1])
if p.exists():
    d = json.loads(p.read_text() or "{}")
    d.pop("statusLine", None)
    p.write_text(json.dumps(d, indent=2) + "\n")
    print("statusLine removida de", p)
PY
  exit 0
fi

# Dependências
missing=()
for bin in jq curl python3; do command -v "$bin" >/dev/null || missing+=("$bin"); done
if ((${#missing[@]})); then
  echo "Faltam dependências: ${missing[*]}" >&2
  echo "Ubuntu/Debian: sudo apt install ${missing[*]}" >&2
  exit 1
fi

mkdir -p "$HOME/.claude"
install -m 0755 "$SRC_DIR/statusline-command.sh" "$DEST"

# Registra no settings.json preservando o resto do arquivo (backup .bak)
python3 - "$SETTINGS" <<'PY'
import json, pathlib, shutil, sys
p = pathlib.Path(sys.argv[1])
d = {}
if p.exists():
    shutil.copy(p, str(p) + ".bak")
    d = json.loads(p.read_text() or "{}")
d["statusLine"] = {"type": "command", "command": "bash ~/.claude/statusline-command.sh"}
p.write_text(json.dumps(d, indent=2) + "\n")
print("statusLine registrada em", p)
PY

echo
echo "Prévia:"
echo '{"cwd":"'"$PWD"'","effort":{"level":"low"},"model":{"display_name":"Opus 5"}}' | bash "$DEST"
echo
echo
echo "Pronto. Aparece no próximo render do Claude Code (ou reinicie a sessão)."
