<!-- // © https://saadbinyousaf.dev/ © // -->
# Development

Droidesk has no build step. It's Windows PowerShell 5.1 (built into every Windows 10 and 11) and a single HTML file, so you can edit a file and reopen the app to see the change.

## How it fits together

```
Droidesk.bat ──> conhost --headless ──> powershell core\server.ps1
                                          │
                       ┌──────────────────┼────────────────────┐
                       │                  │                    │
               HttpListener on      WebView2 window      tasks.ps1 (hidden)
               localhost:<random>   loads core\app\      create / root /
               JSON API + token     index.html           setup / update
                       │                                       │
                       └──────── data\.ui\task.json, task.log ─┘
```

| File | Role |
| --- | --- |
| `Droidesk.bat` | Starts the engine through a headless console host, so Windows Terminal never opens a window. |
| `core/server.ps1` | The engine. Serves the UI and a JSON API on a random `localhost` port, hosts the window (WinForms + WebView2, with an Edge `--app` fallback), reads device state, starts and stops emulators, and launches tasks. On every start it also repairs device paths, environment variables and the desktop shortcut, and checks hardware acceleration. |
| `core/tasks.ps1` | Long jobs: `Setup`, `Create`, `Root` and `Update`. Runs with no window, writes progress to `data\.ui\task.json` and the log to `data\.ui\task.log`. A watchdog stops any step that makes no progress. |
| `core/app/index.html` | The whole interface: HTML, CSS and JavaScript in one file, with no framework. It polls `/api/state` and redraws only what changed. |

## API

Every request to `/api/*` must carry the `X-Vault` header with the token from the window URL's hash. Bodies are JSON.

| Method | Path | Body or query | Does |
| --- | --- | --- | --- |
| GET | `/api/state` | | Devices, current task, setup state, version |
| POST | `/api/start` | `{ name, cold }` | Starts a device |
| POST | `/api/stop` | `{ name }` | Stops a device |
| POST | `/api/delete` | `{ name }` | Deletes a stopped device |
| POST | `/api/folder` | `{ name }` | Opens the device folder |
| GET | `/api/versions` | `?refresh=1` | System images known and installed |
| GET | `/api/devices` | | Device definitions |
| GET | `/api/magisk` | `?refresh=1` | Magisk builds from GitHub |
| POST | `/api/create` | `{ name, key, tag, device, ram, storage, root, url, version }` | Starts the Create task |
| POST | `/api/root` | `{ name, url, version }` | Starts the Root task |
| POST | `/api/setup` | | Starts the Setup task |
| POST | `/api/update` | | Starts the Update task |
| POST | `/api/cancel` `/api/retry` `/api/dismiss` | | Controls the current task |

## Running from source

```powershell
git clone https://github.com/saadbinyousaf1/Droidesk.git D:\Droidesk
D:\Droidesk\Droidesk.bat
```

The first run goes through setup like a release does. To test a change, close Droidesk and open it again. The app window turns off browser shortcuts such as reload and DevTools. While working on the UI, you can open the same page in a normal browser: the address is in `data\.ui\server.json`, as `http://localhost:<port>/#<token>`.

## Conventions

- PowerShell code must run on Windows PowerShell 5.1. Don't use PowerShell 7-only syntax such as `??`, `?.` or ternaries.
- Save `.ps1` files as UTF-8 **with BOM** and CRLF line endings. `.gitattributes` handles the line endings.
- Start child processes with `CreateNoWindow` so nothing pops up a console.
- Put the signature line `// © https://saadbinyousaf.dev/ © //` above each section of a script (`# // © https://saadbinyousaf.dev/ © //` in PowerShell).
- Keep the UI copy plain and specific: say what happens and what to do next.

## Releasing

1. Add the release notes to `docs/changes.md` and bump `$AppVersion` in `core/server.ps1`.
2. Commit, then tag and push:

```bash
git tag v1.0.0
git push origin v1.0.0
```

The **Release** workflow packages `Droidesk.bat`, `core`, `README.md` and `LICENSE` into `Droidesk-v1.0.0.zip` and publishes a GitHub release with that version's notes.
