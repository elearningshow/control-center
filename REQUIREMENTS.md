# Control Center — Requirements

Local-first business dashboard from
https://github.com/mreflow/control-center

This file lists what you need to install and run Control Center on Windows
with the included `setup.bat`. The official app does **not** ship its own
REQUIREMENTS.md; npm packages are locked in `package-lock.json`.

---

## 1. Required

| Item | Version / detail | Why |
|---|---|---|
| Windows | 10 22H2 or Windows 11 | `setup.bat`, portable Node, Ollama |
| Node.js | **24.19.0 or newer** | Official engine. `setup.bat` installs portable **24.20.0 LTS** if needed |
| npm | Comes with Node (project pins npm 11.x) | Installs app packages from `package-lock.json` |
| Modern desktop browser | Chrome, Edge, Firefox, Brave | UI is `http://127.0.0.1:3000` |
| Disk (app only) | ~500 MB | Repo + `node_modules` + Next.js build |
| RAM (app only) | 4 GB free | Dashboard, collectors, SQLite |

Git is optional. If Git is installed, `setup.bat` clones the repo. If not, it downloads the GitHub ZIP instead.

Admin rights are **not** required. Portable Node lands in:

`%LOCALAPPDATA%\ControlCenter-Runtime\node`

---

## 2. Network and ports

| Port | Bind | Used by |
|---|---|---|
| **3000** | `127.0.0.1` only | Control Center |
| **11434** | `127.0.0.1` only | Ollama local AI |

The app rejects non-loopback Host/Origin headers. Do not expose it on your LAN without your own auth proxy.

First run needs internet for:

- GitHub clone or ZIP
- `npm ci` (locked dependencies)
- Optional Node / Ollama / model downloads

After that, the dashboard itself is local-first. Collectors still need internet to fetch public news, sites, and audience pages.

---

## 3. Application packages (installed by `npm run launch`)

From the official `package.json` (v0.3.1). You do not install these by hand.

**Runtime**

- next
- react
- react-dom
- lucide-react
- fast-xml-parser

**Dev / build**

- typescript
- tsx
- eslint
- eslint-config-next
- @types/node
- @types/react
- @types/react-dom

`npm run launch` runs `npm ci` against `package-lock.json` when needed, then builds and starts the server.

---

## 4. Optional — local AI (Ollama)

No cloud key is required. Newsletter intelligence **does** need some model, local or cloud.

| Item | Detail |
|---|---|
| Ollama | Windows app from https://ollama.com/download/windows or `winget install Ollama.Ollama` |
| API | `http://127.0.0.1:11434` (Control Center accepts loopback only) |
| Loaded model | Control Center lists **currently loaded** text models, not every model on disk |

`setup.bat` picks a recommended model from RAM:

| Installed RAM | Model | Download | Role |
|---|---|---|---|
| Under ~10 GB | `gemma3:4b` | ~3.3 GB | Fits smaller laptops |
| Typical PC (default) | `qwen2.5:7b` | ~4.7 GB | Summaries, ranking, newsletters |
| ~20 GB or more | `qwen2.5:14b` | ~9 GB | Higher quality, same tasks |

Override with:

```bat
setup.bat /model=qwen2.5:7b
setup.bat /skip-ollama
```

Keep the Ollama tray app running while the dashboard is open. After a reboot, start Ollama first or run `start.bat` (it will try to start `ollama serve`).

In the app: **Settings → AI curation → Ollama · local → Reload models**.

---

## 5. Optional — cloud AI keys

Only needed if you do not use Ollama / LM Studio. Keys can go in Settings or in `.env.local`:

```
OPENAI_API_KEY=
ANTHROPIC_API_KEY=
GEMINI_API_KEY=
XAI_API_KEY=
```

A key does nothing until that provider is selected in Settings. Local Ollama does not use `OLLAMA_API_KEY` (that name is reserved for Ollama Cloud).

LM Studio alternative endpoint: `http://127.0.0.1:1234`.

---

## 6. Optional — Gmail newsletters

- Google Cloud project
- Gmail API enabled
- OAuth client ID + secret (read-only)
- Any Gmail account

Configured later under **Settings → Newsletters**. Not installed by `setup.bat`.

---

## 7. Folders created by setup

| Path | Contents |
|---|---|
| `F:\AI\apps\mattwolfe\control-center` | App source (or whatever folder you chose) |
| `%LOCALAPPDATA%\Control Center` | `settings.json`, SQLite, snapshots |
| `%LOCALAPPDATA%\ControlCenter-Runtime\node` | Portable Node 24.20 if winget was unavailable |
| `control-center\.env.local` | Copied from `.env.example` on first run |
| `control-center\start.bat` | Later launches |

Optional override in `.env.local`:

```
CONTROL_CENTER_DATA_DIR=
```

Must be an absolute path if set.

---

## 8. What `setup.bat` does automatically

1. Finds or installs Node.js 24.19+
2. `git clone` (or ZIP) of `mreflow/control-center`
3. Creates the data folder and `.env.local`
4. Installs Ollama, pulls the recommended model, keeps it loaded
5. Points Settings at Ollama
6. Runs `npm run launch` (install + build + server + browser)

Useful commands after install, from the project folder:

```bat
npm run launch
npm run launch -- --no-open
npm run launch -- --port=3001
npm run doctor
npm run backup
```

---

## 9. Quick check that it is running

- Command Prompt window titled **Control Center** is still open
- Browser opens `http://127.0.0.1:3000`
- Optional: `http://127.0.0.1:11434/api/tags` returns JSON if Ollama is up

If the Command Prompt closes, the dashboard stops. Use `start.bat` to bring it back.
