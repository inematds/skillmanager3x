@echo off
rem Abre o Codex CLI na pasta atual sem pedir aprovacao e sem sandbox. Argumentos extras passam adiante.
rem ATENCAO: --dangerously-bypass-approvals-and-sandbox roda tudo sem pedir - use so em maquina sua.
codex --dangerously-bypass-approvals-and-sandbox %*
