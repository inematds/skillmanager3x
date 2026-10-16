@echo off
rem Abre o Claude Code na pasta atual com as flags do INEMA. Argumentos extras passam adiante (ex.: cc -c).
rem ATENCAO: --dangerously-skip-permissions roda tudo sem pedir permissao - use so em maquina sua.
set CLAUDE_CODE_MAX_OUTPUT_TOKENS=64000
claude --chrome --dangerously-skip-permissions --exclude-dynamic-system-prompt-sections %*
