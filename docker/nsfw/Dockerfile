# open_nsfw scoring microservice (Yahoo open_nsfw via opennsfw2 / TensorFlow-CPU).
FROM python:3.11-slim

# Runtime libs TensorFlow / Pillow need.
RUN apt-get update && apt-get install -y --no-install-recommends \
        libgl1 libglib2.0-0 curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# NOTE: we do NOT run the model at build time. TensorFlow's wheels require AVX CPU
# instructions, so executing it during `docker build` crashes ("Illegal instruction") on hosts
# without AVX — e.g. QEMU/KVM VMs that don't pass the host CPU through — which would fail the
# whole build. opennsfw2 downloads the (small) weights on first use at runtime instead.
#
# The service still REQUIRES AVX *to run*: on a CPU without it the container exits with SIGILL
# at model load and will restart-loop. Run this service on a host with AVX (bare metal or a VM
# with host-CPU passthrough); if your host has no AVX, leave VICHAN_NSFW_ENABLED=0 and stop the
# nsfw container. See docker/security.md.

COPY app.py /app/app.py

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=5 \
    CMD curl -fsS http://127.0.0.1:8080/healthz || exit 1

# One sync worker. IMPORTANT: do NOT use --preload (and do not load the model in the master):
# TensorFlow does not survive gunicorn's fork, so a preloaded model deadlocks on the first
# inference in the worker. Without --preload the worker imports app.py — and loads the model —
# in its own post-fork process, which works. The model is large, so keep it to one worker.
CMD ["gunicorn", "-w", "1", "-b", "0.0.0.0:8080", "--timeout", "120", "app:app"]
