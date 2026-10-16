#!/usr/bin/env bash
# Abre o Claude Code na pasta atual com as flags do INEMA. Argumentos extras passam adiante (ex.: cc.sh -c).
# ATENÇÃO: --dangerously-skip-permissions roda tudo sem pedir permissão — use só em máquina sua.
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=64000
claude --chrome --dangerously-skip-permissions --exclude-dynamic-system-prompt-sections "$@"
