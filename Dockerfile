# syntax=docker/dockerfile:1.6
FROM --platform=linux/amd64 ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ARG WINEHQ_BRANCH=stable

ENV WINEPREFIX=/wine \
    WINEARCH=win32 \
    WINEDEBUG=-all \
    DISPLAY=:99 \
    LANG=C.UTF-8

# Install Wine from WineHQ + Xvfb for headless GUI launcher
RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
        ca-certificates \
        wget \
        gnupg \
        cabextract \
        xvfb \
        xauth \
        winbind \
        procps \
        tini \
 && install -dm 755 /etc/apt/keyrings \
 && wget -qO /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key \
 && wget -qNP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/winehq-jammy.sources \
 && apt-get update \
 && apt-get install -y --install-recommends "winehq-${WINEHQ_BRANCH}" \
 && rm -rf /var/lib/apt/lists/*

# Initialize a clean 32-bit Wine prefix in a virtual X session.
# WINEDLLOVERRIDES disables Mono/Gecko so wineboot does not hang waiting on
# their installer dialogs / network downloads (FC2 server doesn't need them).
RUN WINEDLLOVERRIDES="mscoree,mshtml=" xvfb-run -a -e /dev/stderr wineboot --init \
 && wineserver -w \
 && rm -f /tmp/.X*-lock /tmp/.X11-unix/X*

# Game files are NOT copied into the image — mount the host data/ directory at /data:
#   /data/farcry2  — game contents (former fc2/)
#   /data/config   — exposed to the game as "Documents\My Games\Far Cry 2\Server"
#                    so dedicated_server.cfg is picked up from its default location
#   /data/user_maps — exposed to the game as "Documents\My Games\Far Cry 2\user maps"
RUN mkdir -p /data \
 && mkdir -p "/wine/drive_c/users/root/Documents/My Games/Far Cry 2" \
 && ln -sfn /data/config    "/wine/drive_c/users/root/Documents/My Games/Far Cry 2/Server" \
 && ln -sfn /data/user_maps "/wine/drive_c/users/root/Documents/My Games/Far Cry 2/user maps"

# Game (TCP/UDP 9000-9003) and STUN (UDP 3074-3080) ports
EXPOSE 9000-9003/tcp
EXPOSE 9000-9003/udp
EXPOSE 3074-3080/udp

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /data/farcry2/bin

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["FC2ServerLauncher.exe", "-noredirectstdin"]
