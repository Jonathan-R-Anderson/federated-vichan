# open_nsfw scoring microservice (Yahoo open_nsfw via opennsfw2 / TensorFlow-CPU).
FROM python:3.11-slim

# Runtime libs TensorFlow / Pillow need.
RUN apt-get update && apt-get install -y --no-install-recommends \
        libgl1 libglib2.0-0 curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Bake the model weights into the image so the first request doesn't have to download them
# (opennsfw2 fetches them the first time make_open_nsfw_model() runs).
RUN python -c "import opennsfw2 as n2; n2.make_open_nsfw_model()"

COPY app.py /app/app.py

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=5 \
    CMD curl -fsS http://127.0.0.1:8080/healthz || exit 1

# One sync worker. IMPORTANT: do NOT use --preload (and do not load the model in the master):
# TensorFlow does not survive gunicorn's fork, so a preloaded model deadlocks on the first
# inference in the worker. Without --preload the worker imports app.py — and loads the model —
# in its own post-fork process, which works. The model is large, so keep it to one worker.
CMD ["gunicorn", "-w", "1", "-b", "0.0.0.0:8080", "--timeout", "120", "app:app"]
