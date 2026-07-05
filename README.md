# Astroneer Dedicated Server (LXC)

Native [LXC](https://linuxcontainers.org/) deployment for the Astroneer Dedicated Server on Linux, ported from the excellent Docker packaging in [birdhimself/astroneer-docker](https://github.com/birdhimself/astroneer-docker).

This project runs [AstroTuxLauncher](https://github.com/birdhimself/AstroTuxLauncher) with Wine (and Box64 on ARM64) directly on a Debian-based system or Proxmox LXC container — no Docker required.

## Attribution

This LXC port is based on:

- **[birdhimself/astroneer-docker](https://github.com/birdhimself/astroneer-docker)** — Docker image, entrypoint logic, and operational documentation
- **[birdhimself/container-base-images](https://github.com/birdhimself/container-base-images)** — Wine 10.x base image definition
- **[birdhimself/AstroTuxLauncher](https://github.com/birdhimself/AstroTuxLauncher)** — Server launcher and management utility

If you use Docker instead, prefer the upstream project: [ghcr.io/birdhimself/astroneer-server](https://github.com/birdhimself/astroneer-docker/pkgs/container/astroneer-server).

## Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| OS | Debian 12+ or Ubuntu 22.04+ | Debian Trixie (matches upstream Wine builds) |
| Architecture | amd64 or arm64 | amd64 |
| RAM | 2 GB | 4 GB+ |
| Disk | 10 GB | 20 GB+ |
| Network | UDP 7777 reachable | Public IP or tunnel (e.g. playit.gg) |

**Proxmox:** Set the CT CPU type to `host` or `x86-64-v3`. The default `kvm64` profile omits instruction sets Wine/Unreal may need.

## Quick start (Proxmox LXC)

1. Create an **unprivileged** Debian 12/13 CT (2–4 cores, 4 GB RAM).
2. Copy this repository into the container (or clone after pushing to GitHub).
3. Run the provisioning script as root:

   ```bash
   sudo ./scripts/provision.sh
   ```

4. Bind-mount your save directory (Proxmox CT config example):

   ```
   mp0: /path/on/host/saved,mp=/opt/astroneer/AstroneerServer/Astro/Saved
   ```

5. Enable and start the service:

   ```bash
   sudo systemctl enable --now astroneer
   ```

6. Open UDP port 7777 on your firewall / Proxmox host.

### Console access

View live server output:

```bash
journalctl -u astroneer -f
```

For an interactive launcher console (optional), run the entrypoint manually inside tmux:

```bash
sudo -u astroneer tmux new-session -s astroneer /usr/local/bin/astroneer-entrypoint
sudo -u astroneer tmux attach -t astroneer
```

Stop the systemd service before using manual tmux, or pick one mode at a time.

## Configuration

Environment variables are read from `/etc/astroneer/astroneer.env` (created by `provision.sh`).

| Variable | Description | Default |
|----------|-------------|---------|
| `DEBUG` | Enable debug logging | `false` |
| `DISABLE_ENCRYPTION` | Disable connection encryption | `false` |
| `CREATE_LAUNCHER_CONFIG` | Regenerate `launcher.toml` on each start | `true` |
| `FORCE_CHOWN` | `chown` the install tree on startup | `false` |
| `ASTRONEER_HOME` | Install root | `/opt/astroneer` |

Server settings live in `AstroServerSettings.ini` under your mounted save path:

```
<Saved>/Config/WindowsServer/AstroServerSettings.ini
```

Stop the service before editing config files the server writes on shutdown:

```bash
sudo systemctl stop astroneer
```

See the [upstream Docker README](https://github.com/birdhimself/astroneer-docker#configuration) for encryption, admin setup, and client configuration details.

## Project layout

```
astroneer-lxc/
├── README.md
├── LICENSE
├── scripts/
│   ├── provision.sh      # One-time install (Wine, Box64, AstroTuxLauncher)
│   ├── entrypoint.sh     # Start logic (from astroneer-docker)
│   └── install.sh        # Python venv setup (from astroneer-docker)
├── systemd/
│   └── astroneer.service
└── config/
    └── astroneer.env.example
```

## Updating

```bash
cd /opt/astroneer
sudo -u astroneer git pull
sudo systemctl restart astroneer
```

AstroTuxLauncher auto-updates the dedicated server on start when `AutoUpdateServer` is enabled (default).

## License

AGPL-3.0 — consistent with [AstroTuxLauncher](https://github.com/birdhimself/AstroTuxLauncher) and upstream dependencies. See [LICENSE](LICENSE).
