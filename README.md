vichan
======

**A lightweight, fast, and highly configurable PHP imageboard.**

vichan is a free and open-source imageboard package. It renders boards as static
HTML for speed, keeps its dependency footprint small, and exposes an enormous amount
of behaviour through configuration — from a single hobby board to a large,
federated, multi-board site. It is a long-running fork of the (now defunct)
[Tinyboard](http://github.com/savetheinternet/Tinyboard), with many additional
features built on top.

**This fork — federated-vichan — is built around three headline capabilities:**
**[federated posting](#federated-posting)** over NNTPChan, so boards are shared across a
network of independent nodes instead of being trapped on one server;
**[real-time posting](#real-time-posting)**, so new threads and replies appear without a
refresh; and a hardened **[security](#security)** stack, with upload malware scanning and
runtime intrusion detection. **Federation is the heart of the project** — see below.

- Written in PHP (8.1 supported), backed by MySQL/MariaDB.
- Static page generation with pluggable caching (APCu, Memcached, or Redis).
- Per-board configuration, a themeable front end, gettext translations, and a
  4chan-compatible JSON API.

---

## Features

### Boards & posting
- Classic threads and replies with multi-file posts, OP-only file rules, and
  configurable per-board limits.
- Thread controls: **sticky**, **lock**, **cyclical threads**, **bump-lock**, and
  sage.
- Tripcodes — regular, **secure**, and admin-defined **custom** tripcodes — plus
  optional capcodes for staff.
- Poster identity extras: per-thread **poster IDs**, **country flags** (GeoIP) and
  custom user flags, and forced-anonymous mode.
- Cross-board references (`>>>/board/123`), backlinks, slugified thread URLs, and a
  catalog view.
- Rich text markup (bold, italics, spoilers, code, headings, quotes), optional
  **wiki markup**, Markdown (Parsedown), and inline **dice rolls**.
- **Video embedding** (YouTube, Vimeo, Dailymotion, Vocaroo, …) and optional
  upload-by-URL.
- Built-in **oekaki** drawing (wPaint) for posting images you draw in the browser.

### Media handling
- Thumbnailing via **GD**, **ImageMagick**, `convert`, or `convert`+`gifsicle`,
  with separate OP/reply thumbnail sizes and animated-GIF thumbnails.
- **WebM/MP4 video** support with dimension and duration extraction.
- Multi-image posts, spoiler images, and a deleted-file placeholder.
- **EXIF stripping** / image redraw / auto-orientation, and optional
  EXIF-based identification.

### Anti-spam & abuse prevention
- **Captcha** with several backends: reCAPTCHA, hCaptcha, a self-hosted distorted-text
  captcha, and a self-hosted **anime image-quiz captcha** whose challenge pool is
  managed from the mod panel.
- **Perceptual image-hash banning** — bans images by a fuzzy hash (pHash/dHash/aHash)
  and Hamming-distance matching, so re-encoded, resized, or one-pixel-edited copies of
  a banned image are still caught. Hashes (from vichan or any compatible tool) can be
  bulk-imported to mass-ban unwanted images.
- A flexible **filter engine**: match on IP, file hash, name/tripcode, filename,
  extension, body, and more, then reject or auto-ban.
- **DNSBL** support (Tor/proxy blocklists), proxy detection, configurable flood
  throttling, unoriginal-content (robot) detection, a simple question/answer check,
  and optional **Tesseract OCR** text-in-image filtering.
- **Upload malware scanning (ClamAV)** and **runtime intrusion detection (Falco)**, with
  Falco alerts surfaced in the mod panel — see the dedicated **[Security](#security)**
  section.

### Moderation
- A full moderation panel with fine-grained, per-board and global **permissions**.
- **Bans** with IP ranges, ban appeals, and a ban list that loads on **infinite
  scroll** (fetched in batches, so it scales to very large ban tables).
- **IP tools**: per-IP view with post history and notes, delete-by-IP (per board or
  global), and reversible **IP cloaking** (IPs are stored/displayed as encrypted
  tokens that only staff can uncloak), including consistent cloaking in the moderation
  log for staff without raw-IP access.
- Post actions: delete, delete file, edit (rendered or raw), move threads between
  boards, sticky/lock/cycle/bump-lock, and public ban messages.
- **Emergency mode**: freeze a board (all boards for admins, only their own for
  moderators) so posts from ordinary users are held in an **approval queue** instead
  of being published; staff then approve or reject them one at a time or in batches.
- **Admin-managed board navigation links** (the top/bottom board bar), editable from
  the panel without touching config files.
- Staff PM system, a moderation log, a noticeboard, news, a static-page editor, a
  web-based **config editor**, a theme manager, board creation/management, and user
  management with promote/demote.
- Search across posts, IP notes, bans, and the log; plus a recent-posts view.

### Federation
- **NNTPChan federation** — federated-vichan is a *federated* imageboard: boards are
  shared across a network of independent nodes over NNTP, exchanging threads, replies, and
  images with every peer that carries the board. A default public hub joins you to the
  network at install time, and the whole layer is best-effort so it **never blocks local
  posting**. **→ [Federated posting](#federated-posting)** covers this in depth.

### Front end & themes
- Pluggable **themes** for site-wide pages: catalog, categories, recent posts, an
  overboard (ukko), RSS, sitemap, a public ban list, frameset, and a basic index.
- A large set of optional JavaScript enhancements, including quick reply, inline
  image expansion, post hovering/preview, **real-time updates** (live threads and index —
  see [Real-time posting](#real-time-posting)), a thread watcher,
  catalog and catalog search, gallery view, thread/post hiding and filtering, ID
  colouring, quote selection, style selection, **user CSS/JS**, an options panel,
  favourites, and desktop-title notifications.

### Architecture & operations
- **Static HTML generation** for fast page serving, with incremental rebuild
  options.
- Pluggable caching: **APCu**, **Memcached**, or **Redis**.
- **Per-board configuration**, an instance override file (`secrets.php`), and a
  4chan-compatible **JSON API**.
- Internationalisation via gettext, a set of CLI maintenance tools, and Docker
  support.

---

## Federated posting

**federated-vichan is a federated imageboard.** Instead of every post living on one server
that can be seized, blocked, throttled, or simply go offline, boards are shared across a
network of independent nodes that exchange content peer-to-peer over
[NNTPChan](https://github.com/majestrate/nntpchan) — an imageboard federation protocol
built on **NNTP**, the same battle-tested transport that has carried Usenet for decades.
You are not hosting an island; you are joining a network.

### How it works

- **Every board maps to a newsgroup.** When someone posts a thread or reply, your node
  publishes it as an NNTP article to that board's group. Any peer subscribed to the group
  receives the article and renders it as a native post — thread, replies, and **images
  included** (attachments are carried inline in the article, not just linked).
- **Posts propagate outward.** A message posted on *your* node reaches every peer that
  carries the group, and their peers in turn — so a single post can fan out across the
  entire network with no central server relaying it.
- **A default hub puts you online immediately.** A fresh install is pre-wired to the public
  **syndichan.org** hub and automatically maps the `syndichan.random` newsgroup to your
  **`/b/`** board, so a brand-new node starts **sending and receiving content the moment it
  comes up** — no manual peering required to join the network.
- **Message-ID deduplication.** Every article carries a globally-unique Message-ID, so the
  same post arriving from two different peers is stored once; loops and duplicates are
  dropped automatically.

### Built to never get in your way

Federation is **best-effort and asynchronous** — it is layered *on top of* local posting,
never in front of it:

- Local posting is **never blocked or slowed** by federation. If a peer or the hub is
  unreachable, your post still succeeds instantly; outbound delivery is retried and inbound
  sync catches up when the peer returns.
- Outbound delivery is tuned for real-world endpoints (the syndichan.org hub accepts
  articles by **POST** rather than streaming), so it works through the kind of restricted
  NNTP hubs you actually meet in practice.

### Managed from the mod panel

An **NNTP manager** in the moderation panel puts the whole federation layer under admin
control — no config-file editing:

- **Peers** — add, remove, and enable/disable the nodes you pull from and push to.
- **Group ↔ board map** — choose which newsgroups feed which local boards (many-to-many);
  `/b/ ↔ syndichan.random` is seeded for you at install so the board self-populates.
- **Settings** — federation identity and delivery options.

### Why it matters

A federated board has **no single point of failure and no single point of control.**
Content is mirrored across every participating node, so:

- if one node is taken down, the conversations live on everywhere else;
- new nodes bootstrap from the network and immediately carry the shared corpus;
- a community can run its own node, keep full control of its own instance, and *still* take
  part in a much larger shared set of boards.

That is what makes federated-vichan fundamentally different from a stock imageboard: it is
a **resilient, distributed network of boards**, not a lone server.

---

## Real-time posting

Boards update **live** — new threads appear on the index and new replies appear in an open
thread **without anyone refreshing the page.** Two layers work together:

- **Instant push (Server-Sent Events).** When a post is committed, the server bumps a
  per-board change counter in **Redis**; a lightweight SSE endpoint streams that signal to
  every connected browser, which then pulls in the new content — typically in well under a
  second. SSE connections run in their **own dedicated PHP-FPM pool**, so a crowd of
  long-lived streams can never starve normal page serving.
- **Polling fallback.** If the stream drops, or the browser is old, the built-in
  auto-reloader (open threads) and live-index (board index) keep updating on a short timer,
  so the live experience **degrades gracefully instead of breaking**.

Because boards are served as cached static HTML, front-end assets are **automatically
cache-busted on every deploy** (versioned by content), so visitors always run the current
scripts and styles rather than a stale cached copy.

---

## Security

Running a public imageboard means accepting untrusted uploads and traffic from anyone.
federated-vichan ships a defense-in-depth stack for exactly that. Full operational details
are in [`docker/security.md`](docker/security.md).

### Upload malware scanning (ClamAV)

Every uploaded file is **streamed to a ClamAV daemon and scanned before the post is
accepted** — a signature match rejects the post outright, so malware never reaches the
board's storage or its visitors. Scanning happens over the network (clamd INSTREAM), so the
scanner never needs access to the web server's filesystem. It **fails open** by default (a
slow or offline scanner never blocks posting) and can be flipped to fail-closed for stricter
environments.

### Runtime threat detection (Falco)

A [Falco](https://falco.org/) service watches host and container **syscalls** (via modern
eBPF — no kernel headers required) for the tell-tale signs of a compromise: an interactive
shell opening inside a container, a package manager running at runtime, reads of credential
files, or connections to miner / reverse-shell ports. The rules are tuned to this stack so
normal activity (thumbnailing, healthchecks) doesn't cry wolf. Alerts are written as JSON
and surfaced **right in the mod panel at `?/falco`** — priority-coloured and newest-first —
so staff can see what the host is doing without needing shell access to it.

### Automated NSFW / explicit-content filtering (open_nsfw)

A dedicated ML service scores every uploaded image with **Yahoo's open_nsfw** deep-learning
model (run via the maintained `opennsfw2` port of the original weights), giving each image a
0–1 probability of being explicit. It is a **more sophisticated automated line of defense than
static filters** for keeping prohibited imagery off the boards:

- Where the perceptual-hash banlist only catches *known* images (ones an operator has already
  seen and banned), open_nsfw **classifies images it has never seen** — so a brand-new explicit
  upload can be caught automatically, before a human ever lays eyes on it.
- Policy is **per board**, configured from the mod panel at **`?/nsfw`**: a site-wide default
  plus per-board overrides, each with its own score **threshold** and **action** — either
  *reject* the post outright, or *spoiler* the image (let it through but hide the thumbnail).
- It runs as an isolated sidecar service that the board simply asks for a score. It fails
  **open** by default (a scorer outage never blocks posting) and can be set to fail closed.

**What it is — and isn't.** open_nsfw is a heuristic classifier for *explicit / pornographic*
imagery: a strong automated first filter, **not** a legal-content oracle. It does not
"detect illegal content" in any authoritative sense — identifying material such as CSAM
requires specialised hash-matching services (e.g. PhotoDNA), and human review remains
essential. Treat it as a **force-multiplier for moderators**: it removes the bulk of obvious
explicit uploads automatically so staff can spend their time on the genuinely hard cases,
layered together with the perceptual-hash banlist, the filter engine, and human moderation.

### Abuse prevention

- **Captcha** — reCAPTCHA, hCaptcha, a self-hosted distorted-text captcha, or a self-hosted
  **image-quiz captcha** whose answer key stays server-side.
- **Perceptual image-hash banning** — fuzzy pHash/dHash/aHash matching catches re-encoded,
  resized, or one-pixel-edited copies of a banned image.
- A flexible **filter engine** (IP, file hash, name, filename, extension, body…), **DNSBL**
  / proxy detection, flood throttling, robot detection, and optional **OCR** text-in-image
  filtering.

### Hardening

- **Encrypted IP cloaking** — IPs are stored and shown to staff as reversible encrypted
  tokens (including in the moderation log), so staff can act without handling raw addresses.
- **EXIF stripping / image redraw** removes metadata — and metadata-borne exploits — from
  uploads.
- Optional **Content-Security-Policy**, secure / HTTPS-only cookies, **secure tripcodes**,
  and **SSRF guards** on server-side fetches (upload-by-URL, captcha image import).
- **Emergency mode** freezes a board into an approval queue so nothing from ordinary users
  is published until staff clear it — a kill-switch for raids.

---

## Getting the software running

There are two ways to run vichan. **Docker Compose is strongly recommended** — the
included images bundle the correct PHP version and every required extension, so you
avoid host PHP/extension mismatches entirely. A manual (bare-metal) path is documented
afterwards for those who need it.

The web service listens on **port 9080** in both cases.

---

### Option A — Docker Compose (recommended)

This repository ships a complete stack: **nginx** + **PHP 8.3-FPM** (with GD, BCMath,
PDO MySQL, Redis and ImageMagick) + **MySQL** + **Redis**, defined in `compose.yml`.
Persistent data (the site, database, and cache) lives under `local-instances/<INSTANCE>/`.

#### 1. Install Docker and the Compose plugin

On Ubuntu/Debian:

```sh
sudo apt update
sudo apt install -y docker.io docker-compose-v2
sudo systemctl enable --now docker

# run docker without sudo (log out/in afterwards, or use `newgrp docker` now)
sudo usermod -aG docker "$USER"
newgrp docker

docker --version
docker compose version
```

#### 2. Get the code

```sh
git clone https://github.com/Jonathan-R-Anderson/federated-vichan.git
cd federated-vichan
```

#### 3. Create your environment file

Copy the example and set your own passwords:

```sh
cp .env.example .env
nano .env          # or your editor of choice
```

At a minimum, change the passwords. **`VICHAN_MYSQL_PASSWORD` and `MYSQL_PASSWORD`
must be identical** (the app and the database must agree):

```ini
VICHAN_MYSQL_PASSWORD=a-long-random-password       # app -> database
MYSQL_PASSWORD=a-long-random-password              # must match the line above
MYSQL_ROOT_PASSWORD=another-long-random-password
VICHAN_CACHE_PASSWORD=yet-another-random-password
```

Generate strong values with `openssl rand -base64 32`. Leave `INSTANCE=0` unless you
run multiple instances on one host. The `UPDATE_*` block is optional (see
[Automatic updates](#automatic-updates)).

#### 4. Create the persistent data directories

```sh
mkdir -p local-instances/0/{www,db,redis}
# the app is unpacked into ./www on first boot; make it writable for setup
chmod -R 777 local-instances/0/www
```

(You can tighten the `www` permissions after installation.)

#### 5. Build and start everything

```sh
docker compose up -d --build
```

The PHP image runs `composer install` at build time, so you do **not** need Composer
on the host. Confirm all four services are up:

```sh
docker compose ps
# vichan_web, vichan_php, vichan_db, vichan_redis  -> all "running"
```

On the very first start the database initialises, which can take a minute; give it a
moment before running the installer.

#### 6. Run the installer

Find the machine's address (`curl -4 ifconfig.me` for a public IP), then open:

```
http://YOUR_SERVER_IP:9080/install.php
```

When it asks for database details, use the **service name**, not `localhost`:

| Field             | Value                                         |
|-------------------|-----------------------------------------------|
| Database server   | `db`                                          |
| Database name     | `vichan` (`VICHAN_MYSQL_NAME`)                |
| Database username | `vichan` (`VICHAN_MYSQL_USER`)               |
| Database password | your `VICHAN_MYSQL_PASSWORD` from `.env`      |

#### 7. Log in and secure the admin account

Open `http://YOUR_SERVER_IP:9080/mod.php` and log in with the default
credentials **`admin` / `password`** — then **change the password immediately**.

#### Opening the firewall

If port 9080 isn't reachable, allow it locally and in your provider's firewall/security
group:

```sh
sudo ufw allow 9080/tcp
curl -I http://127.0.0.1:9080/install.php   # test from the server itself
```

#### Everyday commands

```sh
docker compose logs -f            # all logs
docker compose logs -f php        # PHP-FPM / application
docker compose logs -f web        # nginx
docker compose restart            # restart everything
docker compose down               # stop (data is preserved under local-instances/)
docker compose up -d --build      # rebuild after changing application code
```

#### Troubleshooting

- **`502 Bad Gateway`** — nginx can't reach PHP-FPM. Make sure PHP-FPM listens on all
  interfaces, not just loopback: `docker/php/www.conf` must contain `listen = 9000`
  (**not** `listen = 127.0.0.1:9000`, which refuses cross-container connections). Fix
  it and `docker compose restart php`.
- **`403 Forbidden` on `/`** — normal *before* you finish `install.php`; the document
  root has no index page yet.
- **Permission / bind-mount errors during setup** — ensure `local-instances/0/www` is
  writable (step 4).

---

### Option B — Manual installation (without Docker)

Requirements:

1. PHP **8.1–8.3** (the bundled Docker image uses 8.3; very new host PHP such as 8.5
   may hit compatibility issues in older dependencies — prefer Docker there)
2. MySQL/MariaDB server (>= 5.5.3 recommended)
3. PHP extensions: **gd**, **bcmath**, **mbstring**, **pdo_mysql** (GD powers CAPTCHA
   and thumbnails; BCMath is needed by the IP library)
4. A web server (nginx or Apache) with PHP-FPM
5. [Composer](https://getcomposer.org/)
6. A Unix-like OS (GNU/Linux or FreeBSD preferred)

Install the PHP extensions on Ubuntu/Debian, then verify:

```sh
sudo apt install -y php-gd php-bcmath php-mbstring php-mysql php-curl composer
php -m | grep -E 'gd|bcmath|mbstring|pdo_mysql'   # all four should print
```

Then:

```sh
git clone https://github.com/Jonathan-R-Anderson/federated-vichan.git
cd federated-vichan
composer install
```

Point your web server's document root at the project directory and hand `.php`
requests to PHP-FPM. A minimal nginx example:

```nginx
server {
    listen 80;
    server_name example.org;
    root /path/to/federated-vichan;
    index index.html index.php;

    location / { try_files $uri $uri/ /index.php?$query_string; }
    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass unix:/run/php/php-fpm.sock;   # or 127.0.0.1:9000
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
```

vichan needs no Apache `.htaccess` file. **Recommended:** ImageMagick for better
thumbnails, and APCu/Memcached/Redis for caching. Finally, open `install.php` in your
browser and follow the prompts, then log in at `mod.php` (**admin / password**) and
change the password.

Instance-specific settings belong in `inc/secrets.php` (or per-board `config.php`
files), never in `inc/config.php`, which is overwritten on upgrade. See
[Configuration Basics](https://github.com/vichan-devel/vichan/wiki/config).

---

## Upgrading

**Manually:** `git pull`, then `docker compose up -d --build` (Docker) or re-run
`install.php` (manual). Re-running `install.php` also creates any new database tables
added by newer features. Back up `inc/secrets.php` first if you replace files by hand.

To migrate from Kusaba X, use
[Tinyboard-Migration](http://github.com/vichan-devel/Tinyboard-Migration).

### Automatic updates

`tools/self-update.sh` can keep a deployment current on its own: once a week it pulls
from the git address in your `.env`, restarts, health-checks the site, and **rolls back
to the previous release if the update is unhealthy**. Configure it in `.env`:

```ini
UPDATE_ENABLED=1
UPDATE_GIT_REMOTE=https://github.com/you/your-fork.git
UPDATE_HEALTHCHECK_URL=http://localhost:9080/install.php
# UPDATE_GIT_BRANCH= and UPDATE_RESTART_CMD= are optional (sensible defaults)
```

Then install the weekly cron job:

```sh
tools/self-update.sh --install-cron
```

It is disabled by default (`UPDATE_ENABLED=0`) and only acts when the remote actually
has new commits.

## JSON API

vichan provides a 4chan-compatible JSON API by default. See
<https://github.com/vichan-devel/vichan-API/> for documentation.

## CLI tools

Command-line utilities live in `tools/` (run from a shell account). They are aimed at
power users and are not required for normal operation — for example: site rebuilds
(`rebuild2.php`), maintenance (`maintenance.php`), stray-image cleanup
(`delete-stray-images.php`), password hashing (`hash-passwords.php`), translation
extraction/compilation, and benchmarking.

## Oekaki

vichan uses [wPaint](https://github.com/websanova/wPaint) for oekaki. After cloning,
pull it in via git submodules:

```
git submodule init
git submodule update
```

Then enable it by adding the scripts listed in `js/wpaint.js` to your instance
config.

## WebM support

See `inc/lib/webm/README.md` for information on enabling WebM.

## Documentation

Further documentation is on the
[wiki](https://github.com/vichan-devel/vichan/wiki) — contributions welcome.

## Contributing

You can help by submitting pull requests (features, fixes, translations), reporting
bugs, and improving documentation.

---

## History

vichan is a fork of the (now defunct)
[Tinyboard](http://github.com/savetheinternet/Tinyboard), building on it with many
additional features and improvements.

### Maintainer timeline
1. [@perdedora](https://github.com/perdedora) and [@RealAngeleno](https://github.com/RealAngeleno) - 2023-Present.
2. Development Commission lead by [@basedgentoo](https://github.com/basedgentoo), [@kuz-sysadmin](https://github.com/kuz-sysadmin), and [@RealAngeleno](https://github.com/RealAngeleno). (2023 - 2023)
3. [@h00j](https://github.com/h00j) (2021 - ???)
4. [@ctrlcctrlv](https://github.com/ctrlcctrlv) (2017 - 2021)
5. [@czaks](https://github.com/czaks) (2014 - 2017) (The author of vichan fork)
6. [@savetheinternet](https://github.com/savetheinternet) (2010 - 2014) (The creator of Tinyboard)

## License

See [LICENSE.md](https://github.com/vichan-devel/vichan/blob/master/LICENSE.md) (and
[LICENSE.Tinyboard.md](https://github.com/vichan-devel/vichan/blob/master/LICENSE.Tinyboard.md)).
