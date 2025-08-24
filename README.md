# [copyparty](https://github.com/9001/copyparty) Server with Cloudflared Tunnel 🚀

This repository provides a `Dockerfile` to run a `copyparty` fileserver. It is designed to be securely exposed to the internet using a Cloudflare Tunnel, which is managed within the container.

View the GitHub Container Registry package for this image: **[ghcr.io/vilos92/copyparty-tunnel](https://github.com/Vilos92/copyparty-tunnel/pkgs/container/copyparty-tunnel)**

---

## Prerequisites

Before you begin, ensure you have the following set up on your host machine:

* **Docker:** You must have [Docker](https://www.docker.com/get-started) installed and running.
* **Cloudflare Tunnel Token:** You need a token from your [Cloudflare Zero Trust dashboard](https://one.dash.cloudflare.com/).
* **`copyparty.conf` file:** A configuration file for `copyparty`. This file tells the server which directories to share and sets permissions.
* **Source Directories:** The local directories you want to serve must exist on your computer.

---

## ⚠️ Critical Configuration Steps

You **must** configure the following correctly for the container to work.

### 1. Set the Cloudflare Token

The container **will not function** without your Cloudflare Tunnel token. It is required to authenticate with Cloudflare's network and create the secure tunnel.

Set it as an environment variable in your terminal before running the container:
```bash
export COPYPARTY_CLOUDFLARED_TOKEN="your-long-token-goes-here"
```

### 2. Map Your Configuration File

The `copyparty.conf` file controls everything about your fileserver. You must map your local configuration file into the container so the application can read it.

This is done with the `-v` flag in the `docker run` command:
```bash
-v "$(pwd)/copyparty.conf:/app/copyparty.conf:ro"
```
This command maps the `copyparty.conf` in your current directory to the expected location inside the container in read-only (`ro`) mode.

### 3. Mount Your Data Volumes

The most important step is to make your local files available inside the container. The paths you mount with the `-v` flag **must match the paths defined inside your `copyparty.conf` file.**

For example, if your `copyparty.conf` specifies a volume named `/data/music`, you must map one of your local folders to that exact path inside the container.

**Example:**
* **If `copyparty.conf` contains:** `-v /data/music:r:user:pass`
* **Then your `docker run` command MUST include a matching volume flag:**
    ```bash
    -v "/path/on/your/computer/to/music:/data/music"
    ```

### 4. Ensure Port Consistency 🔗

For the tunnel to work correctly, the port number must be consistent across three places:

1.  **`copyparty.conf` file:** Your configuration file must specify the port for the `copyparty` server to listen on (e.g., using the argument `-p 3923`).
2.  **`docker run` command:** The port mapping flag (`-p 3923:3923`) must expose the same container port that `copyparty` is listening on.
3.  **Cloudflare Tunnel:** When you configure your tunnel in the Cloudflare dashboard, its service URL must point to the same port on localhost (e.g., `http://localhost:3923`).

Using the same port number for all three (like `3923` in the examples) is highly recommended to avoid confusion.

---

## How to Use

### 1. Pull or Build the Docker Image

You can pull the Docker image from the GitHub Container Registry (GHCR).

```bash
docker pull ghcr.io/vilos92/copyparty-tunnel:latest
```

If you would prefer to build it yourself, navigate to the directory containing the `Dockerfile` and run the following command to build the image.

```bash
docker build -t ghcr.io/vilos92/copyparty-tunnel:latest .
```

### 2. Run the Docker Container

Run the command below to start your `copyparty` container.

**✅ Remember:** Replace the example volume paths (`/path/on/your/computer/...`) with the actual paths on your machine, ensuring they correspond to your `copyparty.conf`.

```bash
docker run -d \
  --name gcopyparty \
  -p 3923:3923 \
  -u $(id -u) \
  # Map your configuration file (required)
  -v "$(pwd)/copyparty.conf:/app/copyparty.conf:ro" \
  \
  # Map your data volumes (examples below, change them!)
  -v "/path/on/your/computer/to/music:/data/music" \
  -v "/path/on/your/computer/to/documents:/data/docs" \
  \
  # Pass in the Cloudflare token (required)
  -e COPYPARTY_CLOUDFLARED_TOKEN="$COPYPARTY_CLOUDFLARED_TOKEN" \
  --restart unless-stopped \
  ghcr.io/vilos92/copyparty-tunnel:latest
```
