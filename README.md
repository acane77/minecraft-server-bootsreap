# Minecraft 26.3 servers

Two independent Minecraft Java servers:

| Directory | Loader | Default build | Game port | systemd service |
| --- | --- | --- | --- | --- |
| `forge/` | Forge | 26.3-66.1.0 (recommended) | TCP 25565 | `minecraft-forge` |
| `neoforge/` | NeoForge | 26.3.0.101 | TCP 25566 | `minecraft-neoforge` |

`make VERSION=26.2` downloads the 26.2 build instead: Forge **65.1.5**, NeoForge **26.2.0.93**. Run `make clean` before switching versions. `start_server.sh` always starts the 26.3 files.

Both servers need Linux Java 25 or newer. `eula.txt` is already set to `eula=true`, which accepts the [Minecraft EULA](https://aka.ms/MinecraftEULA).

## Install Java 25

Ubuntu 20.04 has no Java 25 package in the official archive. Install Eclipse Temurin 25:

```bash
sudo apt-get update
sudo apt-get install -y wget ca-certificates gnupg
sudo mkdir -p /etc/apt/keyrings
wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor | sudo tee /etc/apt/keyrings/adoptium.gpg >/dev/null
echo "deb [signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb focal main" | sudo tee /etc/apt/sources.list.d/adoptium.list
sudo apt-get update
sudo apt-get install -y temurin-25-jdk
java -version
```

If `java -version` still prints 11, run `sudo update-alternatives --config java` and select 25. The scripts also look in `/usr/lib/jvm/temurin-25-jdk-*`.

On Ubuntu 22.04 and newer, the distro package is enough when it exists (Ubuntu 26.04 has it):

```bash
sudo apt-get update
sudo apt-get install -y openjdk-25-jdk
```

A Windows `java.exe` on `PATH` is ignored. To force a binary, set `JAVA` to its absolute path.

## Prepare and start

Run these inside `forge/` or `neoforge/`:

```bash
make                  # Minecraft 26.3
make VERSION=26.2     # Minecraft 26.2
make clean            # delete downloaded libraries and installer files
./start_server.sh
```

`make` checks the installer SHA1, then runs the official installer. If `https_proxy` or `http_proxy` is set, both `make` and `start_server.sh` pass that proxy to Java. Worlds, logs, `server.properties`, `eula.txt`, and `user_jvm_args.txt` are kept by `make clean`.

Heap size is `-Xms1G -Xmx4G` in `user_jvm_args.txt`. Lower `-Xmx` when the machine has less than about 6 GB of RAM. Put mods in `mods/`.

`./start_server.sh` exits with an error until `make` has prepared the 26.3 server.

## systemd

```bash
./service_manager.sh install
./service_manager.sh uninstall
```

`install` enables the service for the user who owns that directory and keeps the current proxy variables. It does not start the process.

```bash
sudo systemctl start minecraft-forge
sudo systemctl stop minecraft-forge
journalctl -u minecraft-forge -f
```

Use `minecraft-neoforge` for the NeoForge server. Ubuntu 20.04 already runs systemd. On WSL, set `systemd=true` under `[boot]` in `/etc/wsl.conf`, then run `wsl --shutdown` from Windows.
