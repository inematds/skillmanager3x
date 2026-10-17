# skillmanager3x

[![skillmanager3x — skills de sesión](guia/assets/banner-es.jpg)](https://inematds.github.io/skillmanager3x/guia/es/)

**🇧🇷 [Português](README.md) · 🇺🇸 [English](README.en.md) · 🇪🇸 [Español](README.es.md)**

## Qué es

skillmanager3x es un conjunto de skills (instrucciones listas en archivos de texto) para quienes usan Claude Code en sesiones largas. Resuelven el problema de perder el hilo cuando la conversación se llena: `session-handoff` guarda el estado en un archivo, limpias con `/clear` y `prime` retoma leyendo ese archivo. Además hay un checkpoint rápido, una auditoría de la memoria y una barra de estado. Para usarlas, basta copiar las carpetas a `~/.claude/skills`.

Biblioteca de **skills de gestión de sesión** para [Claude Code](https://claude.ai/code). Plantillas pequeñas y disjuntas que ayudan a mantener bajo control el contexto, la memoria y las transiciones entre sesiones.

## 📖 Guía de uso

Guía completa (landing + paso a paso): **https://inematds.github.io/skillmanager3x/guia/es/**

## ⭐ Cambio de sesión: handoff → `/clear` → `/prime`

Cuando el contexto se llena o la sesión ya se compactó, no insistas con la misma conversación:

1. **`/session-handoff`** registra lo que se hizo, lo que está en curso, la próxima acción exacta y lo que depende de ti en `handoffs/history/<UTC>.md` (nunca sobrescribe) y actualiza `handoffs/latest.md`.
2. **`/clear`** borra la conversación (en Codex, abre una sesión nueva). No se pierde nada: el estado está en el archivo.
3. **`/prime`** lee `CLAUDE.md`/`AGENTS.md`, `context/`, `tasks/current.md` y `handoffs/latest.md` y devuelve un briefing corto. Solo lee; no retoma despliegues, publicaciones ni envíos por su cuenta.

> **Existen dos `session-handoff`.** La versión antigua de este repositorio (y la que circula en otros kits) solo mostraba el resumen en el chat: al hacer `/clear` desaparecía y `/prime` no tenía qué leer. La versión actual, en `skill/pt` y `skill/en`, es la misma del kit [agente-claude-codex](https://github.com/inematds/agente-claude-codex) 1.5.2 y **graba en un archivo** mediante el script `scripts/handoff-grava.py` (sello con el reloj de la máquina, commit solo del handoff, sin push). Desde la 1.4.1, `handoffs/latest.md` es un **índice de trabajos abiertos por tema** + copia del más reciente, y `prime` lista todos los abiertos; es el mismo formato que lee el hook de Ejecución Larga. Para comprobar la tuya: `grep -c "handoffs/history" ~/.claude/skills/session-handoff/SKILL.md` (0 = versión solo chat). Desde la 1.5.2 el handoff trae un **bloque de estado grabado por el script** (commit + sha256 de los archivos; `handoff-grava.py --conferir` dice si el handoff quedó viejo), evidencia en cada `[confirmed]` y **5 preguntas de prueba** que `prime` responde con los archivos y puntúa (N/5).

Para trabajos de horas o días, mira la **[Ejecución Larga](https://inematds.github.io/execucao-longa/guia/es/)** ([repo](https://github.com/inematds/execucao-longa)): el hook que graba el handoff solo al ~70% y ~85% del contexto y después de compactar, los archivos de estado, el `/goal` y la investigación detrás de las franjas de contexto.

No hay build, dependencias ni código ejecutable: cada skill es una carpeta con un `SKILL.md` (markdown + frontmatter YAML) que Claude Code carga cuando el usuario dice uno de los disparadores.

## Estructura

```
skill/
├── en/                  versiones en inglés  (+ README detallado)
│   ├── session-handoff/SKILL.md  (+ scripts/handoff-grava.py)
│   ├── prime/SKILL.md
│   ├── session-statusline/SKILL.md
│   └── memory-audit/SKILL.md
└── pt/                  versiones en portugués (+ README detallado)
    ├── session-handoff/SKILL.md  (+ scripts/handoff-grava.py)
    ├── prime/SKILL.md
    ├── session-statusline/SKILL.md
    └── memory-audit/SKILL.md

statusline-cmd/          barra de estado del terminal (bash, opcional)
├── statusline-command.sh
├── install.sh
└── README.md
```

Los README de `skill/en/` y `skill/pt/` cubren decisiones de diseño, cambios respecto de versiones anteriores y consejos avanzados. Este README de la raíz es la puerta de entrada.

## Las skills

Cada una tiene **un solo trabajo** y disparadores que no se superponen. Usa la tabla de abajo para elegir:

| Skill | Cuándo usar | Disparadores típicos |
|---|---|---|
| `session-handoff` | fin de sesión, antes de `/clear` o de cambiar de agente | "handoff", "vou dar /clear", "encerrar sessão", "passar para outro agente", "wrap up", "resumo final antes de limpar" |
| `prime` | inicio de la sesión nueva, después del `/clear` | "prime", "retoma", "continua de onde parou", "lê o handoff" |
| `session-statusline` | checkpoint rápido **durante** el trabajo | "statusline", "checkpoint", "onde estamos", "como está a sessão", "próximos passos", "organiza/otimiza a sessão" |
| `memory-audit` | revisar lo que está/debería estar en memoria | "analise a memória", "analise CLAUDE.md", "o que foi guardado", "memória inchada", "limpa memória" |

Regla de bolsillo: **fin de sesión → handoff. Sesión nueva → prime. "¿Cómo vamos?" → statusline. "¿Qué hay en la memoria?" → audit.**

---

### 1. `session-handoff` — pasar la posta antes de limpiar el contexto

Produce un resumen estructurado de la sesión para que un agente futuro retome donde lo dejaste — conciso, con rutas, IDs de procesos en segundo plano, verificación real y marcadores de confianza (`[confirmed]`, `[unverified]`, `[?]`). Lo muestra en el chat **y lo graba** en `handoffs/history/<UTC>.md` + `handoffs/latest.md` cuando la raíz del proyecto tiene `handoffs/`, `AGENTS.md` o `CLAUDE.md`.

**Cuándo invocar:**
- Antes de `/clear`.
- Antes de cambiar de agente (p. ej.: pasar trabajo a un subagente en otra ventana).
- Cuando la conversación llega a >50 turnos y quieres reiniciar ligero.

**Ejemplo de uso:**

```
Usuario: voy a hacer /clear, haz el handoff antes
```

Claude lo muestra en el chat y lo graba en `handoffs/history/2026-10-13T014500Z.md` (y lo copia a `handoffs/latest.md`), con este formato:

```
# Handoff — 2026-10-13 — refactorización del middleware de auth

## Proyecto y alcance
~/projetos/api. Extraer la validación de JWT del middleware monolítico, manteniendo tokens v1.

## Estado aceptado
- [confirmed] auth/jwt_validator.py extraído de middleware.py:45-180

## Propuesto / intentado, no confirmado
- [unverified] caché de claves públicas con TTL de 5min — código listo, sin prueba
- [?] migración v1→v2 — el usuario quería revisarla antes de hacer merge

## Verificación
- Ejecutado: `pytest tests/auth/ -v` → 12 passed
- No ejecutado: prueba de carga — sin entorno

## Estado en ejecución
- Procesos en segundo plano: shell_a3f → pytest --watch (kill: KillShell shell_a3f)

## Próxima acción exacta
Revisar con el usuario si la migración v1→v2 entra ahora (necesita su ok).

## Mapa de retoma
- `auth/jwt_validator.py` — núcleo de la extracción

## Chequeo de compartición
- Sin secretos, tokens ni datos personales: sí
```

**En la sesión nueva**, después del `/clear`, ejecuta `/prime`: lee `handoffs/latest.md` (y `CLAUDE.md`/`AGENTS.md`, `context/`, `tasks/current.md`) y devuelve objetivo, regla principal con fuente, última decisión, próxima acción y conflictos.

---

### 2. `session-statusline` — checkpoint rápido durante el trabajo

Snapshot operativo corto: foco actual, contexto, decisiones recientes, candidatos a memoria y cuál es el próximo movimiento (continuar, compactar, auditar, hacer handoff o limpiar). Úsalo cuando quieras ver el estado sin terminar la sesión.

**Cuándo invocar:**
- La sesión empezó a sentirse ruidosa y quieres un norte.
- Terminó una fase del trabajo y quieres decidir si continúas o cambias de táctica.
- Quieres saber qué guardó Claude en la memoria **en esta sesión**.

**Ejemplo de uso:**

```
Usuario: statusline
```

Claude responde:

```
# Statusline

## Estado
- Foco actual: ajustar la paginación del endpoint /users
- Contexto: moderado
- Riesgo principal: aún no hicimos prueba de carga con >10k registros

## Lo que quedó guardado en la memoria
- Guardado confirmado: none
- Candidatos para memoria: el usuario prefiere keyset pagination sobre offset (decisión de esta sesión)
- No guardar: greps fallidos al inicio, intento descartado con cursor base64

## Historial corto
- Hecho ahora: implementado keyset en users_repo.py, ajustado el schema de la respuesta
- Decisiones recientes: descartado offset por inestabilidad con inserts concurrentes
- Archivos relevantes: /api/users.py, /repo/users_repo.py

## Próximos pasos
1. Correr prueba con 50k registros y medir latencia
2. Actualizar el schema OpenAPI
3. Decidir si vale guardar en memoria la preferencia por keyset

## Recomendación
continuar
```

La línea **Recomendación** al final te dice qué skill (o ninguna) tiene sentido a continuación.

---

### 3. `memory-audit` — revisar lo que está en memoria

Auditoría de lo que está (o debería estar) en `~/.claude/projects/<proyecto>/memory/` y en el `CLAUDE.md` del proyecto. Distingue **hecho duradero** (se mantiene), **estado de corto plazo** (se descarta) y **ruido** (se elimina).

**Cuándo invocar:**
- La memoria parece inflada o contradictoria.
- Vas a empezar un proyecto nuevo y quieres depurar antes.
- Terminó una sesión grande y quieres revisar lo que quedó registrado.

**Ejemplo de uso:**

```
Usuario: audita la memoria del proyecto, está desordenada
```

Claude responde con un inventario como:

```
# Memory Audit

## Mantener (hechos duraderos)
- user_role.md → el usuario es ing. backend Go, nuevo en React
- feedback_testing.md → las pruebas de integración deben pegarle al Postgres real (incidente Q3/2025)

## Considerar mover a CLAUDE.md
- project_auth_rewrite.md → contexto de motivación (compliance) — vale en la documentación del proyecto

## Eliminar (corto plazo / ruido)
- session_2026-04-15.md → estado de sesión antigua, irrelevante
- bug_fix_recipe_xyz.md → fix ya aplicado, el código habla por sí solo

## Puntos de atención
- Duplicación: feedback_pr_size.md y feedback_review_style.md cubren un tema parecido
- Obsoleto: reference_grafana.md apunta a un dashboard que cambió de URL
```

La salida es **recomendación, no ejecución**. Si quieres que Claude aplique los recortes, pídelo en un segundo paso: "ok, aplica eso".

---

## Instalación

Para que Claude Code reconozca las skills, copia la carpeta de cada skill a una de las carpetas que el harness recorre:

- **Global (todas las sesiones):** `~/.claude/skills/<skill>/`
- **Por proyecto:** `<proyecto>/.claude/skills/<skill>/`

Ejemplo (instalación global de las skills en portugués):

```bash
mkdir -p ~/.claude/skills
cp -r skill/pt/session-handoff   ~/.claude/skills/
cp -r skill/pt/prime             ~/.claude/skills/
cp -r skill/pt/session-statusline ~/.claude/skills/
cp -r skill/pt/memory-audit       ~/.claude/skills/
```

> Cada carpeta va completa, con el `SKILL.md` dentro — no la aplanes.

Para verificar que se registró, usa `/skills` en Claude Code.

> No hay versión de las skills en español: usa `skill/pt` o `skill/en` (los disparadores en portugués funcionan en ambas).

## Bonus: `statusline-cmd` — la barra de estado del terminal

Además de las skills, el repo trae una **statusline** para Claude Code: la línea fija que aparece debajo del input, mostrando dónde estás, con qué modelo, cuánto contexto queda y cuánto de tu límite ya se usó.

```
nmaldaner@spark-922b:~/projetos/wifi Opus 5/low ctx 10% 5h:24%→00:10 w:29%→10/08 21:00 d:109.6M
```

| Campo | Significado |
|---|---|
| `user@host:cwd` | usuario, máquina y directorio actual |
| `Opus 5/low` | modelo y nivel de esfuerzo de la sesión (acompaña el `/model`) |
| `ctx 10%` | cuánto de la ventana de contexto ya se usó |
| `5h:24%→00:10` | límite de 5 horas usado y hora del reinicio |
| `w:29%→10/08 21:00` | límite semanal usado y reinicio |
| `d:109.6M` | tokens sumados hoy, en todas las sesiones locales |

**El comando:**

```bash
git clone https://github.com/inematds/skillmanager3x
bash skillmanager3x/statusline-cmd/install.sh
```

El instalador copia el script a `~/.claude/statusline-command.sh`, registra el bloque `statusLine` en `~/.claude/settings.json` **preservando el resto del archivo** (con respaldo `.bak`) y muestra una vista previa. La barra aparece en el próximo render — no hace falta reiniciar la sesión.

Quitar: `bash statusline-cmd/install.sh --uninstall`.

Requisitos: `jq`, `curl`, `python3` y el `date` de GNU. Los límites 5h/semanal vienen del endpoint `api/oauth/usage` usando **tus propias credenciales** (`~/.claude/.credentials.json`) — ningún token va en el repo. Detalles y personalización en [`statusline-cmd/README.md`](statusline-cmd/README.md) (en portugués).

> La skill `session-statusline` y la carpeta `statusline-cmd` tienen nombres parecidos y propósitos distintos: la skill escribe un **checkpoint en texto** cuando lo pides; la carpeta instala la **barra fija** del terminal.

## Convención en/pt

`skill/en/` y `skill/pt/` tienen la misma estructura. El `name` es igual en ambas; la `description` **incluye disparadores en portugués** cuando corresponde (`"vou dar /clear"`, `"encerrar sessão"`, `"retoma"`, etc.). `session-handoff` y `prime` en `skill/pt/` son copia exacta de las versiones del kit [agente-claude-codex](https://github.com/inematds/agente-claude-codex) 1.5.2; las de `skill/en/` son la traducción fiel.

Al editar una skill, sincroniza las dos versiones.
