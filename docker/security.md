# Upload scanning (ClamAV) and runtime threat detection (Falco)

Two optional security services are wired into `compose.yml`:

- **ClamAV** — scans every uploaded file for malware and rejects infected ones.
- **Falco** — watches host/container syscalls for suspicious behavior and surfaces the alerts
  in the mod panel at **`?/falco`**.

Both come up with the normal deploy (`docker compose up --build`). Notes and tuning below.

---

## ClamAV — upload malware scanning

**How it works.** The `clamav` container runs the `clamd` daemon listening on `3310` (compose
network only — no host port). When a post has files, `post.php` streams each one to `clamd` via
the INSTREAM command (`inc/clamav.php`) *before* the post is accepted. A signature match rejects
the post; the uploader sees "Upload rejected: malware detected (…)". Streaming means `clamd`
never needs access to the web server's files — only the socket.

**Enable/disable** (env, see `.env.example`):

| Variable | Default | Meaning |
|---|---|---|
| `VICHAN_CLAMAV_ENABLED` | `1` | Master switch for scanning. |
| `VICHAN_CLAMAV_HOST` | `clamav` | clamd host (compose service name). |
| `VICHAN_CLAMAV_PORT` | `3310` | clamd TCP port. |
| `VICHAN_CLAMAV_FAIL_CLOSED` | `0` | `0` = allow the upload if clamd is unreachable (fail open); `1` = reject it (fail closed). |

**RAM.** `clamd` holds its signature database in memory — roughly **1–2 GB**. If the host can't
spare that, set `VICHAN_CLAMAV_ENABLED=0` (uploads then skip scanning and the container can be
removed). Scanning fails *open* by default, so a slow or missing scanner never blocks the board.

**First start** downloads the signature DB (`freshclam`, a few hundred MB) — the healthcheck's
`start_period` allows ~2 minutes. The DB is persisted in `local-instances/<INSTANCE>/clamav/`, so
restarts are fast.

**File-size limit.** `docker/clamav/clamd.conf` sets `StreamMaxLength 100M`. This must be **≥ your
largest allowed upload** (`$config['max_filesize']`) or `clamd` returns "size limit exceeded" and
the scan errors (treated per `FAIL_CLOSED`). Raise it in step with the board's limit.

**Test it.** Upload an [EICAR test file](https://www.eicar.org/download-anti-malware-testfile/)
(a harmless standard AV probe). It should be rejected as `Eicar-Test-Signature`.

**If `clamav` won't start** with the custom config, remove the `clamd.conf` line from the service
in `compose.yml` — the stock image still exposes TCP `3310` (with a 25 MB stream limit).

---

## Falco — runtime threat detection

**How it works.** The `falco` container watches syscalls using the **modern eBPF** probe (CO-RE —
no kernel headers or compiled driver needed; requires **Linux ≥ 5.8**). It flags suspicious
behavior across the host and all containers and writes JSON alerts to
`local-instances/<INSTANCE>/falco/events.log`, which the php container reads read-only for the
admin viewer.

**Privileges.** Falco needs deep host access — `privileged`, `pid: host`, and read-only mounts of
`/proc`, `/etc`, and the Docker socket. This is inherent to host-level monitoring; it is the one
service here with broad access, so treat the host accordingly.

**Rules.** The official image's default ruleset (fetched by `falcoctl` on first start — needs
outbound internet) provides ~100 detections. On top, `docker/falco/rules.d/vichan_rules.yaml`
adds stack-specific rules written to avoid this app's false positives (the php container
legitimately shells out to ImageMagick/ffmpeg for thumbnails; healthchecks run `sh`):

- **Interactive shell in a vichan container** — a shell *with a tty* (the thumbnail `exec()`s
  have none), i.e. hands-on access.
- **Package manager in a vichan container** — `apk`/`apt`/`pip`/… at runtime = post-exploitation.
- **Sensitive credential file read** — `/etc/shadow`, `~/.ssh/id_rsa`, etc.
- **Outbound connection to miner/reverse-shell ports.**

Tune or add rules in that file, then `docker compose restart falco`.

**Viewing alerts.** Mod panel → **Security alerts (Falco)** (`?/falco`), visible to admins
(`$config['mod']['view_falco']`, default `ADMIN`). It shows the most recent 300 alerts newest-first,
colored by priority, with per-priority counts. Also available via `docker logs vichan_falco`.

**Notes.**
- If the kernel is < 5.8 or eBPF is unavailable, Falco won't start and the panel simply shows
  "No Falco alert log is readable yet" — nothing else breaks.
- `events.log` is append-only and not rotated by Falco; add host `logrotate` if it grows large.
  The panel only reads the tail, so it stays fast regardless.

---

## NSFW image filtering (open_nsfw)

The `nsfw` service scores every uploaded image with **Yahoo's open_nsfw** model (via the
`opennsfw2` TensorFlow port, same weights). `post.php` sends each image to it and applies the
board's policy before the post is accepted.

**Configure it** in the mod panel at **`?/nsfw`** (admin): a site-wide default plus per-board
overrides, each with a score **threshold** (0–1) and an **action** — **reject** (block the
post, default) or **spoiler** (allow it but force the thumbnail to a spoiler). Policy lives in
the `nsfw_settings` table (the empty-`board` row is the site-wide default). Env defaults:

| Variable | Default | Meaning |
|---|---|---|
| `VICHAN_NSFW_ENABLED` | `1` | Master switch (feature + upload hook). |
| `VICHAN_NSFW_DEFAULT_ENABLED` | `1` | Apply to all boards until a policy row exists. |
| `VICHAN_NSFW_THRESHOLD` | `0.8` | Score at/above which an image counts as NSFW. |
| `VICHAN_NSFW_ACTION` | `reject` | `reject` or `spoiler`. |
| `VICHAN_NSFW_FAIL_CLOSED` | `0` | `0` = allow uploads if the scorer is down; `1` = reject. |

**Requirements.** The service runs TensorFlow-CPU, which **requires a CPU with AVX** and
~0.5–1 GB RAM (the image is large). On a host without AVX — e.g. a QEMU/KVM VM that doesn't pass
the host CPU through — the container exits with `Illegal instruction` (SIGILL) at model load and
restart-loops. Run it on a host with AVX (bare metal, or a VM with host-CPU passthrough); if the
host has no AVX, leave `VICHAN_NSFW_ENABLED=0` and stop the `nsfw` container. The model weights
download on first use. It fails **open** by default, so even a missing/crash-looping scorer
never blocks posting.

**Scope.** open_nsfw classifies *explicit* imagery — a strong automated first filter, not a
detector of illegal content (that needs specialised hash-matching such as PhotoDNA). Pair it
with the perceptual-hash banlist and human moderation.

## Deploy

Normal flow: `git pull` && `docker compose up --build`. New persistent dirs
(`local-instances/<INSTANCE>/clamav`, `.../falco`) are created automatically. No schema changes.
Give ClamAV a couple of minutes on first boot to pull signatures.
