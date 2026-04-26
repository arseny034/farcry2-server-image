# Far Cry 2 Dedicated Server in Docker

Run the Far Cry 2 multiplayer dedicated server (`FC2ServerLauncher.exe`) on Linux
inside a container, using Wine. The image ships only Wine + Xvfb; the game files
live on the host and are mounted into the container at runtime.

![Docker Image Version](https://img.shields.io/docker/v/arseny034/farcry2-server)
![Docker Image Size](https://img.shields.io/docker/image-size/arseny034/farcry2-server)

```shell
docker pull arseny034/farcry2-server:latest
```

## Requirements

- Docker or a compatible container runtime.
- A copy of the Steam version of Far Cry 2 with the community
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

## Ports

The following ports should be published from the container:

| Port range  | Proto    | Purpose          |
|-------------|----------|------------------|
| 9000–9003   | TCP/UDP  | Game traffic     |
| 3074–3080   | UDP      | STUN services    |

If your host is behind NAT, forward these ranges on the router as well.
