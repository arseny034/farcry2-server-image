# Far Cry 2 Dedicated Server in Docker

Run the Far Cry 2 multiplayer dedicated server (`FC2ServerLauncher.exe`) on Linux
inside a container, using Wine. The image ships only Wine + Xvfb; the game files
live on the host and are mounted into the container at runtime.

## Requirements

- Docker / Docker Compose v2
- A copy of the **Steam version** of Far Cry 2 with the community
  **multiplayer patch** installed from
  [fc2mp.com](https://www.fc2mp.com/Multiplayer-patch/).
- An `x86_64` Linux host.

## Data volume

The container expects a single volume mounted at **`/data`** with the
following layout:

```
/data
├── config/
│   └── dedicated_server.cfg     # exposed to the game as
│                                # Documents\My Games\Far Cry 2\Server\dedicated_server.cfg
├── farcry2/                     # game contents
│   ├── bin/
│   │   ├── FC2ServerLauncher.exe
│   │   └── ...
│   ├── Data_Win32/
│   └── ...
└── user_maps/                   # exposed to the game as
                                 # Documents\My Games\Far Cry 2\user maps
```

How you provide that volume is up to you — a host bind mount, a named Docker
volume, a managed volume on a container platform, etc. The bundled
`docker-compose.yml` is just one convenient option: it bind-mounts `./data`
from the repo root into `/data`, so you can drop the directories above next to
the `Dockerfile` and run `docker compose up`. Any other arrangement is fine
as long as the `/data` tree inside the container ends up matching the layout
above.

## Configuration

The launcher reads its config from
`Documents\My Games\Far Cry 2\Server\dedicated_server.cfg` (its default
Windows location). Inside the container that path is a symlink to
`/data/config/`, so editing `dedicated_server.cfg` in your mounted volume is
all that's needed — no launcher arguments required.

## Ports

Published in `docker-compose.yml`:

| Port range  | Proto    | Purpose          |
|-------------|----------|------------------|
| 9000–9003   | TCP/UDP  | Game traffic     |
| 3074–3080   | UDP      | STUN services    |

If your host is behind NAT, forward these ranges on the router as well.
