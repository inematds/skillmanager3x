#!/usr/bin/env bash
# Abre o Codex CLI na pasta atual sem pedir aprovação e sem sandbox. Argumentos extras passam adiante.
# ATENÇÃO: --dangerously-bypass-approvals-and-sandbox roda tudo sem pedir — use só em máquina sua.
codex --dangerously-bypass-approvals-and-sandbox "$@"
